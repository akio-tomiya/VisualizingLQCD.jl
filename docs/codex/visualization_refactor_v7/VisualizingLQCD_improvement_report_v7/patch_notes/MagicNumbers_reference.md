# Magic number reference memo

This note records the fixed values observed in the current `VisualizingLQCD.jl` main branch as of 2026-05-04. The values are not all recommended defaults. They are reference anchors for compatibility, regression tests, metadata, and old-vs-new comparisons.

## Visualization path

| Value | Current role | Proposed treatment |
|---:|---|---|
| `1e-7` | epsilon in `-log(tmp + epsilon)` | Keep as `TransformSpec(:neglog, 1e-7, :fixed, ...)` legacy default. |
| `1.2` | `mean + 1.2 * std` starting level | Keep only in `LevelSpec(:mean_std)` compatibility mode. |
| `0.05` | display-level step size | Keep only in compatibility mode and store raw-equivalent levels. |
| `12` | movie framerate | Move to `RenderSpec.framerate`. |
| `1` | number of loops via `t_end = NT * 1` | Move to `FrameSpec.nloops`. |
| `(800, 800)` | Makie figure size | Move to `RenderSpec.figure_size`. |
| `:viridis` | contour colormap | Move to `RenderStyle.colormap`. |
| `alpha=1.0`, `transparency=false` | opaque surfaces | Move to `RenderStyle`. |
| `10 / 3` | legacy yoctosecond conversion | Do not show on screen in the new default UI. |

## Scale and generation path

| Value | Current role | Proposed treatment |
|---:|---|---|
| `r_0 = 0.48 fm` | beta-to-lattice-spacing scale | Move to `ScaleSpec`. |
| `[5.7, 6.57]` | beta fit validity range | Move to `ScaleSpec` and metadata. |
| `(-1.6805, -1.7139, 0.8155, -0.6667)` | polynomial coefficients for `ln(a/r0)` | Move to `ScaleSpec` with source. |
| `20` | heatbath sweeps | Move to `GenerationSpec.num_heatbath`. |
| `5` | progress report interval | Move to `GenerationSpec.report_interval`. |
| `100_000` | SU(3) update iteration maximum | Move to `HeatbathSpec.iteration_max`. |
| `0.01` | implied gradient-flow step size | Move to `FlowSpec.step_size`. |

## Examples and tests

| Value | Current role | Proposed treatment |
|---:|---|---|
| `(24,24,24,32), beta=6.0, Nc=3, flow=200` | README demo | Name as `ExampleSpec(:readme)`. |
| `(12,12,12,16), beta=6.0, Nc=3, flow=10` | current test size | Name as `ExampleSpec(:ci_small)` or integration-test spec. |
