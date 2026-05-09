#!/usr/bin/env julia

using Dates
using Gaugefields
using LinearAlgebra
using Printf
using SHA
using Statistics
using Wilsonloop

const HEATBATH_DIM = 4
const HEATBATH_ITERATION_MAX = 100_000
const PLAQUETTE_PLANES_4D = ((1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4))
const ACTION_DENSITY_QUANTILES = [0.0, 0.5, 0.8, 0.84, 0.9, 0.99, 1.0]

function arg_value(args, name, default)
    flag = "--$name"
    index = findfirst(==(flag), args)
    index === nothing && return default
    index < length(args) || error("missing value after $flag")
    return args[index + 1]
end

arg_bool(args, name) = "--$name" in args

function parse_loaders(text)
    loaders = Symbol[]
    for item in split(text, ",")
        loader = Symbol(strip(item))
        loader in (:binary, :ildg) || error("unsupported loader: $loader")
        push!(loaders, loader)
    end
    isempty(loaders) && error("--loaders must include at least one loader")
    return loaders
end

function selected_slices(nt)
    return unique([1, max(1, nt ÷ 4), max(1, nt ÷ 2), max(1, 3nt ÷ 4), nt])
end

plaquette_loop(mu::Integer, nu::Integer) = [(mu, +1), (nu, +1), (mu, -1), (nu, -1)]

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

