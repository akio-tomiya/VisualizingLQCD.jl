# Current code structure and function I/O memo

This memo corresponds to the v6 addition in `main.tex`.

## Current source files

- `src/VisualizingLQCD.jl`: module declaration, package imports, and includes for `configuration_generation.jl` and `visualization.jl`.
- `src/visualization.jl`: defines `automatic_level2`, `ln_a`, `calculate_a`, and `create_animation`; exports `create_animation`.
- `src/configuration_generation.jl`: defines `heatbath_SU3!` and `heatbathtest_4D`; exports `heatbathtest_4D`.
- `src/header.jl`: legacy package-import helper, not included by the current module.
- `src/constants.jl`: legacy demo-parameter helper, not included by the current module.
- `test/runtests.jl`: defines `test()` and runs an integration-style smoke test.

## Current public API

- Exported: `create_animation`, `heatbathtest_4D`.
- Non-exported internal helpers: `automatic_level2`, `ln_a`, `calculate_a`, `heatbath_SU3!`.

## Function I/O inventory

| Function | Inputs | Outputs | Side effects / notes |
|---|---|---|---|
| `automatic_level2(plaqs_t)` | Unannotated; practically an `AbstractArray{<:Real}` with `minimum`, `maximum`, `mean`, `mode`, `std`. | `(level, isorange, min_val, max_val)`; practically real values. | Prints diagnostics. Mixes level calculation and display. |
| `ln_a(beta::Float64)::Float64` | `Float64` beta only. | `Float64` log lattice spacing relative to `r_0`. | Throws `ArgumentError` outside `[5.7, 6.57]`. |
| `calculate_a(beta::Float64)::Float64` | `Float64` beta only. | `Float64` lattice spacing in fm. | Uses `ln_a`; same beta range restriction. |
| `create_animation(...)` | Unannotated; practically integer lattice sizes, integer `NC`, string paths, and `Float64` beta. | No explicit return contract; current final expression is `Makie.record(...)`. | Reads an ILDG file and writes a movie. `flow_steps_in` and `scale_factor` are currently unused. |
| `heatbath_SU3!(U, NC, temps, beta)` | Unannotated; practically a 4-direction Gaugefields gauge-link collection, integer `NC`, work fields, and real beta. | Treat as `Nothing`; primary output is mutated `U`. | Destructive SU(3) heatbath update. |
| `heatbathtest_4D(...)` | Unannotated; practically integer lattice sizes, beta, integer `NC`, integer flow steps, and output path. | `plaq_t`, the last measured normalized plaquette. | Generates a configuration, applies gradient flow, and saves to `confname`. |
| `test()` | None. | No explicit return contract. | Generates a small configuration and movie; heavy for CI. |

## Immediate design implications

- Give `create_animation` a result type or named tuple containing video path, metadata path, levels, raw-equivalent levels, and frame map.
- Give `heatbathtest_4D` a `GenerationResult` containing configuration path, final plaquette, final Polyakov loop, flow steps, and beta.
- Turn `automatic_level2` into a pure `LevelStats` function and move printing to logging or metadata.
