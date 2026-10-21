# Render with the LatticeField API and with create_animation under the same
# settings, so the outputs can be compared frame by frame.
#
# Usage (lab machine with a display, not the MacBook):
#   julia --project=. -t 8 benchmark/check_render_api.jl CONF.ildg OUTDIR
#
# Writes OUTDIR/{api,legacy}_{blob,signed_contour}.mp4 and several snapshots.
# Compare with: ffmpeg -i A.mp4 -f framemd5 - (identical hashes = identical frames).

using VisualizingLQCD
using LinearAlgebra
using Printf

const V = VisualizingLQCD
const L = (24, 24, 24, 32)
const BETA = 6.0

function timed(label, f)
    t = @elapsed result = f()
    @printf("%-40s %8.2f s\n", label, t)
    return result
end

function main(args)
    length(args) == 2 || error("usage: check_render_api.jl CONF.ildg OUTDIR")
    conf, outdir = args
    mkpath(outdir)
    common = (figure_size=(480, 480), show_render_progress=false)

    U = timed("load_gauge", () -> load_gauge(conf; lattice=L))
    action = timed("measure ActionDensity", () -> measure(ActionDensity(), U))
    q = timed("measure TopologicalChargeDensity", () -> measure(TopologicalChargeDensity(), U))

    timed("movie api blob", () -> movie(joinpath(outdir, "api_blob.mp4"), action;
        beta=BETA, common...))
    timed("movie api signed_contour", () -> movie(joinpath(outdir, "api_signed_contour.mp4"), q;
        style=SignedContour(), beta=BETA, common...))
    timed("create_animation blob", () -> create_animation(L..., 3,
        joinpath(outdir, "legacy_blob.mp4"); beta=BETA, filename=conf, common...))
    timed("create_animation signed_contour", () -> create_animation(L..., 3,
        joinpath(outdir, "legacy_signed_contour.mp4"); beta=BETA, filename=conf,
        level_target=V.LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY, common...))

    plaquette = measure(PlaquetteDensity(1, 2), U)
    for (name, field, style) in (
        ("blob", action, Blob()),
        ("signed_volume", q, SignedVolume()),
        ("signed_contour", q, SignedContour()),
        ("log_isosurface", plaquette, LogIsosurface()),
        ("raw_thermal", plaquette, RawIsosurface(thermal=true)),
    )
        timed("snapshot $name", () -> snapshot(joinpath(outdir, "snapshot_$name.png"), field;
            slice=6, style=style, beta=BETA, figure_size=(480, 480)))
    end

    # A user-defined operator, drawn in lattice units (no beta).
    clover_energy = FieldStrengthDensity(name="clover_field_strength_squared", signed=false) do F
        -sum(real(tr(F[m, n] * F[m, n])) for m in 1:4, n in 1:4)
    end
    energy = timed("measure FieldStrengthDensity", () -> measure(clover_energy, U))
    timed("snapshot user field", () -> snapshot(joinpath(outdir, "snapshot_user_field.png"),
        energy; slice=6, figure_size=(480, 480)))
    timed("movie user field orbit", () -> movie(joinpath(outdir, "api_user_field_orbit.mp4"),
        energy; frames=FixedSlice(6), camera=Orbit(turns=1.0, seconds=4.0), common...))
end

main(ARGS)