function print_environment()
    println("timestamp=", Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"))
    println("julia_version=", VERSION)
    println("julia_bindir=", Sys.BINDIR)
    println("active_project=", Base.active_project())
    println("gaugefields_path=", pathof(Gaugefields))
    println("wilsonloop_path=", pathof(Wilsonloop))
    flush(stdout)
end

function print_observables(U, temp1, temp2, label)
    factor = 1 / (length(PLAQUETTE_PLANES_4D) * U[1].NV * U[1].NC)
    plaq = calculate_Plaquette(U, temp1, temp2) * factor
    poly = calculate_Polyakov_loop(U, temp1, temp2)
    @printf("%s plaquette %.16g\n", label, plaq)
    @printf("%s polyakov %.16g %.16g\n", label, real(poly), imag(poly))
    flush(stdout)
    return plaq
end

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

function density_stats(values)
    flat = vec(values)
    return (
        quantiles=quantile(flat, ACTION_DENSITY_QUANTILES),
        frac_eq1=count(x -> x == 1.0, flat) / length(flat),
        frac_ge099=count(x -> x >= 0.99, flat) / length(flat),
    )
end

function print_stats(label, values)
    stats = density_stats(values)
    println(label)
    println("  quantiles=", stats.quantiles)
    println("  frac_eq1=", stats.frac_eq1, " frac_ge099=", stats.frac_ge099)
    flush(stdout)
    return stats
end

function assert_stats_ok(label, stats; frac_limit, q90_limit)
    stats.frac_eq1 < frac_limit ||
        error("$label has exact-1 contamination: $(stats.frac_eq1)")
    stats.frac_ge099 < frac_limit ||
        error("$label has >=0.99 contamination: $(stats.frac_ge099)")
    stats.quantiles[5] < q90_limit ||
        error("$label q90 is suspiciously high: $(stats.quantiles[5])")
    return nothing
end

function check_sample_link_norms(U, nt)
    for t in selected_slices(nt)
        norms = [norm(U[mu][:, :, 1, 1, 1, t]) for mu in 1:HEATBATH_DIM]
        println("link_norms slice=$t norms=$norms")
        minimum(norms) > 0.1 ||
            error("suspicious near-zero link matrix at slice $t: $norms")
    end
    flush(stdout)
    return nothing
end

function sanity_check_configuration(U, nx, ny, nz, nt, nc; label,
    frac_limit=1e-6, q90_limit=0.5)

    println("sanity_check=$label")
    check_sample_link_norms(U, nt)
    density = local_action_density(U, nx, ny, nz, nt, nc)
    global_stats = print_stats("density_global", density)
    assert_stats_ok("density_global", global_stats; frac_limit, q90_limit)

    for t in selected_slices(nt)
        slice_stats = print_stats("density_slice=$t", @view density[:, :, :, t])
        assert_stats_ok("density_slice=$t", slice_stats; frac_limit, q90_limit)
    end
    println("sanity_check=$label ok")
    flush(stdout)
    return nothing
end

function load_configuration(path, loader, nx, ny, nz, nt, nc)
    U = Initialize_Gaugefields(nc, 0, nx, ny, nz, nt; condition="cold")
    if loader == :binary
        load_binarydata!(U, path)
    elseif loader == :ildg
        ildg = ILDG(path)
        load_gaugefield!(U, 1, ildg, [nx, ny, nz, nt], nc)
    else
        error("unsupported loader: $loader")
    end
    return U
end

function generate_configuration(; nx, ny, nz, nt, nc, beta, heatbath_sweeps,
    flow_steps, condition)

    U = Initialize_Gaugefields(nc, 0, nx, ny, nz, nt; condition=condition)
    temp1 = similar(U[1])
    temp2 = similar(U[1])
    temp3 = similar(U[1])
    temp4 = similar(U[1])
    temp5 = similar(U[1])

    print_observables(U, temp1, temp2, "initial")
    for sweep in 1:heatbath_sweeps
        @time heatbath_SU3!(U, nc, [temp1, temp2, temp3, temp4, temp5], beta)
        print_observables(U, temp1, temp2, "heatbath_$sweep")
    end

    if flow_steps > 0
        g = Gradientflow(U)
        for step in 1:flow_steps
            flow!(U, g)
            println("flow $step/$flow_steps")
        end
    end
    flush(stdout)
    return U
end

function file_sha256(path)
    return bytes2hex(sha256(read(path)))
end

function main(args=ARGS)
    nx = parse(Int, arg_value(args, "nx", "4"))
    ny = parse(Int, arg_value(args, "ny", "4"))
    nz = parse(Int, arg_value(args, "nz", "4"))
    nt = parse(Int, arg_value(args, "nt", "8"))
    nc = parse(Int, arg_value(args, "nc", "3"))
    beta = parse(Float64, arg_value(args, "beta", "6.0"))
    heatbath_sweeps = parse(Int, arg_value(args, "heatbath-sweeps", "1"))
    flow_steps = parse(Int, arg_value(args, "flow-steps", "1"))
    condition = arg_value(args, "condition", "cold")
    output = arg_value(args, "output",
        joinpath("outputs", "roundtrip", "RoundTrip$(nx)$(ny)$(nz)$(nt)beta$(beta).ildg"))
    loaders = parse_loaders(arg_value(args, "loaders", "binary,ildg"))
    overwrite = arg_bool(args, "overwrite")

    print_environment()
    println("roundtrip_output=$output")
    println("loaders=$loaders")
    println("lattice=$nx,$ny,$nz,$nt nc=$nc beta=$beta")
    flush(stdout)

    if isfile(output) && !overwrite
        error("output already exists: $output; pass --overwrite to replace it")
    end

    U = generate_configuration(;
        nx, ny, nz, nt, nc, beta, heatbath_sweeps, flow_steps, condition)
    sanity_check_configuration(U, nx, ny, nz, nt, nc; label="before_save")

    mkpath(dirname(output))
    @time save_binarydata(U, output)
    println("saved_file=$output")
    println("saved_bytes=", filesize(output))
    println("saved_sha256=", file_sha256(output))
    flush(stdout)

    for loader in loaders
        U_reload = load_configuration(output, loader, nx, ny, nz, nt, nc)
        sanity_check_configuration(U_reload, nx, ny, nz, nt, nc;
            label="after_reload_$loader")
    end

    println("roundtrip_io_smoke ok")
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
