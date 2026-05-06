# Visualization refactor status

This memo tracks the VisualizingLQCD.jl visualization refactor outside the
`docs/codex/visualization_refactor_v7/` reference directory. Do not edit the v7
reference materials for status updates.

Last updated during the PR9 thermal-preset work.

## Current branch state

- `main` currently contains PR1 through PR6 locally.
- `codex/pr7-raw-high-levels` is stacked on `main`.
  - Commit: `68524da Add raw-high plaquette level target`
  - Adds an opt-in raw-high plaquette deviation target.
- `codex/pr8-plaquette-render-options` is stacked on PR7.
  - Commit: `c8f15c0 Add plaquette render diagnostics`
  - Adds raw-high color range metadata, transparency, and light/dark render
    themes.
- `codex/pr9-plaquette-thermal-preset` is stacked on PR8.
  - Adds an opt-in plaquette thermal render style.
  - Uses dark theme plus cyan/turquoise/yellow/red colors for raw-high
    plaquette deviation.
- A local untracked `Manifest.toml` exists from dependency resolution. Keep it
  out of unrelated commits unless the project deliberately decides to track a
  manifest.

## PR History

### PR1: current defaults

- Branch: `codex/refactor-visualization-v7`
- Commit: `5118534 Collect current visualization defaults`
- Status: merged.
- Purpose: collect magic numbers into named constants while preserving current
  behavior.

### PR2: Euclidean slice display

- Branch: `codex/pr2-euclidean-slice-display`
- Commit: `c8c312a Remove real-time labels from animation`
- Status: merged.
- Purpose: remove yoctosecond and real-time-like display wording. The fourth
  direction is a Euclidean lattice direction, not real-time evolution.

### PR3: metadata sidecar

- Branch: `codex/pr3-metadata-sidecar`
- Commit: `4c9dc58 Write animation metadata sidecar`
- Status: merged.
- Purpose: write JSON sidecar metadata next to rendered movies.

### PR4: transform and level helpers

- Branch: `codex/pr4-transform-levels`
- Commit: `a7e9f74 Separate display transform and level selection`
- Status: merged.
- Purpose: isolate `-log(p + 1e-7)`, inverse transform metadata, and legacy
  level selection.

### PR5: plaquette observable separation

- Branch: `codex/pr5-observables`
- Commit: `5065c88 Separate plaquette observable calculation`
- Status: merged.
- Purpose: move plaquette-plane observable calculation out of the main animation
  flow.

### PR6: level semantics

- Branch: `codex/pr6-level-semantics`
- Commit: `4916f44 Record raw-equivalent plaquette levels`
- Status: merged.
- Purpose: record raw-equivalent levels and make clear that upper levels after
  the legacy neglog transform correspond to low raw plaquette deviation.

### PR7: raw-high plaquette target

- Branch: `codex/pr7-raw-high-levels`
- Commit: `68524da Add raw-high plaquette level target`
- Status: pushed; merge status should be checked before starting dependent PRs.
- Purpose: add opt-in high raw plaquette-deviation rendering without changing
  the default.
- User-facing option:

```julia
create_animation(...; level_target=VisualizingLQCD.LEVEL_TARGET_RAW_HIGH)
```

### PR8: plaquette render diagnostics

- Branch: `codex/pr8-plaquette-render-options`
- Commit: `c8f15c0 Add plaquette render diagnostics`
- Status: pushed; stacked on PR7.
- Purpose: make raw-high display easier to diagnose before changing defaults.
- Adds:
  - global quantile color range for raw-high plaquette display,
  - raw-high alpha/transparency settings,
  - `render_theme=:light/:dark`,
  - render style metadata.

### PR9: plaquette thermal render preset

- Branch: `codex/pr9-plaquette-thermal-preset`
- Status: in progress during this memo update.
- Purpose: add a named thermal style inspired by the reference movie/screenshot.
- User-facing option:

```julia
create_animation(...;
    level_target=VisualizingLQCD.LEVEL_TARGET_RAW_HIGH,
    render_style=VisualizingLQCD.RENDER_STYLE_PLAQUETTE_THERMAL)
```

## Important Semantic Finding

The legacy display transform is monotone decreasing:

```julia
display = -log(p + epsilon)
raw = exp(-display) - epsilon
```

Therefore high display levels correspond to low raw plaquette deviation. The
legacy movie should be read as a low-raw-deviation surface, not as a high raw
plaquette-deviation surface.

The transform must remain available:

```julia
-log(p + 1e-7)
```

It is useful in practice for threshold exploration and comparison.

## Current Visualization Observations

The README sample configuration is:

```text
/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg
```

