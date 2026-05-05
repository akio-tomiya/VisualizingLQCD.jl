# Visualization refactor status

This memo tracks the VisualizingLQCD.jl visualization refactor outside the
`docs/codex/visualization_refactor_v7/` reference directory. Do not edit the
v7 reference materials for status updates.

## Merged PRs

- PR1: collect current magic numbers as named constants.
- PR2: remove real-time-like and yoctosecond labels from the default movie.
- PR3: write animation metadata sidecar JSON.
- PR4: separate display transform and legacy level selection helpers.
- PR5: separate plaquette observable calculation from `create_animation`.
- PR6: record raw-equivalent plaquette levels and level semantics in metadata.

## Current pipeline shape

The current `create_animation` path is still behavior-preserving overall:

1. Load an ILDG gauge configuration.
2. Measure the current plaquette-plane raw deviation
   `p = 1 - real(tr(U_loop)) / NC`.
3. Apply the legacy display transform `-log(p + 1e-7)`.
4. Choose legacy display levels with `mean + 1.2std : 0.05 : max`.
5. Render the contour movie.
6. Write metadata JSON next to the movie.

The generated movie no longer labels the fourth Euclidean direction as real
time. Frame-to-fourth-direction-slice correspondence is stored in metadata.

## Important semantic finding

The legacy display transform is monotone decreasing:

```julia
display = -log(p + epsilon)
raw = exp(-display) - epsilon
```

Therefore high display levels correspond to low raw plaquette deviation. The
current legacy movie should be read as a low-raw-deviation surface, not as a
high raw plaquette-deviation surface.

Metadata now records:

- `display_transform.inverse_formula = "exp(-level) - epsilon"`
- `display_transform.raw_focus_for_upper_levels = "low_raw_deviation"`
- `level_selection.raw_equivalent_levels`
- `level_selection.raw_focus_for_upper_levels = "low_raw_deviation"`

For the README sample configuration, the PR6 smoke test produced raw-equivalent
levels in approximately this range:

- max raw equivalent: `0.0003440277910435181`
- min raw equivalent: `9.784946792734452e-6`

## Smoke test reference

Use the README sample configuration:

```text
/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg
```

Use Julia from juliaup explicitly when running outside the repository, because
`/usr/local/bin/julia` may point to Julia 1.8 while this environment has been
instantiated with Julia 1.12:

```bash
/Users/akio/.juliaup/bin/julia --project=/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

Write smoke outputs outside the repository, for example:

```text
/private/tmp/VisualizingLQCD-smoke-pr6/readme-smoke.mp4
/private/tmp/VisualizingLQCD-smoke-pr6/readme-smoke.metadata.json
```

`load_gaugefield!` may create a large `tempconf.dat` in the current working
directory. Run smoke tests from `/private/tmp/...` and remove that temporary
file after the run.

## Local dependency note

`Pkg.instantiate()` generated a local `Manifest.toml`. It has intentionally not
been committed in these small refactor PRs. Keep it out of unrelated commits
unless the project decides to track a manifest.

## Recommended next PRs

1. PR7: add a high raw plaquette-deviation visualization option.
   - Keep the legacy mode.
   - Add an option that targets high raw `p`.
   - Save the level target and raw focus in metadata.
   - Compare legacy and raw-high movies using the README sample configuration.
2. PR8: separate the Makie renderer into `src/renderers.jl`.
   - Renderer should receive display field, axes, levels, style, and output.
   - Renderer should not know ILDG I/O, Wilson loops, or observable details.
3. PR9: restructure tests.
   - Keep lightweight unit tests always on.
   - Make README configuration rendering smoke opt-in.
   - Write smoke outputs to `/private/tmp` and clean `tempconf.dat`.
4. PR10: update README and user-facing docs.
   - Remove real-time wording.
   - Explain Euclidean slice sequence.
   - Explain legacy low-raw-deviation behavior and the new raw-high option.
   - Document metadata sidecars.

## Separate project thread

SU(2) instanton generation and SU(2)-in-SU(3) embedding should be handled as a
separate Gaugefields.jl-focused project. Once that fixture exists, it can be
used here to validate topological charge density visualization.
