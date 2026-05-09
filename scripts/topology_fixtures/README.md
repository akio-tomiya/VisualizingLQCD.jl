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

Run from the repository root:

```sh
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/diagnose_su2_instanton_fixtures.jl

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-su2-instanton-fixtures
```
