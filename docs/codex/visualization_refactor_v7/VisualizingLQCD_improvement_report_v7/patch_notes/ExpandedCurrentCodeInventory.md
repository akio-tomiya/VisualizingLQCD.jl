# Expanded current code inventory for v7

This note adds the parts that can be written out from the current source without changing the package.

## Added to the PDF

- Current call graph:
  - `create_animation -> calculate_a -> ln_a`
  - `create_animation -> automatic_level2`
  - `heatbathtest_4D -> heatbath_SU3!`
  - `test() -> heatbathtest_4D -> create_animation`
- External dependency map:
  - Gaugefields / Wilsonloop / Makie / Statistics responsibilities are separated.
- `create_animation` local-variable inventory:
  - `U1`, `Uloop`, `temps`, `plaqs_t`, `levels`, axes, figure, frame variables, and legacy time-label variables.
- Generation-side local-variable inventory:
  - `temps2`, `temps3`, `mapfunc!`, `loops`, `factor`, `numhb`, `flow_steps`, and generated output file.
- Failure modes and validation points:
  - missing file, shape mismatch, empty levels, negative or non-finite plaquette values, beta range, backend failure, and heavy CI tests.
- Proposed result contracts:
  - `AnimationResult`
  - `GenerationResult`
- Proposed signatures for separated functions:
  - configuration loading, observable measurement, display transform, level selection, renderer, metadata, generation.
- Metadata fields that are already available from the current implementation.
- Small pure helper functions that can be added before the full refactor.

## Most useful immediate additions to code

1. Add `make_frame_map(NT; loops=1)` and use `(i - 1) % NT + 1`.
2. Add `raw_equivalent_level_neglog(L; epsilon=1e-7)`.
3. Add `legacy_mean_std_levels(display; multiplier=1.2, step=0.05)`.
4. Write a JSON sidecar with current parameters, even before full modularization.
5. Return a small `AnimationResult` from `create_animation`.
