# Contributing

## Layout

| File | Layer |
| --- | --- |
| `src/input.jl` | reading and generating gauge configurations (the only place that calls Gaugefields' construction and I/O API) |
| `src/observables.jl`, `src/operators.jl` | operators that turn a configuration into a `LatticeField` |
| `src/field.jl` | `LatticeField` |
| `src/transforms.jl`, `src/levels.jl` | display transforms and threshold selection |
| `src/rendering.jl`, `src/visualization.jl`, `src/render_api.jl` | meshes, contours, scenes, `snapshot`, `movie` |
| `src/flow.jl` | gradient-flow series and flow-time movies |
| `src/metadata.jl` | JSON sidecars |

The rendering side only sees `LatticeField`. Keep it that way, so that other
sources of lattice fields (Dirac eigenmodes, flux measurements) can reuse it.

## Conventions

- The fourth direction is Euclidean. Movies show slices or flow time, never
  real-time evolution, and the sidecar records the frame-to-slice map.
- Keep the `-log(p + 1e-7)` transform of `LogIsosurface`; it is needed for
  stable threshold selection.
- Prefer small, reviewable changes, each with tests.

## Checking that a change keeps the pictures

`benchmark/record_baseline.jl` records operator values, thresholds, mesh
summaries, and timings on a fixed configuration;
`benchmark/compare_baseline.py` and `benchmark/compare_fields.jl` compare two
runs. `benchmark/check_render_api.jl` renders the same movie through `movie`
and `create_animation`; compare frames with `ffmpeg -i movie.mp4 -f framemd5 -`.
The reference summary in `benchmark/reference/` was taken on an Apple M4
(mym4mini) with the 24³×32, β = 6.0 sample configuration.

Rendering and the benchmarks are heavy; run them on a workstation rather than
a laptop, and keep rendered movies that others need to review outside
temporary directories.
