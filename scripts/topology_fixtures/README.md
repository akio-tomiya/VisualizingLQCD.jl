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
Use `--show-axis-labels false` for README-style orbit movies; it keeps the grid
and 3D box but avoids axis-label shimmer during rotation.

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

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_movie.jl --nx 24 --ny 24 --nz 24 --nt 32 --nc 3 --beta 6.0 --input /Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg --render-mode volume --camera-motion orbit --frame-mode sequence --nloops 2 --framerate 8 --figure-size 480 --show-render-progress true --output-dir /private/tmp/VisualizingLQCD-topological-config-movie-review
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
