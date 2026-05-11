# Topological Density Sample Commands

Last updated: 2026-05-11

This memo records the reproducible command path for the reviewed
topological-charge-density README sample. It is intentionally separate from
`visualization_refactor_status.md` so it can be edited while PR #42 touches the
main status memo.

## Current Progress

- User-facing visualization pipeline: about `85%`.
- README/sample media path: about `90%`.
- Topological charge-density physics-validation depth: about `70%`.

The main remaining physics validation item is a true gauge-field instanton or
SU(3)-embedded instanton check from the Gaugefields.jl-side work. The current
VisualizingLQCD.jl path is already useful for real-configuration visual review,
but it is not yet the final research-grade instanton calibration suite.

## Reviewed README Sample

- Input:
  `/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg`
- Durable accepted artifact location:
  `studio1:/Users/akio/VisualizingLQCD-review-artifacts/topological-readme-halfspeed-20260511`
- Local review page used for acceptance:
  `file:///private/tmp/VisualizingLQCD-topological-readme-halfspeed-remote-20260511/view.html`
- Accepted visual-review item:
  `no-axis / gif 300 half-speed`

## Reproduction Command

Run from the repository root:

```sh
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_movie.jl --nx 24 --ny 24 --nz 24 --nt 32 --nc 3 --beta 6.0 --input /Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg --output-name topological_density_noaxis_halfspeed.mp4 --render-mode volume --camera-motion orbit --frame-mode sequence --camera-orbit-turns 1 --nloops 4 --framerate 8 --figure-size 480 --show-axis-labels false --show-render-progress true --output-dir /private/tmp/VisualizingLQCD-topological-readme-sample
```

Expected metadata:

- `level_target=topological_charge_density`
- `render_style=topological_charge_volume`
- `frame_mode=slice4_sequence`
- `nloops=4`
- `framerate=8`
- `frame_count=128`
- `duration_seconds=16.0`
- `camera_orbit_turns=1`
- `show_axis_labels=false`

## Operating Notes

- Do not rely on `/private/tmp` as the only artifact location. Copy the MP4,
  metadata sidecar, GIF, review HTML, and command/log notes to durable storage
  before asking for visual review.
- Record the machine name. GLMakie rendering is still display/backend
  dependent; `studio1` is the last known-good render machine for this sample.
- Use still-review pages before long movie renders when tuning thresholds,
  colors, or mesh smoothing.
- Keep README media small. The accepted committed GIF is the `300 x 300`
  derivative, not the larger 480 px review GIF.

## Validation

Current branch: `codex/topological-sample-docs`.

```text
/Users/akio/.juliaup/bin/julia --project=. -e 'include("scripts/topology_fixtures/render_topological_density_config_movie.jl"); @assert parse_bool("false", "--show-axis-labels") == false; @assert parse_bool("true", "--show-axis-labels") == true; println("movie helper syntax and parse smoke passed")'
result: pass

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass, 218 tests, render smoke skipped

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass, 218 tests, render smoke skipped

git diff --check
result: pass
```

## Next Steps

1. Finish PR #42, which locks the tracked README sample metadata contract.
2. Keep this command path as the canonical topological-density README sample
   reproduction route.
3. Next code-health work should separate renderer/I/O orchestration around
   `create_animation` without changing rendered output.
4. Resume true instanton validation once the Gaugefields.jl-side implementation
   is ready.
