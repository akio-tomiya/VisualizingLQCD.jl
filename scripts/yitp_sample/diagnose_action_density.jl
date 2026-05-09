#!/usr/bin/env julia

using Dates
using Gaugefields
using LinearAlgebra
using Printf
using SHA
using Statistics
using Wilsonloop

const PLAQUETTE_PLANES_4D = ((1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4))
const WILSONLINE_TEMP_COUNT = 10
const ACTION_DENSITY_SMOOTH_WEIGHT = 0.92
const ACTION_DENSITY_SMOOTH_PASSES = 1
const ACTION_DENSITY_QUANTILES = [0.0, 0.5, 0.8, 0.84, 0.9, 0.99, 1.0]

function arg_value(args, name, default)
    flag = "--$name"
    index = findfirst(==(flag), args)
    index === nothing && return default
    index < length(args) || error("missing value after $flag")
    return args[index + 1]
end

arg_bool(args, name) = "--$name" in args

function file_sha256(path)
    return bytes2hex(sha256(read(path)))
end

function selected_slices(nt)
    return unique([1, max(1, nt ÷ 4), max(1, nt ÷ 2), max(1, 3nt ÷ 4), nt])
end

plaquette_loop(mu::Integer, nu::Integer) = [(mu, +1), (nu, +1), (mu, -1), (nu, -1)]

function plaquette_plane_deviation(U, nx, ny, nz, nt, nc;
    plane=(1, 2),
    loop=plaquette_loop(plane[1], plane[2]),
    temp_count=WILSONLINE_TEMP_COUNT)

    w = Wilsonline(loop)
    Uloop = similar(U[1])
    temps = [similar(U[1]) for _ in 1:temp_count]
    evaluate_gaugelinks!(Uloop, w, U, temps)

    raw = zeros(Float64, nx, ny, nz, nt)
    for z in 1:nz, y in 1:ny, x in 1:nx, t in 1:nt
        raw[x, y, z, t] = 1 - real(tr(Uloop[:, :, x, y, z, t])) / nc
    end
    return raw
end

function local_action_density(U, nx, ny, nz, nt, nc;
    planes=PLAQUETTE_PLANES_4D,
    temp_count=WILSONLINE_TEMP_COUNT)

    density = zeros(Float64, nx, ny, nz, nt)
    for plane in planes
        raw = plaquette_plane_deviation(U, nx, ny, nz, nt, nc;
            plane=plane, temp_count=temp_count)
        density .+= raw
        raw = nothing
        GC.gc()
    end
    density ./= length(planes)
    return density
end

periodic_index(i, n) = mod1(i, n)

function smooth_periodic_3d(data; weight=ACTION_DENSITY_SMOOTH_WEIGHT,
    passes=ACTION_DENSITY_SMOOTH_PASSES)

    out = Float64.(data)
    for _ in 1:passes
        src = out
        dest = similar(src)
        nx, ny, nz = size(src)
        for z in 1:nz, y in 1:ny, x in 1:nx
            neighbor_sum =
                src[periodic_index(x - 1, nx), y, z] +
                src[periodic_index(x + 1, nx), y, z] +
                src[x, periodic_index(y - 1, ny), z] +
                src[x, periodic_index(y + 1, ny), z] +
                src[x, y, periodic_index(z - 1, nz)] +
                src[x, y, periodic_index(z + 1, nz)]
            dest[x, y, z] = weight * src[x, y, z] + (1 - weight) * neighbor_sum / 6
        end
        out = dest
    end
    return out
end

function map_fourth_slices(data4, f)
    out = similar(data4, Float64)
    for t in axes(data4, 4)
        out[:, :, :, t] .= f(@view data4[:, :, :, t])
    end
    return out
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

function print_stats(label, values)
    flat = vec(values)
    qs = quantile(flat, ACTION_DENSITY_QUANTILES)
    frac_eq1 = count(x -> x == 1.0, flat) / length(flat)
    frac_ge099 = count(x -> x >= 0.99, flat) / length(flat)
    println(label)
    println("  quantiles=", qs)
    println("  frac_eq1=", frac_eq1, " frac_ge099=", frac_ge099)
    flush(stdout)
    return (; quantiles=qs, frac_eq1, frac_ge099)
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

function print_link_norms(U, nt)
    for slice4 in selected_slices(nt)
        norms = [norm(U[mu][:, :, 1, 1, 1, slice4]) for mu in 1:4]
        println("link_norms slice=$slice4 norms=$norms")
    end
    flush(stdout)
end

function main(args=ARGS)
    nx = parse(Int, arg_value(args, "nx", "32"))
    ny = parse(Int, arg_value(args, "ny", "32"))
    nz = parse(Int, arg_value(args, "nz", "32"))
    nt = parse(Int, arg_value(args, "nt", "64"))
    nc = parse(Int, arg_value(args, "nc", "3"))
    input = arg_value(args, "input", "outputs/Conf$(nx)$(ny)$(nz)$(nt)beta6.0.ildg")
    loader = Symbol(arg_value(args, "loader", "ildg"))
    fail_on_contamination = arg_bool(args, "fail-on-contamination")
    skip_plane_stats = arg_bool(args, "skip-plane-stats")
    frac_limit = parse(Float64, arg_value(args, "frac-limit", "1e-6"))
    q90_limit = parse(Float64, arg_value(args, "q90-limit", "0.5"))
    temp_count = parse(Int, arg_value(args, "temp-count", string(WILSONLINE_TEMP_COUNT)))

    print_environment()
    println("input=$input")
    println("input_bytes=", filesize(input))
    println("input_sha256=", file_sha256(input))
    println("loader=", loader)
    println("lattice=$nx,$ny,$nz,$nt nc=$nc")
    println("temp_count=", temp_count)
    println("fail_on_contamination=", fail_on_contamination)
    println("skip_plane_stats=", skip_plane_stats)
    flush(stdout)

    U = Initialize_Gaugefields(nc, 0, nx, ny, nz, nt; condition="cold")
    if loader == :ildg
        ildg = ILDG(input)
        load_gaugefield!(U, 1, ildg, [nx, ny, nz, nt], nc)
    elseif loader == :binary
        load_binarydata!(U, input)
    else
        error("unsupported --loader $loader; use ildg or binary")
    end

    print_link_norms(U, nt)

    if !skip_plane_stats
        for plane in PLAQUETTE_PLANES_4D
            raw = plaquette_plane_deviation(U, nx, ny, nz, nt, nc;
                plane=plane, temp_count=temp_count)
            print_stats("plane=$plane", raw)
            raw = nothing
            GC.gc()
        end
    end

    density = local_action_density(U, nx, ny, nz, nt, nc; temp_count=temp_count)
    density_stats = print_stats("density", density)
    fail_on_contamination &&
        assert_stats_ok("density", density_stats; frac_limit, q90_limit)

    smoothed = map_fourth_slices(density, x -> smooth_periodic_3d(x;
        weight=ACTION_DENSITY_SMOOTH_WEIGHT,
        passes=ACTION_DENSITY_SMOOTH_PASSES))
    print_stats("smoothed_density", smoothed)

    for slice4 in selected_slices(nt)
        slice_stats = print_stats("density_slice=$slice4", @view density[:, :, :, slice4])
        fail_on_contamination &&
            assert_stats_ok("density_slice=$slice4", slice_stats; frac_limit, q90_limit)
        print_stats("smoothed_slice=$slice4", @view smoothed[:, :, :, slice4])
    end

    println("diagnose_action_density ok")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
