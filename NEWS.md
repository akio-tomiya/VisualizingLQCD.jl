# News

## v0.1.0

This release reorganizes the package into layers (configuration input →
operator → `LatticeField` → rendering) and moves to the current JuliaQCD
stack. Movies of the same settings as in v0.0.1 are reproduced. On the reference
24³×32 configuration the topological charge density agrees with v0.0.1 to a
relative 1e-15 (summation order differs).

### Breaking changes

- Julia 1.11 or later; Gaugefields 1.1, QCDMeasurements 1.0.1, Makie 0.24, and
  GLMakie 0.13.
- Configurations are allocated with the Gaugefields v1 API
  (`gauge_configuration`, LatticeMatrices backend by default) instead of
  `Initialize_Gaugefields`.
- `heatbathtest_4D` now uses the Gaugefields v1 heatbath and random-number
  streams, so the generated configurations differ from v0.0.1.
- The 3D contour styles render differently under Makie 0.24: surfaces at all
  requested levels are now drawn.
- `ActionDensity` is now `QCDMeasurements.action_density`,
  E(x) = 2 Σ_{μ<ν} Re tr(1 − U_{μν}(x)), which is `2 Nc × 6` times the
  per-plane average used by `create_animation` in v0.0.1. Pictures do not
  change because the thresholds are quantiles.
- The standalone flow-time movie script was removed; use `FieldSeries`,
  `load_field_series`, and `FlowSweep` instead.

### New

- `load_gauge`, `save_gauge`, `generate_gauge` for ILDG, JLD2, and Bridge++.
- `LatticeField` and `measure(op, U)` (extends `QCDMeasurements.measure`).
- Built-in operators `TopologicalChargeDensity` (plaquette, clover,
  Alexandrou, Bilson-Thompson definitions) and `ActionDensity` (plaquette,
  clover) from the per-site density API of QCDMeasurements 1.0.1, and
  `PlaquetteDensity`.
- User-defined operators `LoopDensity`, `FieldStrengthDensity`, `SiteOperator`.
- `snapshot` and `movie` with styles (`Blob`, `SignedVolume`, `SignedContour`,
  `LogIsosurface`, `RawIsosurface`), cameras (`StaticCamera`, `Orbit`), and
  frame sequences (`SliceSweep`, `FixedSlice`, `FlowSweep`).
- Gradient-flow series: `flow_series`, `load_field_series`, `resample`.
- Axes in lattice units when no lattice spacing is given.

### Performance

On a 24³×32 configuration (Apple M4, 8 threads), compared with v0.0.1:
loading 3.3×, topological charge density 4.1×, action-density movie 6.9× faster.

### Deprecated

- `create_animation` is kept as a wrapper around `load_gauge`, `measure`, and
  `movie` and will be removed in a later release.
