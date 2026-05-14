# Topology Fixtures

These helper scripts are lightweight diagnostics for the topological charge
density renderer.

`diagnose_su2_instanton_fixtures.jl` samples continuum SU(2) instanton
topological charge densities on a periodic lattice. It is a scalar-density
fixture, not a lattice gauge-field instanton solution. Use it to debug signed
rendering, level selection, centers, radii, signs, boundary wrapping, and
DIGA-like multi-lump superpositions before full Gaugefields.jl instanton gauge
fields are available.

`render_su2_instanton_fixture_smoke.jl` renders a few of those scalar fixtures
with the signed topological-density contour style and writes a local HTML review
page. It is intended as a visual smoke test, not a default unit test.

`render_topological_density_config_review.jl` loads an ILDG gauge configuration,
computes the clover topological charge density, and writes still PNGs plus a
review HTML page for selected fourth-direction slices. Use this before rendering
a full movie from a large configuration: it checks whether the contour/volume
styles expose meaningful topological-density structure without spending frames
on a full GLMakie `record` loop.

`render_topological_density_config_movie.jl` uses the same configuration-level
topological-density path, but writes one or more movies plus a review HTML page.
It is a thin wrapper around `VisualizingLQCD.create_animation`, intended for
small reviewed movie runs after the still-review page looks reasonable.

`render_flowtime_q_density_movie.jl` is a private flow-time review helper for
GaugefieldsInstantonRadius `q_density/q_improved_tau_*.jld2` outputs. It fixes
one Euclidean fourth-direction slice and advances movie frames by gradient-flow
time `t/a^2`, so it should not be interpreted as a fourth-direction slice scan
or as real-time evolution. The input metadata calls this dimensionless value
`tau`; the movie label and sidecar report it as `t/a^2`. The metadata sidecar
records the selected `t/a^2` values, the fixed `slice4`, the global display
thresholds, and `Q_tot(t)`.

The flow-time helper keeps the default raw-density display unless explicitly
switched with `--display-normalization per-frame-peak`. In that mode each frame
is rendered as `q_lat/q_max(t)` with a fixed normalized isosurface level, while
`--normalization-floor-fraction` prevents a nearly disappeared lump from being
renormalized into visible noise. This is a display diagnostic only; the sidecar
metadata still records the raw `Q_tot(t)` and raw `max|q|`.

For collapsing Wilson-flow lumps, prefer
`--level-strategy positive-charge-fraction`: on the displayed three-dimensional
slice it chooses the highest-density positive region carrying a fixed fraction
of the positive slice charge. With the default `--charge-fraction-fade true`,
the mesh opacity is the raw positive slice charge divided by its initial value,
so a disappearing lump fades instead of being re-amplified by a tiny peak.
Use `--charge-fraction-fade false --visibility-gate topological-sector` when the
goal is an opaque shape diagnostic: frames are rendered only while `Q_tot` is
closer to the requested topological sector than to a neighboring integer sector.
Use `--duration-seconds` to render a fixed wall-clock movie duration at the
requested framerate. The helper linearly interpolates stored `q_density` frames
in flow time and records that interpolation in the metadata sidecar.

Use `--show-axis-labels false` for README-style orbit movies; it keeps the grid
and 3D box but avoids axis-label shimmer during rotation.
Use `--render-theme light` to render the same scene on a white background, or
`--render-theme both` in the still-review script to compare dark and light
themes in one review page.

For volume rendering, the current reviewed baseline uses a `q0.940` lower
`|q|` body threshold and colors each sign by local `abs(q)`: positive charge is
yellow/orange/red and negative charge is cyan/blue. This is the package default
for `RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME`; pass `--level-quantiles` or
`--color-quantile` only when deliberately testing a new visual threshold.

The default smoke set is intentionally small. Use `--case-set debug` to add
radius, off-center, spatial-boundary, same-sign DIGA, and three-lump checks.
The display can also be tuned from the command line with `--style-preset`,
`--level-quantiles`, `--color-quantile`, and `--alpha`. Presets are `balanced`
(package default), `wide` (default for this smoke script), and `core`. Use
`--style-preset all` to render all three presets into one review page.
Use `--render-mode volume` to render signed positive/negative solid meshes,
or `--render-mode both` to compare contour and volume outputs in one page.

The generated HTML includes visual-check controls next to each still/movie.
Checking boxes updates a copyable review textarea at the bottom of the page, so
manual review notes can be pasted back into an issue, PR, or Codex thread
without retyping each case name.

Run from the repository root:

