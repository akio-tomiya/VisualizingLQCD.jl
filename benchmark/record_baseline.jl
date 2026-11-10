# Record reference values and timings of the pre-refactor implementation.
#
# Usage (run on a lab machine, not on the MacBook):
#   julia --project=. benchmark/record_baseline.jl CONF.ildg OUTDIR [--render]
#
# The configuration is assumed to be 24^3 x 32, Nc = 3, beta = 6.0.
# OUTDIR receives baseline.json (summary numbers and timings) and
# baseline_fields.jld2 (full observable arrays for later comparison).

using VisualizingLQCD
using JLD2
using Printf
using Statistics

const V = VisualizingLQCD

const NX, NY, NZ, NT, NC = 24, 24, 24, 32, 3
const BETA = 6.0
const MESH_SLICES = (1, 6, 17, 28)

function timed(f; repeat=2)
    result = f()  # first call includes compilation
    times = Float64[]
    for _ in 1:repeat
        t = @elapsed (result = f())
        push!(times, t)
    end
    return result, minimum(times)
end

field_summary(x) = Dict(
    "sum" => sum(x),
    "abs_sum" => sum(abs, x),
    "min" => minimum(x),
    "max" => maximum(x),
    "mean" => mean(x),
    "std" => std(x),
    "quantiles" => quantile(vec(x), [0.5, 0.9, 0.99, 0.999]),
)

function mesh_summary(geometry)
    geometry === nothing && return nothing
    if hasproperty(geometry, :positive)
        return Dict(
            "positive" => mesh_summary(geometry.positive),
            "negative" => mesh_summary(geometry.negative),
        )
    end
    points = V.Makie.GeometryBasics.coordinates(geometry.mesh)
    return Dict(
        "filled" => geometry.info.filled,
        "vertices" => geometry.info.vertices,
        "faces" => geometry.info.faces,
        "coordinate_sum" => Float64(sum(sum(p) for p in points)),
        "color_sum" => Float64(sum(c.r + c.g + c.b for c in geometry.colors)),
    )
end

function main(args)
    length(args) >= 2 || error("usage: record_baseline.jl CONF.ildg OUTDIR [--render]")
    conf, outdir = args[1], args[2]
    do_render = "--render" in args
    mkpath(outdir)

    timings = Dict{String,Float64}()
    a = V.calculate_a(BETA)
    lattice3 = (NX, NY, NZ)

    U, timings["load"] = timed(() -> V.load_animation_gaugefield(conf, NX, NY, NZ, NT, NC); repeat=1)
    plaq, timings["plaquette_plane_deviation"] =
        timed(() -> V.plaquette_plane_deviation(U, NX, NY, NZ, NT, NC))
    action, timings["local_action_density"] =
        timed(() -> V.local_action_density(U, NX, NY, NZ, NT, NC))
    qdens, timings["topological_charge_density"] =
        timed(() -> V.topological_charge_density(U, NX, NY, NZ, NT, NC))

    setups = Dict{String,Any}()
    setups["legacy_neglog"], timings["setup_legacy_neglog"] = timed(() ->
        V.plaquette_display_level_setup(plaq; level_target=V.LEVEL_TARGET_LEGACY_NEGLOG_HIGH))
    setups["raw_high"], timings["setup_raw_high"] = timed(() ->
        V.plaquette_display_level_setup(plaq; level_target=V.LEVEL_TARGET_RAW_HIGH))
    setups["plaquette_thermal"], timings["setup_plaquette_thermal"] = timed(() ->
        V.plaquette_display_level_setup(plaq; level_target=V.LEVEL_TARGET_RAW_HIGH,
            render_style=V.RENDER_STYLE_PLAQUETTE_THERMAL))
    setups["action_density_blob"], timings["setup_action_density_blob"] =
        timed(() -> V.action_density_blob_display_setup(action))
    setups["topological_signed"], timings["setup_topological_signed"] = timed(() ->
        V.topological_charge_display_level_setup(qdens))
    setups["topological_volume"], timings["setup_topological_volume"] = timed(() ->
        V.topological_charge_display_level_setup(qdens;
            render_style=V.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME))

    setup_info = Dict{String,Any}()
    for (name, setup) in setups
        setup_info[name] = Dict(
            "levels" => collect(setup.levels),
            "level_summary" => Dict(pairs(setup.level_summary)),
            "render_style_info" => setup.render_style_info,
        )
    end

    meshes = Dict{String,Any}()
    for name in ("action_density_blob", "topological_volume")
        setup = setups[name]
        per_slice = Dict{String,Any}()
        for slice4 in MESH_SLICES
            data = setup.display_field[:, :, :, slice4]
            geometry, t = timed(() ->
                V.mesh_geometry_for_slice(data, setup; a=a, lattice_size=lattice3); repeat=1)
            timings["mesh_$(name)_slice$(slice4)"] = t
            per_slice[string(slice4)] = mesh_summary(geometry)
        end
        meshes[name] = per_slice
    end

    if do_render
        for (name, kwargs) in (
            ("render_action_density_blob", (;)),
            ("render_topological_signed",
                (; level_target=V.LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY)),
        )
            video = joinpath(outdir, "$(name).mp4")
            _, t = timed(() -> create_animation(NX, NY, NZ, NT, NC, video;
                beta=BETA, filename=conf, figure_size=(480, 480),
                show_render_progress=false, kwargs...); repeat=1)
            timings[name] = t
        end
    end

    summary = Dict(
        "lattice" => [NX, NY, NZ, NT],
        "nc" => NC,
        "beta" => BETA,
        "a_fm" => a,
        "configuration" => conf,
        "threads" => Threads.nthreads(),
        "julia_version" => string(VERSION),
        "hostname" => gethostname(),
        "fields" => Dict(
            "plaquette_plane_deviation" => field_summary(plaq),
            "local_action_density" => field_summary(action),
            "topological_charge_density" => field_summary(qdens),
        ),
        "topological_charge" => sum(qdens),
        "setups" => setup_info,
        "meshes" => meshes,
        "timings_seconds" => timings,
    )
    V.write_animation_metadata(joinpath(outdir, "baseline.json"), summary)
    jldsave(joinpath(outdir, "baseline_fields.jld2");
        plaquette_plane_deviation=plaq,
        local_action_density=action,
        topological_charge_density=qdens)

    for key in sort(collect(keys(timings)))
        @printf("%-45s %9.3f s\n", key, timings[key])
    end
    @printf("Q = %.6f\n", sum(qdens))
end

main(ARGS)
