# Generate an unsmoothed configuration, build gradient-flow series, and render
# flow-time movies.
#
# Usage (lab machine with a display, not the MacBook):
#   julia --project=. -t 8 benchmark/check_flow_movie.jl OUTDIR

using VisualizingLQCD
using Printf

function timed(label, f)
    t = @elapsed result = f()
    @printf("%-40s %8.2f s\n", label, t)
    return result
end

function main(args)
    length(args) == 1 || error("usage: check_flow_movie.jl OUTDIR")
    outdir = args[1]
    mkpath(outdir)
    L = (16, 16, 16, 16)
    beta = 6.0

    U = timed("generate_gauge (no flow)", () ->
        generate_gauge(L; beta=beta, sweeps=20, flow_steps=0, verbose=false))
    q_series = timed("flow_series q, 11 times", () ->
        flow_series(U, TopologicalChargeDensity(); steps=0:10:100))
    s_series = timed("flow_series action, 11 times", () ->
        flow_series(U, ActionDensity(); steps=0:10:100))
    for (i, t) in enumerate(q_series.flow_times)
        @printf("t/a^2 = %.2f  Q = %+.4f  mean action density = %.5f\n",
            t, sum(q_series[i]), sum(s_series[i]) / prod(L))
    end

    common = (beta=beta, figure_size=(480, 480), show_render_progress=false)
    timed("movie q per_frame", () -> movie(joinpath(outdir, "flow_q_per_frame.mp4"), q_series;
        frames=FlowSweep(slice=8, hold=3), common...))
    timed("movie q first", () -> movie(joinpath(outdir, "flow_q_first.mp4"), q_series;
        frames=FlowSweep(slice=8, hold=3, levels=:first), common...))
    timed("movie action per_frame", () -> movie(joinpath(outdir, "flow_action_per_frame.mp4"),
        s_series; frames=FlowSweep(slice=8, hold=3), common...))
end

main(ARGS)