```sh
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/diagnose_su2_instanton_fixtures.jl

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-su2-instanton-fixtures

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --case-set debug --style-preset wide --output-dir /private/tmp/VisualizingLQCD-su2-instanton-fixtures-debug

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --case-set debug --style-preset all --no-movie --output-dir /private/tmp/VisualizingLQCD-su2-instanton-fixtures-review

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --case-set debug --style-preset all --render-mode volume --no-movie --output-dir /private/tmp/VisualizingLQCD-su2-instanton-fixtures-volume-review

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_review.jl --nx 24 --ny 24 --nz 24 --nt 32 --nc 3 --beta 6.0 --input /Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg --render-mode both --slice4 auto --auto-slices 4 --output-dir /private/tmp/VisualizingLQCD-topological-config-review

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_review.jl --nx 24 --ny 24 --nz 24 --nt 32 --nc 3 --beta 6.0 --input /Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg --render-mode volume --render-theme both --slice4 auto --auto-slices 4 --output-dir /private/tmp/VisualizingLQCD-topological-light-theme-review

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_movie.jl --nx 24 --ny 24 --nz 24 --nt 32 --nc 3 --beta 6.0 --input /Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg --render-mode volume --camera-motion orbit --frame-mode sequence --nloops 2 --framerate 8 --figure-size 480 --show-render-progress true --output-dir /private/tmp/VisualizingLQCD-topological-config-movie-review

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_flowtime_q_density_movie.jl --t-over-a2-list 0,1,2,4.5,8,12,18,24,30,40,50 --fixed-slice4 7 --output-dir /private/tmp/VisualizingLQCD-flowtime-q-density-wilson-core --output-name su2_wilson_t0_50_slice7_core.mp4 --figure-size 440 --framerate 4 --level-quantiles 0.99,0.9995 --color-quantile 0.9995 --show-render-progress false

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_flowtime_q_density_movie.jl --t-over-a2-list 0,1,2,4.5,8,12,18,24,30,40,50 --fixed-slice4 7 --display-normalization per-frame-peak --normalized-body-level 0.25 --normalization-floor-fraction 1.0e-3 --output-dir /private/tmp/VisualizingLQCD-flowtime-q-density-wilson-qoverqmax --output-name su2_wilson_t0_50_slice7_qoverqmax.mp4 --figure-size 440 --framerate 4 --show-render-progress false

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_flowtime_q_density_movie.jl --t-over-a2-list 0,1,2,4.5,8,12,18,24,30,40,50 --fixed-slice4 7 --level-strategy positive-charge-fraction --charge-fraction 0.50 --charge-fraction-fade true --output-dir /private/tmp/VisualizingLQCD-flowtime-q-density-wilson-charge-hdr --output-name su2_wilson_t0_50_slice7_charge_hdr50.mp4 --figure-size 440 --framerate 4 --show-render-progress false

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_flowtime_q_density_movie.jl --t-over-a2-list 0,1,2,4.5,8,12,18,24,30,40,50 --fixed-slice4 7 --level-strategy positive-charge-fraction --charge-fraction 0.50 --charge-fraction-fade false --visibility-gate topological-sector --target-topological-charge 1 --output-dir /private/tmp/VisualizingLQCD-flowtime-q-density-wilson-charge-hdr-sector --output-name su2_wilson_t0_50_slice7_charge_hdr50_sector.mp4 --figure-size 440 --framerate 4 --show-render-progress false

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_flowtime_q_density_movie.jl --fixed-slice4 7 --level-strategy positive-charge-fraction --charge-fraction 0.50 --charge-fraction-fade false --visibility-gate topological-sector --target-topological-charge 1 --duration-seconds 25 --output-dir /private/tmp/VisualizingLQCD-flowtime-q-density-wilson-charge-hdr-sector-25s --output-name su2_wilson_t0_50_slice7_charge_hdr50_sector_25s_24fps.mp4 --figure-size 440 --framerate 24 --show-render-progress false
```

The accepted README sample can be reproduced from the same input configuration
with the following reviewed settings:

```sh
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_movie.jl --nx 24 --ny 24 --nz 24 --nt 32 --nc 3 --beta 6.0 --input /Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg --output-name topological_density_noaxis_halfspeed.mp4 --render-mode volume --camera-motion orbit --frame-mode sequence --camera-orbit-turns 1 --nloops 4 --framerate 8 --figure-size 480 --show-axis-labels false --show-render-progress true --output-dir /private/tmp/VisualizingLQCD-topological-readme-sample
```

This produces `128` frames at `8` fps: all `32` Euclidean fourth-direction
slices are shown four times while the camera completes one full turn. Keep the
source MP4 and metadata sidecar in durable storage before making a user-review
page or committing derived README media.
