#!/usr/bin/env julia

using Dates
using Gaugefields
using LinearAlgebra
using Printf
using Statistics
using Wilsonloop

const HEATBATH_DIM = 4
const HEATBATH_ITERATION_MAX = 100_000
const HEATBATH_REPORT_INTERVAL = 5
const PLAQUETTE_PLANE_COUNT_4D = 6
const PLAQUETTE_PLANES_4D = ((1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4))
const ACTION_DENSITY_QUANTILES = [0, 0.5, 0.8, 0.84, 0.9, 0.99, 1.0]

function arg_value(args, name, default)
    flag = "--$name"
    index = findfirst(==(flag), args)
    index === nothing && return default
    index < length(args) || error("missing value after $flag")
    return args[index + 1]
end

function arg_bool(args, name)
    return "--$name" in args
end

function memory_estimate_gib(nx, ny, nz, nt, nc)
    sites = nx * ny * nz * nt
    one_direction = sites * nc * nc * sizeof(ComplexF64)
    # The generator keeps 4 gauge directions and 5 same-sized temporary fields.
    return (4 + 5) * one_direction / 1024^3
end

function progress_interval(total, steps=20)
    return max(1, cld(total, steps))
end

function selected_slices(nt)
    return unique([1, max(1, nt ÷ 4), max(1, nt ÷ 2), max(1, 3nt ÷ 4), nt])
end

function heatbath_SU3!(U, nc, temps, beta)
    v = temps[5]
    temps2 = [zeros(ComplexF64, 2, 2) for _ in 1:5]
    temps3 = [zeros(ComplexF64, nc, nc) for _ in 1:5]
    mapfunc!(A, B) = SU3update_matrix!(
        A, B, beta, nc, temps2, temps3, HEATBATH_ITERATION_MAX)

    for mu in 1:HEATBATH_DIM
        loops = loops_staple[(HEATBATH_DIM, mu)]

        iseven = true
        evaluate_gaugelinks_evenodd!(v, loops, U, temps[1:4], iseven)
        map_U!(U[mu], mapfunc!, v, iseven)

        iseven = false
        evaluate_gaugelinks_evenodd!(v, loops, U, temps[1:4], iseven)
        map_U!(U[mu], mapfunc!, v, iseven)
    end
    return nothing
end

function print_observables(U, temp1, temp2, label)
    factor = 1 / (PLAQUETTE_PLANE_COUNT_4D * U[1].NV * U[1].NC)
    plaq = calculate_Plaquette(U, temp1, temp2) * factor
    poly = calculate_Polyakov_loop(U, temp1, temp2)
    @printf("%s plaquette %.16g\n", label, plaq)
    @printf("%s polyakov %.16g %.16g\n", label, real(poly), imag(poly))
    flush(stdout)
    return plaq
end

plaquette_loop(mu::Integer, nu::Integer) = [(mu, +1), (nu, +1), (mu, -1), (nu, -1)]

function plaquette_plane_deviation(U, nx, ny, nz, nt, nc; plane=(1, 2), temp_count=10)
    w = Wilsonline(plaquette_loop(plane[1], plane[2]))
    Uloop = similar(U[1])
    temps = [similar(U[1]) for _ in 1:temp_count]
    evaluate_gaugelinks!(Uloop, w, U, temps)

    raw = zeros(Float64, nx, ny, nz, nt)
    for t in 1:nt, z in 1:nz, y in 1:ny, x in 1:nx
        raw[x, y, z, t] = 1 - real(tr(Uloop[:, :, x, y, z, t])) / nc
    end
    return raw
end

function local_action_density(U, nx, ny, nz, nt, nc)
    density = zeros(Float64, nx, ny, nz, nt)
    for plane in PLAQUETTE_PLANES_4D
        density .+= plaquette_plane_deviation(U, nx, ny, nz, nt, nc; plane=plane)
    end
    density ./= length(PLAQUETTE_PLANES_4D)
    return density
end

function print_density_stats(io, label, values)
    flat = vec(values)
    qs = quantile(flat, ACTION_DENSITY_QUANTILES)
    frac_eq1 = count(x -> x == 1.0, flat) / length(flat)
    frac_ge099 = count(x -> x >= 0.99, flat) / length(flat)
    println(io, label)
    println(io, "  quantiles=", qs)
    println(io, "  frac_eq1=", frac_eq1, " frac_ge099=", frac_ge099)
    flush(io)
    return (quantiles=qs, frac_eq1=frac_eq1, frac_ge099=frac_ge099)
end

function check_sample_link_norms(io, U, nt)
    for t in selected_slices(nt)
        norms = [norm(U[mu][:, :, 1, 1, 1, t]) for mu in 1:HEATBATH_DIM]
        println(io, "link_norms slice=$t norms=$norms")
        minimum(norms) > 0.1 || error("suspicious near-zero link matrix at slice $t: $norms")
    end
    flush(io)
    return nothing
end