PR7 confirmed that raw-high surfaces can be rendered. PR8 improved visibility
with dark background, fixed color range, and transparency.

Observed issues:

- `viridis + transparency` is readable but looks somewhat glassy.
- The visible objects can look fewer/sparser than desired.
- Nested iso-surfaces can hide or visually confuse the highest regions.
- A reference movie/screenshot suggests a better style:
  - black background,
  - cyan/turquoise bulk surfaces,
  - yellow/red highlights for higher-value regions,
  - stronger, less glassy surface appearance,
  - subdued gray grid.

Temporary smoke-test variant names used for visual comparison:

- `baseline-q90`: q90, q95, q98, q99. Current PR8 baseline.
- `wide-q85`: q85, q90, q95, q98. More connected bulk.
- `core-q95`: q95, q98, q99. High cores only.
- `wide-q80`: q80, q90, q95, q98. Broad diagnostic.
- `single-q99`: q99 only. Checks whether nested surfaces hide high regions.

The comparison page from the PR8 smoke run is:

```text
/private/tmp/VisualizingLQCD-smoke-pr8/view-variants.html
```

This path is temporary and should not be committed.

PR9 thermal smoke variants:

- `thermal-q85-a065`: q85, q90, q95, q98 with alpha 0.65.
- `thermal-q80-a065`: q80, q90, q95, q98 with alpha 0.65.
- `thermal-q85-solid`: q85, q90, q95, q98 with alpha 1.0 and no transparency.
- `thermal-core`: q85, q95, q98, q99 with alpha 0.65.

The PR9 comparison page is:

```text
/private/tmp/VisualizingLQCD-smoke-pr9/view.html
```

This path is temporary and should not be committed.

## Testing Notes

Use Julia from juliaup explicitly:

```bash
/Users/akio/.juliaup/bin/julia --project=/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

Avoid running smoke tests from the repository root. `load_gaugefield!` may
create a large `tempconf.dat` in the current working directory. Prefer:

```text
/private/tmp/VisualizingLQCD-smoke-prN
/private/tmp/VisualizingLQCD-test-prN
```

and remove only generated temporary files such as `tempconf.dat` afterward.

`Pkg.test()` currently has a separate test harness problem: `test/Project.toml`
uses the same package name/UUID as the root package, and `Pkg.test()` can fail
with `Missing source file` after dependency precompile. For now, direct test
execution has been used:

```bash
/Users/akio/.juliaup/bin/julia \
  --project=/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl \
  -e 'include("/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl/test/runtests.jl")'
```

PR8 direct test result:

```text
VisualizingLQCD.jl | 15 pass
```

## Proposed Future PR List

### PR10: choose plaquette default

Goal: change the default only after PR9 visual review.

Candidate default:

- raw-high plaquette deviation,
- thermal-style dark render,
- quantiles likely around q80 or q85 through q98.

Keep legacy neglog available explicitly:

```julia
level_target=VisualizingLQCD.LEVEL_TARGET_LEGACY_NEGLOG_HIGH
```

### PR11: test harness cleanup

Goal: make tests safer and clearer.

Scope:

- Fix or remove the duplicate `test/Project.toml` package identity issue.
- Separate lightweight unit tests from opt-in rendering smoke tests.
- Ensure smoke outputs go to `/private/tmp`.
- Ensure large temporary files are cleaned.

### PR12: README/user docs update

Goal: document the new semantics and options.

Scope:

- Explain Euclidean fourth-direction slice sequence.
- Explain metadata sidecars.
- Explain legacy neglog behavior and raw-high plaquette behavior.
- Add example calls for thermal style and legacy comparison.

### PR13: renderer separation

Goal: split Makie rendering from I/O and observable computation.

Scope:

- Move figure/axis/record logic into renderer helpers or `src/renderers.jl`.
- Renderer receives display field, coordinates, levels, style, output path, and
  metadata fragments.
- Renderer should not know ILDG, Wilson loops, or observable-specific details.

This was initially considered earlier, but the visual-design work became more
urgent. Keep it after the plaquette visual default is settled.

### PR14: topological charge density observable

Goal: add topological charge density visualization.

Notes:

- Use Gaugefields.jl topological charge examples as reference.
- Color semantics differ from plaquette deviation because topological charge
  density has sign.
- It likely needs a diverging colormap and positive/negative surface handling.
- Do not reuse plaquette thermal defaults blindly.

### Separate Gaugefields.jl Project

SU(2) instanton generation and SU(2)-in-SU(3) embedding should stay in a
separate Gaugefields.jl-focused thread/project. Once that fixture exists, it can
be used here to validate topological charge density visualization.