function sanity_check_configuration(U, nx, ny, nz, nt, nc; label, log_path=nothing)
    io = log_path === nothing ? stdout : open(log_path, "a")
    try
        println(io, "sanity_check=$label")
        check_sample_link_norms(io, U, nt)
        density = local_action_density(U, nx, ny, nz, nt, nc)
        global_stats = print_density_stats(io, "density_global", density)
        global_stats.frac_eq1 < 1e-6 ||
            error("global action density has exact-1 contamination: $(global_stats.frac_eq1)")
        global_stats.quantiles[5] < 0.5 ||
            error("global action density q90 is suspiciously high: $(global_stats.quantiles[5])")

        for t in selected_slices(nt)
            stats = print_density_stats(io, "density_slice=$t", @view density[:, :, :, t])
            stats.frac_eq1 < 1e-6 ||
                error("slice $t has exact-1 contamination: $(stats.frac_eq1)")
        end
        println(io, "sanity_check=$label ok")
        flush(io)
    finally
        log_path === nothing || close(io)
    end
    return nothing
end

function write_metadata(path; nx, ny, nz, nt, nc, beta, heatbath_sweeps,
    flow_steps, condition, output)

    open(path, "w") do io
        timestamp = Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS")
        plane_text = join(["$a-$b" for (a, b) in PLAQUETTE_PLANES_4D], ",")
        println(io, "generated_at=$timestamp")
        println(io, "lattice=$nx,$ny,$nz,$nt")
        println(io, "nc=$nc")
        println(io, "beta=$beta")
        println(io, "heatbath_sweeps=$heatbath_sweeps")
        println(io, "flow_steps=$flow_steps")
        println(io, "initial_condition=$condition")
        println(io, "plaquette_planes=$plane_text")
        println(io, "output=$output")
    end
    return path
end

function generate_configuration(; nx, ny, nz, nt, nc, beta, flow_steps,
    heatbath_sweeps, output, condition, overwrite, sanity_check)

    if isfile(output) && !overwrite
        error("output already exists: $output; pass --overwrite to replace it")
    end

    @info "starting configuration generation" nx ny nz nt nc beta flow_steps heatbath_sweeps output
    @info "estimated main gauge-field memory GiB" memory_estimate_gib(nx, ny, nz, nt, nc)
    flush(stdout)

    nwing = 0
    U = Initialize_Gaugefields(nc, nwing, nx, ny, nz, nt; condition=condition)
    temp1 = similar(U[1])
    temp2 = similar(U[1])
    temp3 = similar(U[1])
    temp4 = similar(U[1])
    temp5 = similar(U[1])

    print_observables(U, temp1, temp2, "initial")

    for sweep in 1:heatbath_sweeps
        @time heatbath_SU3!(U, nc, [temp1, temp2, temp3, temp4, temp5], beta)
        if sweep % HEATBATH_REPORT_INTERVAL == 0 || sweep == heatbath_sweeps
            print_observables(U, temp1, temp2, "heatbath_$sweep")
        end
    end

    g = Gradientflow(U)
    interval = progress_interval(flow_steps)
    for step in 1:flow_steps
        flow!(U, g)
        if step % interval == 0 || step == flow_steps
            @printf("flow %d/%d %.1f%%\n", step, flow_steps, 100 * step / flow_steps)
            flush(stdout)
        end
    end

    sanity_log = string(output, ".sanity.txt")
    if sanity_check
        sanity_check_configuration(U, nx, ny, nz, nt, nc;
            label="before_save", log_path=sanity_log)
    end

    mkpath(dirname(output))
    @time save_binarydata(U, output)
    if sanity_check
        U_reload = Initialize_Gaugefields(nc, nwing, nx, ny, nz, nt; condition=condition)
        load_binarydata!(U_reload, output)
        sanity_check_configuration(U_reload, nx, ny, nz, nt, nc;
            label="after_reload", log_path=sanity_log)
    end
    write_metadata(string(output, ".metadata.txt");
        nx=nx, ny=ny, nz=nz, nt=nt, nc=nc, beta=beta,
        heatbath_sweeps=heatbath_sweeps, flow_steps=flow_steps,
        condition=condition, output=output)
    @info "finished configuration generation" output metadata=string(output, ".metadata.txt")
    return output
end

function main(args=ARGS)
    nx = parse(Int, arg_value(args, "nx", "32"))
    ny = parse(Int, arg_value(args, "ny", "32"))
    nz = parse(Int, arg_value(args, "nz", "32"))
    nt = parse(Int, arg_value(args, "nt", "64"))
    nc = parse(Int, arg_value(args, "nc", "3"))
    beta = parse(Float64, arg_value(args, "beta", "6.0"))
    flow_steps = parse(Int, arg_value(args, "flow-steps", "200"))
    heatbath_sweeps = parse(Int, arg_value(args, "heatbath-sweeps", "40"))
    output_dir = arg_value(args, "output-dir", "outputs")
    condition = arg_value(args, "condition", "cold")
    output = arg_value(
        args, "output", joinpath(output_dir, "Conf$(nx)$(ny)$(nz)$(nt)beta$(beta).ildg"))
    overwrite = arg_bool(args, "overwrite")
    sanity_check = !arg_bool(args, "no-sanity-check")

    generate_configuration(;
        nx=nx, ny=ny, nz=nz, nt=nt, nc=nc, beta=beta,
        flow_steps=flow_steps, heatbath_sweeps=heatbath_sweeps,
        output=output, condition=condition, overwrite=overwrite,
        sanity_check=sanity_check)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
