# Visualization refactor status

This memo tracks the VisualizingLQCD.jl visualization refactor outside the
`docs/codex/visualization_refactor_v7/` reference directory. Do not edit the v7
reference materials for status updates.

Last updated on 2026-05-10 during the visual-review UI comment-tag pass.

## Active note: 2026-05-10 visual-review comment tags

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/visual-review-comment-tags`.
- Starting point: PR #25 was merged into `main`.
- User feedback:
  - the `needs work` checkbox was being used as a workaround for neutral or
    positive comments;
  - reviewers need an obvious place to leave comments that are not fix requests.
- Implemented:
  - add `notable / promising` and `comment only` checkboxes to both topology
    visual review pages;
  - clarify the note placeholder: note-only rows are copied into the generated
    review text;
  - update `docs/codex/visual_review_io_methodology.md` so future visual review
    pages do not force comments through `needs work`.
- Validation:
  - generated a fixture visual-review page with
    `scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl`;
  - generated a config visual-review page with
    `scripts/topology_fixtures/render_topological_density_config_review.jl`;
  - confirmed the generated HTML contains `notable / promising`,
    `comment only`, and the note-only placeholder text;
  - passed `/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl`;
  - passed `/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`.

## Active note: 2026-05-10 `24^3 x 32` topological-density config review

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/topological-config-review-24x32-result`.
- Starting point: PR #23 was merged into `main`.
- Goal: run the new config-level still-review script on a real `24^3 x 32`
  ILDG configuration before attempting a full topological-density movie.
- Input:

```text
/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg
```

- Output review page:

```text
file:///private/tmp/VisualizingLQCD-topological-config-review-24x32/view.html
```

- Command:

```text
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_review.jl --nx 24 --ny 24 --nz 24 --nt 32 --nc 3 --beta 6.0 --input /Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg --render-mode both --slice4 auto --auto-slices 4 --figure-size 560 --output-dir /private/tmp/VisualizingLQCD-topological-config-review-24x32
```

- Result:
  - run completed locally; no remote machine was needed for still review;
  - selected slices: `6`, `5`, `28`, `27`;
  - generated four contour PNGs, four volume PNGs, and `view.html`;
  - output size: about `1.3M`;
  - total topological charge from the clover density: approximately `0.023`;
  - density range: approximately `[-0.001479, 0.001732]`;
  - default balanced upper-tail volume levels produced non-empty positive and
    negative meshes for all four selected slices.
- Validation:

```text
/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass before the `24^3 x 32` review run

git diff --check
result: pass before this memo update
```

- User visual review pasted on 2026-05-10:
  - all eight stills were marked visible:
    `contour` and `volume` for slices `6`, `5`, `28`, and `27`;
  - `volume / slice4=27` was marked `needs-work`, with the note that this is
    not necessarily a required fix and that the visual appearance is good;
  - this supports using the `24^3 x 32` config review path for human visual
    checks, unlike the tiny `3^3 x 2` smoke pages.
- User action needed next:
  - PR #24 can be merged if the record-only memo update looks fine;
  - after merge, generate a short movie or a denser still review around the
    promising `slice4=27` volume view.

## Active note: 2026-05-10 topological-density config review

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/topological-config-review`.
- Starting point: PR #22 was merged into `main`.
- Goal for this small PR: add a low-cost visual validation path for real or
  semi-real gauge configurations before spending time on full topological
  density movies.
- Implemented:
  - new script
    `scripts/topology_fixtures/render_topological_density_config_review.jl`;
  - it loads an ILDG gauge configuration, computes clover topological charge
    density, selects fourth-direction slices, and writes still PNGs plus a
    review HTML page;
  - `--render-mode contour`, `--render-mode volume`, and `--render-mode both`
    are supported;
  - `--slice4 auto` selects slices with largest `max(abs(q))`; explicit comma
    lists such as `--slice4 1,8,16` are also supported;
  - the review HTML reuses the checkbox/copy-text workflow used by the SU(2)
    scalar fixture review pages.
- Local configuration inventory:
  - `/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg`;
  - size: about `243M`;
  - use this for the next visual review, preferably as stills first rather than
    a full movie.
- Validation so far:

```text
tiny hot 3x3x3x2 ILDG configuration generated under /private/tmp
result: pass

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_review.jl --nx 3 --ny 3 --nz 3 --nt 2 --nc 3 --beta 6.0 --input /private/tmp/VisualizingLQCD-topoconfig-hot-3322.ildg --render-mode both --slice4 auto --auto-slices 2 --figure-size 320 --output-dir /private/tmp/VisualizingLQCD-topological-config-review-smoke
result: pass, contour/volume still review page generated

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_topological_density_config_review.jl --nx 3 --ny 3 --nz 3 --nt 2 --nc 3 --beta 6.0 --input /private/tmp/VisualizingLQCD-topoconfig-hot-3322.ildg --render-mode both --slice4 auto --auto-slices 2 --level-quantiles 0.5,0.9 --figure-size 320 --output-dir /private/tmp/VisualizingLQCD-topological-config-review-smoke-lowq
result: pass, volume mesh info is non-empty for both selected slices

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass

git diff --check
result: pass
```

- Note:
  - on a `3^3 x 2` smoke configuration, default topological upper-tail
    quantiles can legitimately produce empty volume meshes after smoothing;
  - the low-quantile smoke is only to exercise the mesh path on tiny data, not
    a suggested physical display default.
- User visual review on 2026-05-10:
  - `/private/tmp/VisualizingLQCD-topological-config-review-smoke/view.html`
    looked empty;
  - the low-quantile smoke page showed visible objects, but the contour cases
    were shell-like and not useful, and the volume case looked low-poly;
  - conclusion: these tiny `3^3 x 2` pages are code-path smoke tests only and
    should not be used for visual-quality judgment;
  - future review requests to the user should be explicit about what action is
    needed, and should target meaningful `24^3 x 32` or larger configuration
    outputs rather than tiny smoke pages.
- Next validation before/after PR:
  - run unit tests and `Pkg.test()`;
  - run the new script on the `24^3 x 32` Dropbox configuration. If it is slow
    on the MacBook Air, move that run to `studio1` or `notegpu1`.

## Active note: 2026-05-10 topological-density volume renderer

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/topological-volume-renderer`.
- Starting point: PR #21 was merged into `main`.
- Goal for this small PR: promote the signed topological-density volume
  prototype from the fixture smoke script into the main rendering helpers while
  keeping the existing contour renderer available.
- Implemented:
  - new opt-in render style `RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME`;
  - `topological_charge_display_level_setup(...;
    render_style=RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME)` returns a mesh
    render setup;
  - positive and negative density bodies are split as `max(q, 0)` and
    `max(-q, 0)`, then rendered as separate solid meshes;
  - the mesh path reuses the action-density blob geometry pipeline
    (periodic smoothing, upsampling, post smoothing, Taubin mesh smoothing);
  - metadata records positive/negative body levels, sign colors, geometry
    method, smoothing parameters, and mesh source;
  - the topology fixture script now calls the package helper instead of keeping
    its own duplicate volume prototype.
- Deliberate choice:
  - default topological-density rendering remains
    `RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED` for now;
  - volume rendering is opt-in until it is checked on real gauge-field
    topological density, not only scalar SU(2) fixtures.
- Validation so far:

```text
/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-volume-main-pr2 --case-set basic --style-preset wide --render-mode both --no-movie
result: pass

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-volume-main-debug --case-set debug --style-preset all --render-mode volume --no-movie
result: pass, 27 PNG cards plus view.html

local create_animation smoke with a tiny hot 3x3x3x2 gauge field and
render_style=RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME
result: pass, MP4 and metadata written under /private/tmp

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass

git diff --check
result: pass
```

- Next before merge: visually review a real or semi-real gauge-field
  topological-density movie/still using the opt-in volume renderer.

## Active note: 2026-05-10 topological-density style preset visibility

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/topological-density-style-presets`.
- PR: #21.
- Issue found during visual review: the first smoke renders mixed visible and
  invisible cases. `single-plus-small-rho` was blank for all presets, while
  `single-plus-spatial-boundary` was blank for `balanced`/`wide` and visible
  for `core`. Other centered/off-center/DIGA cases were visible.
- Diagnosis:
  - the scalar fixture data and selected levels were present in the rendered
    slice, so this was not a missing-density problem;
  - low 4D quantile levels plus too-low color ceilings can make GLMakie's 3D
    contour effectively disappear for very peaked one-sign fixtures;
  - anchoring the positive/negative color range at zero made blank cases
    visible, but it also produced box-like low-level surfaces and broke the
    clean centered-sphere appearance, so that route was rejected.
- Current fix direction: keep the sign-separated contour implementation, but
  move topological-density style presets to upper-tail quantiles:
  - `balanced`: levels `(0.99, 0.999)`, color ceiling `0.9999`;
  - `wide`: levels `(0.99, 0.995, 0.999)`, color ceiling `0.9999`;
  - `core`: levels `(0.995, 0.9995)`, color ceiling `0.9999`.
- Smoke candidates rendered before committing:

```text
/private/tmp/VisualizingLQCD-topology-style-proposed-balanced/view.html
/private/tmp/VisualizingLQCD-topology-style-proposed-wide/view.html
/private/tmp/VisualizingLQCD-topology-style-proposed-core/view.html
/private/tmp/VisualizingLQCD-topology-style-proposed-contact.png
```

- Visual result: all debug cases are visible with the proposed presets, and the
  centered/off-center cases remain sphere-like instead of box-like.
- Interpretation of `single-plus-spatial-boundary`: the periodic boundary
  condition is represented correctly as pieces wrapping across the fundamental
  domain. It still looks like separated caps or a shell because a contour plot
  is an iso-surface cut by the displayed box; it is a useful boundary diagnostic
  but not a filled-volume visual.
- Validation after applying the preset constants:

```text
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-style-balanced --case-set debug --style-preset balanced --no-movie
result: pass

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-style-wide --case-set debug --style-preset wide --no-movie
result: pass

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-style-core --case-set debug --style-preset core --no-movie
result: pass

pixel/color visibility classifier over all 27 PNGs
result: all visible

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass

git diff --check
result: pass
```

## Active note: 2026-05-10 visual-check review IO

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/topological-density-style-presets`.
- User-review issue: reviewing separate `balanced`, `wide`, and `core` pages is
  cumbersome, and reporting visible/missing cases back into Codex by hand is
  error-prone.
- Implemented review IO in
  `scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl`:
  - `--style-preset all` renders `balanced`, `wide`, and `core` into
    subdirectories under one output directory and writes one combined
    `view.html`;
  - every image/video card has visual-check boxes: `visible`, `not visible`,
    `good`, `shell/hollow`, and `needs work`;
  - each card has a short free-text note field;
  - the bottom of the page has a copyable textarea that updates live with
    Markdown-style review notes;
  - review state is saved in browser `localStorage` for the page path.
- Reusable method memo:

```text
docs/codex/visual_review_io_methodology.md
```

- Current review page generated locally:

```text
file:///private/tmp/VisualizingLQCD-topology-style-review/view.html
```

- Validation:

```text
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-style-review --case-set debug --style-preset all --no-movie
result: pass, 27 PNGs, one combined view.html

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-style-review-single --case-set basic --style-preset wide --no-movie
result: pass, single-preset path still works

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass

git diff --check
result: pass
```

- Intended user workflow:
  1. open the combined review page;
  2. check boxes while visually inspecting each rendered case;
  3. copy the bottom textarea with the `Copy review text` button;
  4. paste the generated text back into the PR, issue, or Codex thread.
- User visual review pasted on 2026-05-10:
  - all listed cases are visible after the upper-tail preset change;
  - `balanced / diga-plus-minus`: negative blue is hard to see;
  - `balanced / single-plus-spatial-boundary`: shell-like;
  - `balanced / diga-three-lump-plus-plus-minus`: visible but too faint;
  - `wide / single-plus-spatial-boundary`: visible and shell-like;
  - `wide / diga-three-lump-plus-plus-minus`: visible, but negative blue is
    too faint;
  - `core / single-plus-spatial-boundary`: visible and shell-like;
  - general issue: grid/axis lines look missing or visually wrong because the
    current translucent contours let axes/grid show through lumps.
- Next visual-tuning hypothesis: make topology fixture contour surfaces opaque
  or nearly opaque and brighten the negative colormap, while keeping the
  boundary fixture as a known shell/cut-surface diagnostic.
- Follow-up tuning after this review:
  - rejected transparency/alpha-only changes because they still leave axes/grid
    visually bleeding through surfaces;
  - set topological-density contour transparency to `false` and alpha to `1.0`
    for all three style presets;
  - changed the negative signed colormap from `(:blue, :cyan)` to
    `(:deepskyblue, :cyan)` to keep the negative sign blue-family while making
    it readable on black backgrounds;
  - regenerated the combined review page at the same path so browser refresh
    shows the updated images.
- Review UI persistence fix:
  - initial review UI keyed `localStorage` only by `location.pathname`, which
    caused old checkbox/note state to reappear after regenerating the same
    `view.html`;
  - the generated HTML now embeds a review-session id and includes it in the
    `localStorage` key;
  - the session id uses millisecond resolution so rapid regeneration of the
    same review page is unlikely to reuse stale browser state;
  - added a `Clear checks` button to reset the current review state explicitly;
  - documented this pitfall in `docs/codex/visual_review_io_methodology.md`.
- Validation for persistence fix:

```text
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-style-review --case-set debug --style-preset all --no-movie
result: pass, generated HTML has review session id and Clear checks button

prechecked input count in generated HTML
result: 0

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

git diff --check
result: pass
```
- Validation after opaque/negative-color follow-up:

```text
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-style-review --case-set debug --style-preset all --no-movie
result: pass, 27 cards, 27 PNGs, no missing asset references

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass
```
- Second user visual review pasted on 2026-05-10 after opaque/negative-color
  tuning:
  - all `balanced`, `wide`, and `core` debug cases were marked `visible`;
  - `balanced / single-plus-spatial-boundary` and
    `wide / single-plus-spatial-boundary` were marked `shell`;
  - no cases were marked `needs work`;
  - this review supports keeping the opaque topology contour preset as the
    current contour baseline.
- New follow-up question: try a volume-rendering pattern similar to the current
  action-density blob renderer. Because topological charge density is signed,
  the safe design is to render positive and negative bodies separately, with
  separate colors/meshes and metadata, rather than treating it as a single
  positive scalar field.
- Implemented a fixture-smoke prototype, not yet the main `create_animation`
  renderer:
  - `--render-mode contour` keeps the current signed contour output;
  - `--render-mode volume` renders signed solid meshes by splitting
    `max(q, 0)` and `max(-q, 0)`;
  - `--render-mode both` emits both contour and volume cards in one review page;
  - the volume path reuses the action-density blob solid-mesh extraction,
    upsampling, post-smoothing, and Taubin mesh smoothing;
  - positive volume color is opaque yellow, negative volume color is opaque
    cyan-blue;
  - review labels include `volume` for volume cards.
- Current volume review page:

```text
file:///private/tmp/VisualizingLQCD-topology-volume-review/view.html
```

- Visual result from local inspection: centered and DIGA cases render as solid
  positive/negative blobs. The spatial-boundary case still appears as separated
  caps because the displayed fundamental domain cuts the periodic object, but it
  reads more like a cut solid than a hollow transparent shell.
- Validation for volume prototype:

```text
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-volume-review --case-set debug --style-preset all --render-mode volume --no-movie
result: pass, 27 review cards

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-render-mode-both-smoke --case-set basic --style-preset wide --render-mode both --no-movie
result: pass, 6 review cards

git diff --check
result: pass

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass
```
- User visual review pasted on 2026-05-10 for the volume review page:
  - all `balanced / volume / ...` debug cases were marked `visible`;
  - all `wide / volume / ...` debug cases were marked `visible`;
  - all `core / volume / ...` debug cases were marked `visible`;
  - no `shell`, `needs work`, or missing cases were reported for the volume
    prototype in this review.
- Current interpretation: the signed volume prototype is viable as a visual
  diagnostic. It should remain clearly marked as a prototype/smoke path until
  the same positive/negative solid-mesh approach is promoted into the main
  `create_animation` renderer with explicit metadata and tests.
- Final close-out validation for the branch:

```text
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-topology-final-smoke --case-set basic --style-preset wide --render-mode both --no-movie
result: pass, contour and volume cards generated in one review page

/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass

git diff --check
result: pass
```

## Active note: 2026-05-10 SU(2) instanton scalar fixtures

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/su2-instanton-fixture`.
- Starting point: PR #19 (`codex/topological-density-rendering`) was merged,
  then `main` was fast-forwarded to `4cd6a64`.
- Context: SU(3) instanton gauge-field embedding is being developed in a
  separate thread. This branch keeps VisualizingLQCD moving by adding SU(2)
  continuum instanton topological-density fixtures first.
- Scope:
  - add scalar SU(2) instanton density fixture
    `q(x) = sign * 6 rho^4 / (pi^2 (r^2 + rho^2)^4)` sampled on a periodic
    four-dimensional lattice;
  - normalize each sampled lump to the requested integer charge by default so
    finite-volume/debug grids have controlled total `Q`;
  - add DIGA-like superposition fixtures for qualitative `++` and `+-`
    signed-rendering tests;
  - add diagnostics for total charge, positive/negative charge, max/min peak
    values and peak indices;
  - add `scripts/topology_fixtures/diagnose_su2_instanton_fixtures.jl`.
- Important limitation: these fixtures are scalar density fields, not lattice
  gauge-field instanton solutions. They validate signed rendering, thresholds,
  position/radius/sign handling, and qualitative multi-lump behavior; they do
  not validate the Gaugefields.jl clover topological-charge operator.
- Validation so far:

```text
/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass, 144 tests, render smoke skipped

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/diagnose_su2_instanton_fixtures.jl
result: pass
selected outputs: single-plus Q=1.0000000000000002,
single-minus Q=-1.0000000000000002,
DIGA ++ Q=1.9999999999999993,
DIGA +- Q=-3.3306690738754696e-16

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass, 144 tests, render smoke skipped

git diff --check
result: pass
```

- Next validation step after this branch: use these fixtures to render small
  signed topological-density movies/stills and tune positive/negative color
  levels before moving to Gaugefields.jl-generated SU(2) gauge-field
  instantons.
- Follow-up in the same branch before merge:
  - adjusted `signed_symmetric_levels` so one-sign density fields only request
    contour levels for the sign actually present in the data;
  - added `scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl`,
    which renders single-plus, single-minus, and DIGA `+-` scalar fixtures to
    PNG/MP4 plus a local HTML review page;
  - local smoke output:

```text
/private/tmp/VisualizingLQCD-su2-instanton-fixtures/view.html
/private/tmp/VisualizingLQCD-su2-instanton-fixtures/single-plus-centered.mp4
/private/tmp/VisualizingLQCD-su2-instanton-fixtures/single-minus-centered.mp4
/private/tmp/VisualizingLQCD-su2-instanton-fixtures/diga-plus-minus.mp4
```

  - representative `ffprobe` for `diga-plus-minus.mp4`: `1120x1120`,
    `36` frames, `12` fps, duration `3.0` seconds.
  - validation after this follow-up:

```text
/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass, 146 tests, render smoke skipped

/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --output-dir /private/tmp/VisualizingLQCD-su2-instanton-fixtures
result: pass

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass, 146 tests, render smoke skipped

git diff --check
result: pass
```

## Active note: 2026-05-10 topological-density signed rendering

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/topological-density-rendering`.
- Starting point: PR #18 (`codex/topological-density-entry`) was merged, then
  `main` was fast-forwarded to `cff0f7f`.
- Goal for this small PR: expose an opt-in signed topological charge density
  contour renderer without changing the current action-density default.
- Scope:
  - add `LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY` and
    `RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED`;
  - select positive and negative contour levels from symmetric magnitude
    quantiles of the signed density;
  - use a signed blue-white-red colormap on a dark theme;
  - keep display metadata separate from raw plaquette metadata so the focus is
    recorded as positive/negative topological charge density;
  - route `create_animation(...; level_target=:topological_charge_density)` to
    the clover topological density observable from PR #18.
- Validation so far:

```text
/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass, 124 tests, render smoke skipped

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass, 124 tests, render smoke skipped

git diff --check
result: pass
```

- Still deferred:
  - visual tuning on an actual nontrivial topological configuration;
  - instanton/SU(2)-in-SU(3) validation fixture;
  - volume/dual-surface treatment if contour-only signed rendering is too
    sparse or visually ambiguous.

## Active note: 2026-05-10 topological-density observable entry

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Branch: `codex/topological-density-entry`.
- Starting point: PR #17 (`codex/yitp-sample-gif`) was merged, then `main` was
  fast-forwarded to `e09ba0a`.
- Goal for this small PR: add topological charge density as an observable-level
  entry point without changing the default renderer or README media.
- Scope:
  - add clover-method topological charge density computation following the
    Gaugefields.jl topological charge example structure;
  - record signed-density metadata separately from plaquette/action-density
    metadata;
  - add lightweight tests on epsilon signs, method validation, loopset shape,
    metadata, and a cold `2^4` gauge field whose density should be zero.
- Implementation note: current Gaugefields.jl evaluates a vector of Wilson
  loops with four auxiliary temp gauge fields, so this observable uses `5`
  total temp fields (`1` output plus `4` auxiliaries).
- Validation:

```text
/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass, 111 tests, render smoke skipped

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass, 111 tests, render smoke skipped

git diff --check
result: pass
```

- Explicitly deferred:
  - diverging positive/negative rendering;
  - topological-density movie presets;
  - instanton/SU(2)-in-SU(3) fixtures, which remain a Gaugefields.jl-side
    thread/project before they are used here as validation data.

## Active note: 2026-05-10 consistency tests

- Machine: `Akios-MacBook-Air.local`.
- Workdir:

```text
/Users/akio/repository/VisualizingLQCD_v2/VisualizingLQCD.jl
```

- Goal: add and run lightweight consistency tests without doing heavy local
  gauge generation or GLMakie movie rendering by default.
- Test design added in `test/runtests.jl`:
  - `Frame selection contracts`: `slice4_for_frame`,
    `total_movie_frames`, `movie_duration_seconds`, and `frame_slice_map`
    must agree. Sequence mode checks equal slice counts; fixed mode checks
    all frames point to the fixed fourth-direction slice.
  - `Camera orbit contracts`: orbit camera defaults stay orthographic/fit;
    the README-style full-turn loop has constant azimuth steps, including the
    last-frame to first-frame loop boundary.
  - `Metadata contracts`: animation metadata must report
    `frame_count=768`, `duration_seconds=768/14`, `figure_size=[480, 480]`,
    a matching `frame_map`, and the Euclidean/not-real-time interpretation.
  - `Display and render setup contracts`: preserve the neg-log transform,
    current action-density default, theme/style defaults, action-density blob
    geometry creation, and palette/color setup.
  - `Sample artifact contracts`: README points at the current full-turn sample
    GIF, the display width is `200`, and the expected GIF/MP4 files exist.
  - `Optional render smoke`: the old heavy `heatbathtest_4D` +
    `create_animation` smoke test is still available, but only when
    `VISUALIZING_LQCD_RUN_RENDER_SMOKE=1` is set.
- Code support added in `src/metadata.jl`:
  - `movie_duration_seconds(...)`.
  - metadata `render.frame_count` and `render.duration_seconds`.
- Removed `test/Project.toml` and `test/Manifest.toml` from the tracked test
  tree. They described a second nested package with the same
  `VisualizingLQCD` UUID and caused `Pkg.test()` to resolve the package under
  test inconsistently.
- Test results:

```text
/Users/akio/.juliaup/bin/julia --project=. test/runtests.jl
result: pass, 92 tests, render smoke skipped

/Users/akio/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
result: pass, 92 tests, render smoke skipped
Julia: 1.12.4

/Users/akio/.juliaup/bin/julia +1.10 --project=. test/runtests.jl
result: failed before tests because the untracked root Manifest.toml is a
Julia 1.12 manifest and pulls an incompatible PrecompileTools/JLD2 stack for
Julia 1.10. This is an environment/manifest issue, not a code-test failure.

Clean-copy Julia 1.10 check without root Manifest:
copy: /private/tmp/VisualizingLQCD-julia110-test-20260510
/Users/akio/.juliaup/bin/julia +1.10 --project=/private/tmp/VisualizingLQCD-julia110-test-20260510 test/runtests.jl
result: pass, 92 tests, render smoke skipped

/Users/akio/.juliaup/bin/julia +1.10 --project=/private/tmp/VisualizingLQCD-julia110-test-20260510 -e 'using Pkg; Pkg.test()'
result: pass, 92 tests, render smoke skipped
```

- Keep the untracked root `Manifest.toml` out of commits unless the project
  explicitly decides to track a manifest. For Julia 1.10 verification, use a
  clean checkout/copy without that manifest or generate a Julia-1.10-specific
  manifest in scratch space.
- PR-prep cleanup after reading the YITP investigation report:
  - updated this memo and `scripts/yitp_sample/README.md` so the old exact-1.0
    failure is recorded as an earlier studio1 copy/read/render-path failure,
    superseded by the checksum-matched fresh YITP diagnostics;
  - rechecked shell syntax for the helper shell scripts with `bash -n`;
  - rechecked `scripts/yitp_sample/render_large_sample.jl` and
    `scripts/yitp_sample/convert_mp4_to_gif.jl` by loading them with Julia;
  - reran `git diff --check`, `julia --project=. test/runtests.jl`, and
    `julia --project=. -e 'using Pkg; Pkg.test()'`: all passed;
  - confirmed the README MP4 is `480 x 480`, `14` fps, `768` frames,
    duration `54.857143` seconds by `ffprobe`.

## Active note: 2026-05-09 18:40 JST

- Main task: finish the README/sample movie workflow without doing heavy work
  on the MacBook Air.
- Important operating rule from the user: keep notes as the work proceeds,
  including machine names and current work directories.
- Historical failure signature: the first studio1 render/read attempt for the
  YITP-generated `32^3 x 64` configuration found many exact-`1.0`
  action-density slices after reload. This was a real input/read-path failure,
  not evidence that the whole visualization code is broken.
- Superseding investigation: a later fresh copy of the current YITP file had
  matching checksum
  `9bc6165178f48b7b49d678d807eb2293fb04bc245fd8aef61e17b81164b716d0`
  and passed both YITP-side and local Gaugefields v0.5.18 diagnostics with
  `frac_eq1=0.0` and `frac_ge099=0.0`. Therefore the current best hypothesis
  is not "the YITP file itself is corrupt"; it is that the earlier studio1
  copy/workdir/script/environment or missing preflight caused the bad render.
- Detailed failure report for a separate debugging thread:

```text
/Users/akio/Downloads/VisualizingLQCD_YITP_32x64_failure_report_20260509.md
```

- Follow-up investigation report:

```text
/Users/akio/Downloads/VisualizingLQCD_YITP_32x64_investigation_report_20260509.md
```

- At that point, the active heavy job was on `studio1`, not on the MacBook Air:

```text
machine: studio1 (Akios-Mac-Studio.local)
workdir: /Users/akio/VisualizingLQCD-yitp-local-render
pid: 37058
log: /Users/akio/VisualizingLQCD-yitp-local-render/logs/studio-generate-32323264-gf05hb40flow200.log
output: /Users/akio/VisualizingLQCD-yitp-local-render/outputs/Conf32323264beta6.0-gf05hb40flow200.ildg
```

- That studio1 run used the same Julia/Gaugefields family for generation and
  reload checks, with `40` heatbath sweeps and `200` flow steps.
- Operational rule retained from that failure: do not render a large movie
  until the saved configuration passes sanity checks (`frac_eq1 == 0`, no
  all-`1.0` slices, and sane action-density quantiles).

Result update:

- The studio1 corrective generation completed successfully.
- The process `pid=37058` finished after about 68 minutes.
- Output files:

```text
/Users/akio/VisualizingLQCD-yitp-local-render/outputs/Conf32323264beta6.0-gf05hb40flow200.ildg
/Users/akio/VisualizingLQCD-yitp-local-render/outputs/Conf32323264beta6.0-gf05hb40flow200.ildg.metadata.txt
/Users/akio/VisualizingLQCD-yitp-local-render/outputs/Conf32323264beta6.0-gf05hb40flow200.ildg.sanity.txt
```

- `before_save` and `after_reload` sanity checks both passed.
- Representative `after_reload` diagnostics:
  - `density_global` quantiles:
    `[0.00020402076181330608, 0.0009149724579730808,
    0.001227278741586383, 0.0012995587367358736,
    0.0014507052576305858, 0.0023145462069107453,
    0.0645340172355522]`
  - `frac_eq1=0.0`
  - `frac_ge099=0.0`
- This confirms that the same-environment studio1 generation/reload path is
  sane. It also separated the visualization code from the earlier bad
  YITP/studio1 read/render attempt.
- Render from this studio1-generated config was started on `studio1`:

```text
pid: 45392
log: /Users/akio/VisualizingLQCD-yitp-local-render/logs/studio-render-20260509-190743.log
input: /Users/akio/VisualizingLQCD-yitp-local-render/outputs/Conf32323264beta6.0-gf05hb40flow200.ildg
output: /Users/akio/VisualizingLQCD-yitp-local-render/outputs/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200.mp4
camera_orbit_turns: 0.175
```

- Next step after render completion: inspect the movie/contact frames first,
  then decide whether it should replace README media.

Render result:

- The studio1 render completed in about 12 minutes for `128` frames.
- Local review copy:

```text
/private/tmp/VisualizingLQCD-32x64-studio/view.html
/private/tmp/VisualizingLQCD-32x64-studio/contact.jpg
/private/tmp/VisualizingLQCD-32x64-studio/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200.mp4
```

- The contact sheet showed no empty-grid or solid-cube failure like the earlier
  YITP artifact. The movie is visually usable as a README candidate, though the
  palette is blue/green heavy compared with the reference VisualQCD style.
- Repository README media were switched to the new generated sample:

```text
plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200.mp4
plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200.gif
test/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200.gif
```

Follow-up from visual review:

- The short `0.175`-turn orbit looks good, but because it is meant to loop, the
  README sample should contain a full camera turn at nearly the same perceived
  angular speed.
- `scripts/yitp_sample/render_large_sample.jl` now accepts optional
  `--nloops` and `--framerate`.
- `scripts/yitp_sample/studio_render_large_sample.sh` now defaults to the
  full-turn README candidate:

```text
camera_orbit_turns: 1.0
nloops: 11
framerate: 14
frames: 704
duration: about 50 seconds
output: /Users/akio/VisualizingLQCD-yitp-local-render/outputs/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.mp4
```

- Full-turn render started on `studio1`:

```text
pid: 47175
log: /Users/akio/VisualizingLQCD-yitp-local-render/logs/studio-render-20260509-200007.log
```

Full-turn result, first attempt:

- The render completed on `studio1` in about `14:37`.
- Output:

```text
/Users/akio/VisualizingLQCD-yitp-local-render/outputs/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.mp4
```

- Metadata:
  - `frames=704`
  - `framerate=14`
  - duration about `50.29` seconds
  - `orbit_turns=1.0`
  - `nloops=11`
- Local review path:

```text
/private/tmp/VisualizingLQCD-32x64-studio/view.html
/private/tmp/VisualizingLQCD-32x64-studio/contact-fullturn.jpg
```

- README media now point to the full-turn GIF/MP4:

```text
plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.mp4
plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.gif
test/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.gif
```

- Loop-boundary review:
  - The MP4 camera angle uses
    `azimuth + 2pi * orbit_turns * (frame - 1) / total_frames`, so frame 704
    is one normal angular step before the first frame, and the player loop
    completes the final step back to the initial angle.
  - The 4th-direction slice sequence still jumps periodically from `slice4=64`
    to `slice4=1`; this is expected for a slice-sequence movie and is separate
    from camera closure.
  - The first README GIF was made at `8 fps` from a `14 fps` MP4, which can
    make the loop boundary visibly uneven because the frame drop cadence does
    not divide evenly.
  - The README GIF was regenerated at `7 fps` (`352` frames, about `50.28`
    seconds, about `8.4M`) so GIF frame sampling is exactly every other MP4
    frame and the loop boundary has the same cadence as the rest of the movie.

Periodic-loop correction:

- The Euclidean fourth direction is periodic too. To avoid breaking that
  periodic slice sequence, the README source should not be made by dropping
  frames from a higher-fps render.
- New plan: render directly at the final display cadence, with the fourth
  direction looping an integer number of times while the camera completes one
  turn.
- Current periodic-loop render settings:

```text
camera_orbit_turns: 1.0
nloops: 6
framerate: 7
frames: 64 * 6 = 384
duration: about 54.9 seconds
```

- This uses all `64` Euclidean fourth-direction slices in order, six times,
  while the camera makes one full turn. The loop boundary is then
  `(slice4=64, final camera step)` -> `(slice4=1, initial camera angle)`, which
  respects both periodicities.
- Periodic-loop render started on `studio1` after preflight diagnostics passed:

```text
pid: 49384
log: /Users/akio/VisualizingLQCD-yitp-local-render/logs/studio-render-20260509-211006.log
preflight_log: /Users/akio/VisualizingLQCD-yitp-local-render/logs/studio-render-preflight-20260509-211006.log
output: /Users/akio/VisualizingLQCD-yitp-local-render/outputs/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.mp4
```

- Periodic-loop render completed on `studio1`.
- Final source MP4:
  - `384` frames
  - `7` fps
  - duration about `54.86` seconds
  - `nloops=6`
  - `camera_orbit_turns=1.0`
- The GIF was regenerated from this MP4 at the same `7` fps, without dropping
  every other frame from a higher-fps source.
- Local review artifacts:

```text
/private/tmp/VisualizingLQCD-32x64-studio/view.html
/private/tmp/VisualizingLQCD-32x64-studio/loop-boundary-periodic-frames.jpg
/private/tmp/VisualizingLQCD-32x64-studio/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.mp4
/private/tmp/VisualizingLQCD-32x64-studio/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.gif
```

Smoothness correction:

- The `384`-frame, `7` fps periodic-loop candidate preserved both periodicities,
  but the GIF looked too large and the motion felt choppy/sluggish.
- Do not change the playback speed. Instead, keep `nloops=6` and the same
  about-`54.86` second duration, but render at `14` fps with
  `slice_hold_frames=2`.
- This makes:

```text
camera_orbit_turns: 1.0
nloops: 6
framerate: 14
slice_hold_frames: 2
figure_size: 480 x 480
frames: 64 * 6 * 2 = 768
duration: about 54.9 seconds
```

- The Euclidean fourth-direction slice cadence stays the same as the `7` fps
  candidate because each slice is held for two rendered frames, while the camera
  gets twice as many angular samples.
- README display width and GIF conversion defaults were reduced to `200` px.
- Source rendering for README media should use `figure_size=(480, 480)` instead
  of the default `800 x 800`, because the final GIF is displayed at `200` px.
- A first full GLMakie `768`-frame render was tried on `studio1` at the old
  `800 x 800` source size, but the progress estimate stayed around
  `6.3 s/frame` early in the run, implying roughly `80` minutes. It was stopped
  before completion.
- A short local preview was generated instead by motion-interpolating the
  existing periodic `7` fps source to `14` fps at `240` px, keeping the playback
  speed unchanged:

```text
/private/tmp/VisualizingLQCD-32x64-studio/view-smooth-preview.html
/private/tmp/VisualizingLQCD-32x64-studio/smooth-14fps-240-preview.mp4
```

- This is only a visual check. If the interpolation looks acceptable, produce
  the full README GIF/MP4 from the existing periodic source. If interpolation
  looks physically/visually suspicious, schedule the real `768`-frame GLMakie
  render as a longer `studio1` job and keep the user informed.
- The real `768`-frame GLMakie render was then rerun on `studio1` at
  `480 x 480`. It completed:

```text
machine: studio1
workdir: /Users/akio/VisualizingLQCD-yitp-local-render
log: /Users/akio/VisualizingLQCD-yitp-local-render/logs/studio-render-20260509-221340.log
render time: 13:26
mp4 frames: 768
mp4 fps: 14
mp4 duration: 54.857143 s
mp4 size: about 12M
gif width: 200 px
gif frames: 768
gif fps: 14
gif size: about 12M
```

- Local review artifacts:

```text
/private/tmp/VisualizingLQCD-32x64-studio/view.html
/private/tmp/VisualizingLQCD-32x64-studio/contact-fullturn-real14.jpg
/private/tmp/VisualizingLQCD-32x64-studio/loop-boundary-real14.jpg
```

## Current branch state

- Current active branch for the YITP sample workflow: `codex/yitp-sample-gif`.
- `origin/main` includes PR16 (`codex/render-progress`) as of commit
  `58b80f1`.
- A local untracked root `Manifest.toml` exists. Keep it out of unrelated
  commits unless the project deliberately decides to track a manifest.

## YITP Sample GIF Workflow

Goal:

- Generate a larger sample configuration without running heavy work locally.
- Current target: `32 x 32 x 32 x 64`, `beta=6.0`, `NC=3`.
- The YITP attempt used 20 heatbath sweeps and 200 gradient-flow steps.
- The studio1 40-sweep, 200-flow configuration was generated as a conservative
  fallback while the YITP/studio1 read-path failure was unresolved. Later
  diagnostics indicate the current checksum-matched YITP file is also sane, but
  the README media in this branch use the studio1-generated
  `Conf32323264beta6.0-gf05hb40flow200.ildg`.
- Work directory on YITP:

```text
/sc/home/akio/VisualizingLQCD-yitp-sample
```

Scripts live under:

```text
scripts/yitp_sample/
```

Current YITP findings:

- Configuration generation can run on CPU queues.
- CPU queues (`S`, `DEBUG`) had idle nodes during the 2026-05-09 check.
- Production generation job `9491` completed on `S` partition.
  - Output:
    `/sc/home/akio/VisualizingLQCD-yitp-sample/outputs/Conf32323264beta6.0.ildg`
  - Size: about `1.2G`.
  - Metadata:
    `/sc/home/akio/VisualizingLQCD-yitp-sample/outputs/Conf32323264beta6.0.ildg.metadata.txt`
- CPU `DEBUG` GLMakie smoke job `9501` failed because `GLMakie`/`GLFW` requires
  `DISPLAY`.
- CPU display probe job `9507` showed that CPU compute nodes do not expose
  `Xorg`, `Xwayland`, `Xvfb`, `xvfb-run`, or `vglrun`; only `glxinfo` was
  present and it failed without `DISPLAY`.
- Front/login nodes expose `Xorg` and `vglrun`, but `Xorg` cannot be started
  from a normal SSH session (`Only console users are allowed to run the X
  server`).
- GPU GLMakie smoke job `9494` is pending.
- GPU display probe job `9509` is pending and should determine whether
  `DISPLAY=:0`, VirtualGL, or a GPU-node X server path exists.
- YITP does not expose a system `ffmpeg` command in the tested shell
  environment. GIF conversion should use `scripts/yitp_sample/convert_mp4_to_gif.jl`,
  which tries `ffmpeg` first and then `FFMPEG_jll`.
- Local-machine fallback was tested on `studio1`.
  - `studio1` has enough disk and memory for rendering.
  - `juliaup update` was run there with user permission; installed channels are
    `1.10.11`, `1.11.9`, and `1.12.6`.
  - Regular `Pkg.status()` works for `+1.10`, `+1.11`, and `+1.12`.
  - A fresh scratch workdir exists at
    `/Users/akio/VisualizingLQCD-yitp-local-render`.
  - The generated YITP configuration was copied there and byte size matched
    YITP: `1207959696` bytes.
  - `GLMakie` PNG smoke succeeded in that workdir.
  - The initial full render attempt failed before heavy rendering because the
    scratch copy still had a Julia `1.12` `Manifest.toml` while render was run
    with Julia `1.10`.
  - Fix: `scripts/yitp_sample/studio_prepare_render_env.sh` backs up a
    mismatched scratch manifest, creates a Julia `1.10` manifest in the scratch
    workdir, and uses a scratch depot plus Julia system depots. It does not
    write to the global Julia environments.
  - `scripts/yitp_sample/studio_render_large_sample.sh` then ran successfully
    on `studio1`, but that first `32^3 x 64` movie was rejected as visually
    invalid.
    - Output:
      `/Users/akio/VisualizingLQCD-yitp-local-render/outputs/plaquette_3D_contour_animation32323264beta6.0.mp4`
    - Render time: about `19:20` for `64` frames.
    - Output size: about `2.0M`.
  - Diagnosis of that invalid `32^3 x 64` render/read attempt:
    - rendered frames became empty grids or full box surfaces;
    - metadata had `body_level=1.0` and `color_range=[1.0, 1.0]`;
    - action-density diagnostics showed many slices with all values exactly
      `1.0` (`slice4=32,48,64`), so that copied input/read path was not usable
      as a visualization sample.
  - Superseding investigation:
    - the current YITP file
      `/sc/home/akio/VisualizingLQCD-yitp-sample/outputs/Conf32323264beta6.0.ildg`
      has sha256
      `9bc6165178f48b7b49d678d807eb2293fb04bc245fd8aef61e17b81164b716d0`;
    - a fresh local copy at
      `/private/tmp/Conf32323264beta6.0-yitp-9731.ildg` had the same checksum;
    - YITP `binary` and `ildg` diagnostics, plus local Gaugefields v0.5.18
      `binary` and `ildg` diagnostics, all reported `frac_eq1=0.0` and
      `frac_ge099=0.0`;
    - the old failure should therefore be treated as a stale copy, stale
      workdir, script/environment mix-up, or missing-preflight problem unless
      the original bad studio1 copy can be reproduced with a checksum.
  - The known Dropbox/local sample
    `/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg` was
    copied to `studio1` and diagnosed as sane:
    - no `frac_eq1` or `frac_ge099` contamination;
    - action-density quantiles around `1e-3`, not `1.0`.
  - The README sample movie was regenerated from that known-good `24^3 x 32`
    configuration on `studio1`.
    - Candidate output:
      `/Users/akio/VisualizingLQCD-yitp-local-render/outputs/plaquette_3D_contour_animation24242432beta6.0-candidate.mp4`
    - Render time: about `2:45` for `128` frames.
    - Metadata summary:
      `body_level=0.001001471068063763`,
      `color_range=[0.0009528263640544168, 0.002317033445038125]`.
  - The corrected MP4 was copied back to the repository root and converted
    locally to a `360px` wide GIF using the existing local `ffmpeg`.
    - `plaquette_3D_contour_animation24242432beta6.0.mp4`
    - `plaquette_3D_contour_animation24242432beta6.0.gif`
    - `test/plaquette_3D_contour_animation24242432beta6.0.gif`
  - No `studio1` render process was left running after that completed
    `24^3 x 32` README-sample render. This statement does not refer to the
    later active `32^3 x 64` corrective generation job noted at the top of this
    memo.

Useful local status command:

```bash
scripts/yitp_sample/check_remote_status.sh
```

Policy:

- Do not run heavy generation, GLMakie rendering, or GIF conversion locally.
- If local fallback is explicitly approved, use a separate scratch directory and
  isolated depot, preferably on `studio1`, and record the environment decisions
  in this memo.
- Local work on the primary laptop should stay limited to script edits, SSH
  status checks, rsync, lightweight inspection, and small media conversion.

## Older branch state notes

- `origin/main` currently contains PR1 through PR7 plus the status-memo PR.
- `codex/pr7-raw-high-levels` is merged on `origin/main`.
  - Commit: `68524da Add raw-high plaquette level target`
  - Adds an opt-in raw-high plaquette deviation target.
- `codex/pr8-plaquette-render-options` is included in the current PR10 branch
  history and may still need separate merge verification.
  - Commit: `c8f15c0 Add plaquette render diagnostics`
  - Adds raw-high color range metadata, transparency, and light/dark render
    themes.
- `codex/pr9-plaquette-thermal-preset` is included in the current PR10 branch
  history and may still need separate merge verification.
  - Adds an opt-in plaquette thermal render style.
  - Uses dark theme plus cyan/turquoise/yellow/red colors for raw-high
    plaquette deviation.
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

## Physical-vs-Visual Conflict

The main visual difficulty is now understood more clearly:

- The legacy neglog high-side surface gives a strong, smooth "blob" impression.
- Because `-log(p + epsilon)` is monotone decreasing, that surface corresponds
  to low raw plaquette deviation, not high raw plaquette deviation.
- Raw-high plaquette-deviation rendering is semantically clearer, but the high
  raw field is sparse/noisy enough that it tends to look like shells, thin
  surfaces, isolated patches, or voxel-like volume rather than smooth blobs.

The likely solution is not a purely cosmetic renderer tweak. The physical field
used for geometry should become a physically meaningful coarse-grained high-side
observable:

- Prefer local action density over a single plaquette-plane deviation when the
  goal is "field-strength/action-density blobs".
- Prefer gauge-field gradient flow before measurement when smoothing is meant
  to be physical rather than only an image filter.
- A defensible visual renderer can use a smoothed/flowed high-side action
  density as the geometry envelope and color that surface/volume by the same
  high-side observable, with all smoothing/flow/quantile choices recorded in
  metadata.
- Scalar post-smoothing or morphological envelopes can be useful diagnostics,
  but they should be documented as visualization operations, not as the
  underlying physics observable.

PR10 branch experiment:

- Branch: `codex/pr10-action-density-blob-trials`
- Temporary trial output:

```text
/private/tmp/VisualizingLQCD-action-density-pr10/view.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-envelope.html
```

- Tested `plane12` raw-high against 6-plane local action density:

```text
action_density(x) = (1/6) * sum_{mu<nu} (1 - ReTr U_mu_nu(x) / Nc)
```

- Result:
  - 6-plane local action density makes high-side structures more connected and
    blob-like than a single plaquette orientation.
  - Additional gradient flow after loading did not qualitatively change the
    t=0 shape as much as switching from `plane12` to 6-plane action density.
  - Dense RGBA volume still looks too box-like at this lattice resolution.
  - The most promising style so far is a sparse contour composition:
    cyan high-side action-density envelope plus only two hot/core contours.
  - Strong candidate diagnostic names from the temporary page:
    `env-action6-q70-hot95-core99` and `env-action6-q65-hot94-core99`.
- Interpretation:
  - This is the first trial that keeps the high-side physical meaning while
    recovering much of the legacy/reference "blob" impression.
  - It should be implemented, if adopted, as a new observable and render style
    rather than as a tweak to plaquette-plane raw-high defaults.

Reference-page/paper findings:

- Leinweber's Visual QCD / QCD Lava Lamp visualizations are action-density and
  topological-charge-density visualizations after physical smoothing, not raw
  unsmoothed single-plaquette visualizations.
- The arXiv paper `hep-lat/0004025` describes the action-density image as:
  - a 3D slice of action density after cooling,
  - one blue isosurface connecting equal action-density points,
  - tri-linear interpolation for surface smoothing,
  - volume rendering only inside the isosurface to show action-density changes,
  - no volume rendering outside the low-density region so the inside remains
    visible,
  - sharp peaks clipped for illustration.
- The same public animation description says the QCD Lava Lamp appears after
  smoothing the gluon field, specifically citing 50 APE-smearing sweeps in the
  widely mirrored/Commons description.
- Most important rendering implication:
  - Do not render q70/q95/q99 as separate opaque colored isosurfaces.
  - That directly creates the "nested peanut shell" artifact.
  - Instead, render a single action-density envelope and use masked/clipped
    volume rendering or an equivalent transfer function inside that envelope.
  - Hot colors should be a color/opacity transfer inside the object, not
    independent shell geometry.

### PR10 masked-volume test log

Record new rendering tests here before deciding what to implement in `src/`.

- Goal: reproduce the VisualQCD-style "single object with colored interior"
  while preserving high-side action-density semantics.
- Baseline to beat: `env-action6-q70-hot95-core99`, which has good action-density
  blob geometry but still reads like nested colored peanut shells.
- Temporary output directory:

```text
/private/tmp/VisualizingLQCD-action-density-pr10
```

- Test pages produced so far:

```text
/private/tmp/VisualizingLQCD-action-density-pr10/view-masked-volume.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-envelope-hot-volume.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-surface-projected-hot.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-hot-blob-overlay.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-coarse-grain-visualqcd.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-flow-sweep-visual.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-legacy-low-action.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-legacy-low-candidates.html
/private/tmp/VisualizingLQCD-action-density-pr10/view-legacy-low-candidate2-refine.html
```

- Cache files:

```text
/private/tmp/VisualizingLQCD-action-density-pr10/action_density_cache_v1.jls
/private/tmp/VisualizingLQCD-action-density-pr10/flow_sweep_slice_cache_v1.jls
/private/tmp/VisualizingLQCD-action-density-pr10/legacy_raw_plane12_cache_v1.jls
```

- Test execution status:
  - All PR10 trial scripts above ran successfully with
    `/Users/akio/.juliaup/bin/julia --project=...`.
  - Latest trial driver:
    `/private/tmp/VisualizingLQCD-action-density-pr10/legacy_low_envelope_action_trials.jl`.
  - The README sample configuration used for these visual tests is
    `/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg`.
  - `tempconf.dat` was generated by ILDG loading during flow-sweep testing and
    removed afterward from the temporary directory.
  - `legacy_low_envelope_action_trials.jl` also ran successfully with the same
    Julia project. The first run computed `legacy_raw_plane12_cache_v1.jls`;
    subsequent runs used the cache.
  - No `src/` or `test/` code changes have been made for these visual trials.

- Trial results:
  - `masked-volume`: removed explicit q95/q99 hot surfaces, but the result was
    too smoky/transparent and did not recover a solid blob impression.
  - `envelope-hot-volume`: one cyan envelope plus hot volume is conceptually
    closest to the VisualQCD description, but Makie draw order/transparency
    made hot regions appear mostly at cut/boundary faces instead of as rich
    interior color.
  - `surface-projected-hot`: a single q68/q70 action-density surface colored by
    nearby high-density values removes nested shell geometry, but current
    colors spread across the surface too much and the hand-built mesh looks
    more like a colored membrane than the reference image.
  - `hot-blob-overlay`: high-level caps still read as secondary shell surfaces,
    while peak-splat spheres are obviously artificial. Useful only as a
    diagnostic, not a final renderer.
  - `coarse-grain-visualqcd`: scalar post-smoothing makes surfaces smoother, but
    multiple hot contours still create the same nested-skin visual artifact.
    Coarse-grained RGBA volume remains visually weak behind the envelope.
  - `flow-sweep-visual`: gauge-field gradient flow at 30/60/100 steps
    physically smooths the action density, but multiple hot contours still read
    as separate transparent skins. Flow alone does not solve the renderer
    problem.
  - `legacy-low envelope + action color`: confirms the user's hint. The
    high side of the legacy `-log(p + epsilon)` display field gives a much
    stronger blob scaffold than high-side action-density geometry. However, it
    corresponds to low raw plaquette deviation, so it is a visual scaffold, not
    a high-action isosurface.
  - `ll-contour-q70-y965-r992`: readable and keeps action-density color
    thresholds, but yellow/red are still separate contour geometry and can read
    as shells.
  - `ll-mask-contour-*` and `ll-mask-volume-*`: masking action density to the
    legacy-low envelope and then recomputing thresholds is misleading, because
    thresholds drop to low action values and produce noisy color.
  - `ll-mask-fixed-*`: using global action-density thresholds after masking is
    more honest, but shows very little hot structure inside the legacy-low
    envelope. This suggests that the visually good low-side scaffold does not
    strongly overlap the true highest action-density peaks in this slice.
  - `ll-surface-up3-q70-topmean-surf88-r98`: best single-surface physical-color
    candidate so far. Geometry is the legacy-low visual scaffold; color is a
    local projected action-density statistic, with color thresholds calibrated
    on the projected surface values.
  - `ll-self-surface-up3-q70-topmean-surf94-r992`: closest to the reference
    appearance among the latest trials, but both shape and color come from the
    legacy low-side field. Treat as appearance-only diagnostic.
  - Full RGBA volume trials remain too dark/smoky in Makie for this data and
    transfer function.
  - User feedback on `view-legacy-low-candidates.html`: candidates 3, 4, 5, and
    6 are not acceptable. Keep only candidate 1 as the pure blob scaffold and
    candidate 2 as the contour-overlay line worth refining.
  - Candidate 2 refinement page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-legacy-low-candidate2-refine.html`.
    Variants tried:
    `ll-contour-q70-y965-r992-faintyellow`, `ll-contour-q70-y98-r995`,
    `ll-contour-q70-y985-r997`, `ll-redonly-q70-r992`, and
    `ll-orangeonly-q70-q985`.
  - Candidate 2 refinement result: `ll-contour-q70-y98-r995` and
    `ll-contour-q70-y965-r992-faintyellow` are slightly cleaner than the
    original contour overlay, but they do not solve the fundamental
    contour-shell look. Single-contour `redonly` and `orangeonly` variants lose
    too much of the reference-like hot-color impression.
  - Multi-step contour test after user suggested "more color stages / many
    shells": added `ll-multistep-q70-6soft`, `ll-multistep-q70-8fine`,
    `ll-multistep-q70-top6`, and `ll-multistep-q64-8fine`.
    The direction is viable. Low thresholds such as q86/q90 create too much
    colored coverage and muddy the cyan body; `ll-multistep-q70-top6` is the
    best-balanced variant so far, with `ll-multistep-q70-6soft` as a secondary
    candidate. This still has visible contour shells, but the staged color
    reads closer to a continuous hot region than the two-contour version.
  - Follow-up for blur in the multi-step direction: added
    `ll-multistep-q70-top5-crisp`, `ll-multistep-q70-top7-crisp`,
    `ll-multistep-q70-core5`, and `ll-multistep-q72-top6-crisp` to
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-legacy-low-candidate2-refine.html`.
    Current visual read: `ll-multistep-q70-top5-crisp` is the best balance of
    reduced blur and staged hot color; `ll-multistep-q70-core5` is the crispest
    but may be too sparse; `ll-multistep-q70-top7-crisp` and
    `ll-multistep-q72-top6-crisp` still look somewhat diffuse.
  - Follow-up for the hollow/back-cavity issue: tried closing the cyan scaffold
    only while keeping the action-density color contours unchanged. Binary
    mask closing (`ll-close*`) closes holes but creates severe contour
    aliasing/wire texture and should not be used. Grayscale field closing
    (`ll-gclose*`) is much better: `ll-gclose6-r1-q70-top5-crisp` is the
    conservative version, while `ll-gclose26-r1-q70-top5-crisp` closes more of
    the visible cavities at the cost of a slightly thicker/blockier envelope.
    `ll-gclose26-r2-q70-top5-crisp` is too aggressive and too box-like.
    Focused page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-legacy-low-closing-refine.html`.
  - Follow-up on grayscale closing: added matched-level variants
    `ll-gclose6-r1-q70match-top5-crisp`,
    `ll-gclose26-r1-q70match-top5-crisp`,
    `ll-gclose26-r1-q72level-top5-crisp`, and
    `ll-gclose26-r1-q68match-top5-crisp`. These recompute the contour level
    on the closed field to keep the scaffold closer to the original volume
    fraction. Current read: `ll-gclose6-r1-q70match-top5-crisp` is the
    conservative candidate; `ll-gclose26-r1-q70match-top5-crisp` closes more
    of the visible hollow regions but starts to look thicker/blockier;
    `ll-gclose26-r1-q72level-top5-crisp` is tighter but gives back too much of
    the cavity behavior.
  - User liked `Same hot contours, no emerald scaffold`. This is an important
    pivot: removing the emerald/cyan visual scaffold also removes much of the
    hollow/back-cavity problem and makes the display closer to a direct
    high-side action-density diagnostic. Added focused hot-only variants in
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-hotonly-refine.html`.
    User then selected `hotonly-top5-crisp` as visually good. Current read:
    `hotonly-top5-crisp` is the cleanest hot-only candidate and should be used
    as the baseline. `hotonly-top6-wide` is the first enlargement candidate if
    the blobs are too small; `hotonly-q93-wide` is a slightly larger but softer
    alternative; `hotonly-q91-softbody` and `hotonly-coreplusglow` start to look
    too smoky/blurred.
  - Comparison to the original user-provided VisualQCD-like screenshot:
    `hotonly-top5-crisp` matches the black background, grid, and localized
    yellow/orange/red high-density peaks. It does not match the large
    cyan/blue envelope/body in the reference image. This makes it more
    physically direct as a high-side action-density diagnostic, but less
    faithful to the full VisualQCD/Lava-Lamp look, which appears to combine a
    connected low/medium-density envelope with hot interior coloring or volume
    transfer.
  - Added follow-up hot-only crisp expansion trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-hotonly-crisp-expansion.html`.
    Temporary names A-J. Baseline A is `hotonly-top5-crisp`. B only raises
    alpha, C adds one lower hot rim, D/E/F/G use a visual-only grayscale
    expansion of the high-density field, H/I lightly smooth the field, and J is
    aggressive dilation. Current read: A remains the clean baseline. B, C, D,
    G, and I are worth user comparison. J is larger but too artificial and
    should not be the default direction.
  - User liked G (`expand6 smooth96`), H (`smooth92 lowrim`), and J
    (`dilate6 crisp`). Added color-range trials K-V:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-hotonly-color-range.html`.
    These keep the hot-only direction but vary geometry and color thresholds
    separately. K/M keep the G shape and alter the red/yellow range. N/O/P keep
    the H shape and alter smoothing/color. Q/R/S are J-like expansions with
    weaker smoothing/threshold choices. T/U are H/J hybrids. V tests a hot-white
    peak clip and looks too unlike the reference style. Current read: M is a
    useful G-style color candidate; P is a subdued H-style candidate; Q/R/T/U
    best capture the larger-blob direction; U is the most interesting first
    shortlist item because it preserves J-like blob size while reducing the
    bright-yellow rim.
  - User feedback on K-V: reject V (`hot-white core`) and S
    (`J display-levels`). Good candidates are K (`G-shape red core`), J
    (`dilate6 crisp` from the previous page), P (`H-shape amber rim`), O
    (`H-shape broad red`), and T (`H/J hybrid`). User especially likes the
    color of U (`H/J hybrid amber`). User also noted that the literature /
    original-reference style still looks better. Interpretation: the current
    hot-only contour direction is physically cleaner and avoids the previous
    emerald-shell issue, but it lacks the large connected blue/cyan body seen
    in the reference. Next trial should combine the favored shape candidates
    with U-like amber color, and separately test a very subdued physical
    action-density body under the hot contours.
  - Added W-AE shortlist/literature trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-hotonly-shortlist-literature.html`.
    W-AA combine favored shapes K/J/P/O/T with U-like amber color. AB-AE add a
    subdued blue/cyan physical action-density body under the hot contours, to
    test whether the literature/reference look needs a connected body. Current
    read: W is the clean K+U variant; X recovers J-like blob size but still has
    some artificial dilation character; Y/Z/AA are stable H/O/T-style amber
    variants. AB/AE are closer to the reference image because they reintroduce
    a large body, but the body is visually dominant and partly hides the hot
    contours. AC is too blue; AD is darker but still body-heavy. This confirms
    that the literature look likely requires a proper masked/volume-transfer
    renderer rather than simply overlaying a translucent body isosurface.
  - User asked why AB's blue body looks like a shell and suggested the body
    threshold might be mismatched. Added focused body threshold/fill trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-body-threshold-fill.html`.
    AB used a single `contour!` at body quantile 0.72, i.e. a boundary of the
    top 28% of the smoothed body field. Lowering the single body threshold to
    q60/q52 reduces some holes but makes a large blue isosurface that still
    reads as a shell, because an isosurface is only the boundary of the region
    above threshold. Multi-body contours fill visually a bit more, but still
    create nested surfaces. RGBA body-volume variants reduce the shell/cavity
    artifact, but the current Makie volume setup becomes dark/foggy and shows
    cube-like boundary behavior. Interpretation: the threshold mismatch
    contributes, but the main issue is that the body is being drawn as one or
    more isosurfaces rather than as a controlled masked volume/transfer
    function. For blob clarity, X (`J shape + U amber color`) remains stronger;
    for literature style, body volume needs renderer work.
  - User then noticed that the apparent cross-sections through blobs are odd
    away from the box boundary. Added contour-solid diagnostics:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-contour-solid-diagnostics.html`.
    Cause: the X/J direction draws several nested high-side isosurfaces
    (`q95.5`, `q97.2`, `q98.5`, `q99.3`, `q99.8`) with `alpha < 1` and
    `transparency=true`, so inner surfaces are visible through the outer
    surface. These are not physical cut planes; they are transparent nested
    contours. Real open cuts occur at the finite box boundary, but the
    mid-volume "cut" look is mostly the transparency/nested-shell artifact.
    Diagnostic variants confirm this: AO (`outer only`) removes inner shells,
    AQ (`opaque multi`) hides inner shells but loses useful red-hot internal
    readability, and AP/AR (`outer + red core only`) are a possible compromise
    with fewer visible nested shells. A more faithful solid blob needs either
    single-surface color projection or a controlled volume/transfer renderer,
    not many transparent contour surfaces.
  - User feedback after this diagnostic: AQ (`opaque multi`) is the best
    current direction. This is an important pivot: for the near-term visual
    style, prefer opaque multi-contours over transparent hot contours, because
    opacity suppresses the false internal cutaway/nested-shell look. Added AQ
    refinement page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-opaque-multi-refine.html`.
    Temporary variants A-I keep the AQ principle and vary only level spacing,
    display-field smoothing/expansion, and amber/red color range.
  - User liked I (`muted outer`), B (`AQ denser`), and G (`H/J U-amber`) from
    the AQ refinement page, but noted visible gaps between shells. Cause: even
    with `transparency=false`, the renderer still draws separate two-dimensional
    isosurfaces. No geometry exists between adjacent contour levels, so gaps
    appear unless the levels are made denser, the depth shift is reduced, or
    the style moves to a single colored surface / volume transfer renderer.
    Added gap-fill refinement page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-opaque-gap-fill.html`.
    Temporary variants J-R test denser contour levels, lower outer levels, and
    smaller/no depth shift around the liked I/B/G styles. Current local read:
    K fills gaps most aggressively but increases contour banding; M preserves
    the B style with fewer side effects; N/O are the G/H-J amber versions with
    denser levels.
  - User suggested overlapping the bands. This is right in spirit, but
    `contour!` cannot draw the interval volume `q_i < field < q_j`; it only
    draws surfaces where `field == level`. Added overlap/interval-fill trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-overlap-band-trials.html`.
    Temporary variants S-X test two approximations:
    dense level spacing (S/W) and an underpainted low-level surface plus
    overdrawn high-level caps (T/V). Variant X is a true RGBA interval-volume
    fill for comparison, but it remains too blurry/smoky. Current local read:
    T and V are closest to the user's overlap idea, but they should be
    documented as visual underpaint/projection styles rather than literal
    physical isosurfaces.
  - User selected U (`I underpaint depth-tested`), W (`R smooth92 overdense`),
    and S (`I overdense`) as the good candidates from the overlap page. Added
    a focused shortlist page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-overlap-shortlist.html`.
    Current interpretation: U is the best near-term "filled look" candidate,
    because it uses a low-level opaque underpaint surface and depth-tested hot
    caps. W is the most physically conservative-looking smooth action-density
    dense-contour candidate. S preserves the I/muted outer direction with dense
    levels and no transparency. If implementing one style first, start with U
    as an opt-in diagnostic render style, then keep W/S as parameter variants
    or test presets.
  - Added movies for the U/W/S shortlist:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-overlap-shortlist-movies.html`.
    Individual videos:
    `/private/tmp/VisualizingLQCD-action-density-pr10/movie-u-underpaint-depth.mp4`,
    `/private/tmp/VisualizingLQCD-action-density-pr10/movie-w-smooth92-overdense.mp4`,
    and `/private/tmp/VisualizingLQCD-action-density-pr10/movie-s-i-overdense.mp4`.
    GLMakie `record(...)` segfaulted in GLFW monitor detection on this machine,
    so the movies were generated by saving 32 PNG frames per candidate and
    assembling them with ffmpeg at 8 fps. Thresholds are global quantiles across
    all 32 Euclidean fourth-direction slices, not per-frame thresholds.
  - User noticed that all three U/W/S movies have a large hole around
    slice4=31. This is not W-specific. It is a common consequence of drawing
    superlevel-set surfaces: at slice4=31 the selected high-density body has a
    tunnel/open channel connected to the outside. A true internal-hole fill does
    not change the q87 mask (`2079 -> 2079` voxels), confirming that this is
    not a closed internal cavity. Focused W diagnostics:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-hole-fill.html`.
    For W at slice4=31, lowering the base/underpaint threshold to q82 or q78
    reduces the hole most cleanly. Binary closing can bridge holes but produces
    severe mesh/stripe artifacts, and RGBA volume fill is again too blurry.
    Current implication: if keeping the W direction, use a lower underpaint
    surface (around global q78-q82) plus hot caps, with metadata clearly
    recording that the underpaint is a visual body threshold rather than the
    same level as the hot contours.
  - Follow-up after the user clarified that the suspicious feature is not the
    black background void but a hole-looking region inside the red/high-density
    blob near `x≈0.5 fm, y≈0 fm, z≈1.5 fm` at `slice4=31`. Screen/data
    cross-check outputs:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-red-region-target.html`
    and
    `/private/tmp/VisualizingLQCD-action-density-pr10/w_slice31_red_region_target_report.md`.
    With `a=0.08941478992524238 fm`, this maps to approximately
    `(ix,iy,iz,it)=(6,1,17,31)`. The raw action density there is
    `0.002393677474588759`, the `smooth92` action density is
    `0.002377882216105838`, and the global `smooth92` rank is about `0.99918`,
    i.e. above the W q0.999 level. Nearby sites such as `(7,2,17,31)` are even
    higher. Therefore this red-region "hole" is not a low-action-density hole
    in the configuration data. It is a rendering artifact caused by drawing
    isosurfaces only, with the high-density object intersecting the front
    `y≈0` boundary and exposing an open/cut surface.
  - Follow-up after the user marked the actual suspicious areas in lime green:
    `/Users/akio/Dropbox/w_slice31_red_region_target_focus copy.png`.
    The initial lattice-site projection was not sufficient, because the
    circles mark `contour!` isosurface patches, not lattice-site centers. A
    second diagnostic interpolated contour-surface edge crossings for the W
    q-levels and projected those surface points with the same Makie camera.
    Outputs:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-green-circle-surface-match.html`,
    `/private/tmp/VisualizingLQCD-action-density-pr10/w_slice31_green_circle_surface_match_report.md`,
    and
    `/private/tmp/VisualizingLQCD-action-density-pr10/w_slice31_green_circle_surface_overlay.png`.
    Result: the green-circled features are real rendered isosurface caps/bands,
    but they are not empty holes in the scalar field. For example, the large
    lower red patch `G5` matches many contour-surface crossings from q0.87
    through q0.996, with nearest projected points on the q0.996 surface near
    `(x,y,z)≈(1.16,1.08,1.70) fm`. No q0.999 surface point was detected inside
    the marked green regions. The hollow/ring impression is therefore a direct
    artifact of drawing multiple thin isosurfaces/level bands rather than a
    filled superlevel volume or a capped solid surface.
  - Follow-up fill strategy trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-fill-strategy-trials.html`.
    Tested two ways to make the high-side region look filled:
    1. solid superlevel voxel-boundary meshes (`B-D`), and
    2. single smooth surface-nets style meshes with color projected from local
       action-density statistics (`E-J`).
    The solid voxel meshes genuinely cap/fill the superlevel set, but the
    appearance is too blocky at this resolution even after 3x interpolation.
    The single smooth surface variants are the more promising direction because
    they remove the nested contour/ring artifact while preserving a smooth blob
    look. `E`/`F` keep the surface tighter (`q82`/`q78`), while `G`/`I`
    (`q74`) and `H`/`J` (`q70`) fill more of the visible openings. Tradeoff:
    lowering the base surface closes more holes but moves the displayed
    geometry toward a lower-action visual envelope; this must be recorded in
    metadata if adopted.
  - User feedback on the fill strategy page: `B solid q87 topmean`,
    `C solid q82 topmean`, and `D solid q78 max muted` are interesting because
    they look genuinely filled, but the voxel-boundary surfaces are too
    blocky. `A baseline W contours` still has the best smooth surface quality.
    `E smooth surface q82 topmean` and related single-surface variants are not
    acceptable as-is because they read as surface-only rather than filled
    blobs.
  - Follow-up smooth-solid trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-smooth-solid-trials.html`.
    Variants `K-O` rebuild the B/C/D-style solid masks as shared-vertex meshes
    and apply Taubin smoothing. Result: this reduces small roughness but does
    not solve the visible slab/stairstep artifacts, especially where the
    filled region touches the finite box boundary or has large flat mask faces.
    Smoothing a voxel boundary after extraction is not enough.
  - Follow-up occupancy-blur trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-occupancy-blur-trials.html`.
    Variants `P-T` first threshold the high-side action-density field into a
    B/C/D-like occupancy mask, then smooth the occupancy field and extract a
    single opaque boundary surface from that smoothed occupancy. Color is still
    sampled from the original action-density field, not from the blurred
    occupancy. This keeps the "filled solid" impression while making the
    boundary much smoother than the voxel meshes, but user feedback rejected
    all variants on this page. Do not continue this direction unless
    explicitly revived.
  - User instead preferred the previous smooth-solid direction:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-smooth-solid-trials.html`.
    The target is now: keep the B/C/D-style filled object, but make the visible
    corners a little rounder. Added rounder solid trials:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-rounder-solid-trials.html`.
    Variants `AA-AD` keep the filled solid mesh but use 4x interpolation,
    stronger unpinned Taubin smoothing, and q82/q78 body thresholds. These are
    the current main comparison set. Variants `AE-AH` tried a smooth isosurface
    with explicit box-boundary caps, but the cap planes become visually
    dominant and are not as promising as `AA-AD`.
    User feedback: `AA-AD` are quite good. Added a focused refinement page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-rounder-solid-refine.html`.
    Variants `AI-AP` only vary threshold, smoothing strength, and color
    statistic around `AA-AD`. Current local read: `AI` is a good q82 midpoint,
    `AK` gives a slightly fuller q80 body, `AL` is tighter, and `AM/AO` are
    useful muted local-max color variants.
    User selected `AK q80 round42 topmean`, `AL q84 round42 tight`,
    `AJ q82 round70 soft`, and `AI q82 round42 topmean`, with `AL` the current
    favorite. Added 32-slice movie page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-rounder-solid-movies.html`.
    Individual movies:
    `/private/tmp/VisualizingLQCD-action-density-pr10/movie-rounder-ai-q82.mp4`,
    `/private/tmp/VisualizingLQCD-action-density-pr10/movie-rounder-aj-q82-soft.mp4`,
    `/private/tmp/VisualizingLQCD-action-density-pr10/movie-rounder-ak-q80.mp4`,
    and
    `/private/tmp/VisualizingLQCD-action-density-pr10/movie-rounder-al-q84-tight.mp4`.
  - Color-scheme work began after shape was narrowed to AL. First fixed-AL
    color range page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-rounder-color-trials.html`.
    User requested a more thermography-like color scheme, especially yellow /
    thermal-camera style. Added thermography palette page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-rounder-thermo-color-trials.html`.
    User selected `DE classic thermogram` as good. Added DE-only refinement:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-w-classic-thermo-refine.html`.
    User then selected `EB DE wider q80-999` as the current color/range
    candidate, even though it spreads more blue-green than the original local
    read preferred. Added a 32-slice movie page:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-eb-de-wider-q80-999-movie.html`.
    Movie file:
    `/private/tmp/VisualizingLQCD-action-density-pr10/movie-eb-de-wider-q80-999.mp4`.
    The visual reference source is the VisualQCD/Nobel QCD Lava Lamp page:
    `http://www.physics.adelaide.edu.au/theory/staff/leinweber/VisualQCD/Nobel/`.
    Added a side-by-side comparison page with the user-provided screenshot and
    EB slice 31:
    `/private/tmp/VisualizingLQCD-action-density-pr10/view-eb-reference-comparison.html`.

- Current interpretation:
  - Transparent multiple hot isosurfaces should not be the final
    VisualQCD-like style. They are good diagnostics, but they directly create
    the shell artifact.
  - Opaque multi-contours were a useful short-term candidate, but their gaps
    and ring/cap artifacts are still intrinsic to separate isosurfaces.
  - Checkpoint decision, as of the EB movie/refererence comparison: the current
    visual candidate is a filled superlevel solid mesh built from the high-side
    local action-density field. The selected shape candidate is `AL q84
    round42 tight`; the selected color/range candidate is `EB DE wider
    q80-999`.
  - Current candidate parameters to preserve for the next implementation pass:
    6-plane local action density, one `periodic_smooth` pass with
    `weight=0.92`, body threshold q84 over the globally smoothed field, 4x
    clamped trilinear interpolation, one `clamped_smooth` pass with
    `weight=0.88`, shared-vertex filled solid boundary extraction, Taubin
    smoothing with `iterations=42`, `lambda=0.38`, `mu=-0.40`, unpinned
    boundaries, and color from local topmean sampling with radius 7 and
    top-fraction 0.14. Palette is `DE classic thermogram`; color range is q80
    to q99.9 of the globally smoothed action-density field.
  - This is still a visualization style choice and must record interpolation,
    smoothing, threshold, and color-range parameters in metadata.
  - The small-side/legacy-low hint is useful for appearance, but it creates a
    semantics split. Do not use it for the selected candidate unless it is
    explicitly revived as a labeled visual scaffold or projected-color
    diagnostic.
  - Comparison to the VisualQCD/Nobel reference: EB matches the black
    background, lattice box, smooth blob direction, and thermal hot-core
    language better than previous trials. Remaining mismatch: the reference
    body is more consistently cyan/turquoise, reserves yellow/red for hot
    cores, and appears to combine an isosurface with volume-rendered density
    inside the surface. EB is currently an opaque surface-colored filled solid,
    so interior density is approximated by surface-projected local statistics.
  - The next defensible implementation path is:
    1. add local 6-plane action density as a first-class observable,
    2. add the selected filled-solid high-side render style as an opt-in style
       first, not as a silent replacement for existing behavior,
    3. store Euclidean slice, observable, smoothing, interpolation, threshold,
       mesh-smoothing, palette, and color-range metadata,
    4. only after this is stable, consider a more faithful masked volume
       transfer renderer to close the remaining gap to the VisualQCD/Nobel
       reference.
  - Implementation follow-up on the same PR10 branch:
    `CURRENT_LEVEL_TARGET` was changed to `:action_density_high` and
    `CURRENT_RENDER_STYLE` to `:action_density_blob`. The legacy
    `-log(p + 1e-7)` plaquette iso-surface path is still available through
    `level_target=LEVEL_TARGET_LEGACY_NEGLOG_HIGH` and
    `render_style=RENDER_STYLE_CURRENT`. The README sample GIF/MP4 were
    regenerated from the new default renderer using
    `/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg`.
  - After PR10 merge, the README sample GIF/MP4 were regenerated again from
    the Dropbox sample URL file
    `https://www.dropbox.com/scl/fi/ujkmaeszcm33gku7kl67v/Conf24242432beta6.0.ildg?rlkey=4fyzg3krxsy7azlcjgl68nvsm&dl=1`.
    The GIF now uses an 800px palette-based ffmpeg conversion and the README
    preview width was increased to 600px.

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

Additional PR9 visual experiments after the reference screenshot:

- Multi-contour bulk/hot overlays were tested locally. They tended to expose
  internal hot shells as orange/red stripes and did not solve the hollow-looking
  blob issue.
- Plain scalar volume rendering was tested. Simple `:mip`, `:absorption`, and
  `:iso` variants were either box-like or lacked surface hot spots.
- The best experimental direction so far is explicit RGBA transfer-function
  volume rendering with a small display-only smoothing pass:
  - cyan/turquoise base opacity from a lower raw plaquette-deviation quantile,
  - yellow/red opacity for high quantiles,
  - black background and gray grid.
- User feedback: the RGBA direction is promising but the smoothed volume
  variants are too blurry.
- Follow-up sharp trials showed:
  - sharper alpha ramps and no/very-light smoothing reduce blur but expose
    voxel/block artifacts,
  - a contour+RGBA hybrid gives crisp cyan surfaces but currently loses most
    interior yellow/red hot spots, so it is not yet a clear replacement.
- Additional colored-surface trials:
  - thresholded voxel-surface meshes can put yellow/red directly on the surface
    but look too blocky at the current 24^3 resolution,
  - contour-surface plus hot `meshscatter!` patches puts high-value markers on
    the visible surface, but the spherical markers look more like annotations
    than painted surface color.
  - The least-bad hot-patch variant was `patch-q76-small`; `overdraw=true` was
    too visually busy.
- Additional rejected/weak variants:
  - upsampled multi-level contours reduce blockiness but introduce dense contour
    striping/moire patterns,
  - upsampled contour hybrids preserve the cyan shell but still show hot
    regions as internal orange shells,
  - hot-only volume overlays are smoother than markers, but the hot volume is
    largely hidden by the opaque cyan contour and tends to appear only at
    boundaries, holes, or box-edge cut surfaces,
  - additive hot volume is too flat/yellow and not a useful replacement.
- Colored single-surface mesh trial:
  - A temporary surface-nets style mesh extractor was tested to create one
    surface and color vertices from the field, avoiding stacked shell layers.
  - This removes the conceptual shell problem better than multi-contour and
    volume overlays.
  - Direct surface sampling gives a mostly cyan surface with very weak hot
    spots.
  - Near-neighbor max/top-mean coloring brings back hot regions but can produce
    noisy/star-like patches; this needs a better color-sampling rule, likely
    normal-direction or narrow-band sampling rather than a naive 3D
    neighborhood max.
- Follow-up comparison against the user-provided reference screenshot showed
  that the colored single-surface direction is perceptually wrong: it reads as
  a thin membrane/sheet, while the reference reads as smooth, shaded, bulky
  iso-surface objects with hot nested/cut regions.
- Dense RGBA volume trials were tested to move away from thin membranes:
  - the volume transfer-function approach produced thickness and red/yellow
    regions in one layer,
  - but high opacity made the render look cubical/voxel-like rather than like
    the smooth reference blobs.
- A more important comparison was made with the repository's original GIF:
  - the old `-log(p + 1e-7)` geometry is much closer to the reference screenshot
    in shape and smoothness than raw-high volume trials,
  - this supports the earlier semantic finding that the visually attractive
    legacy surface is probably not a high raw plaquette-deviation surface,
  - future visual decisions must separate "reference-like appearance" from
    "high raw plaquette deviation" semantics instead of treating them as the
    same target.
- Temporary outputs for these latest checks are:

```text
/private/tmp/VisualizingLQCD-volume-pr10/view.html
/private/tmp/VisualizingLQCD-volume-pr10/reference-volume-t0-comparison.png
/private/tmp/VisualizingLQCD-volume-pr10/view-legacy-thermal.html
/private/tmp/VisualizingLQCD-volume-pr10/legacy-thermal-contour-t0-comparison.png
```
- Temporary outputs for this RGBA trial are:

```text
/private/tmp/VisualizingLQCD-rgba-pr9/view.html
/private/tmp/VisualizingLQCD-rgba-pr9/rgba-smooth-t0-comparison.png
/private/tmp/VisualizingLQCD-rgba-pr9/view-sharp.html
/private/tmp/VisualizingLQCD-rgba-pr9/sharp-t0-comparison.png
/private/tmp/VisualizingLQCD-rgba-pr9/view-surface-color.html
/private/tmp/VisualizingLQCD-rgba-pr9/view-hot-patch.html
/private/tmp/VisualizingLQCD-rgba-pr9/view-upsampled-contour.html
/private/tmp/VisualizingLQCD-rgba-pr9/view-hot-volume-overlay.html
/private/tmp/VisualizingLQCD-rgba-pr9/view-colored-single-surface.html
```

This RGBA direction changes the renderer more than the current PR9 contour
preset, so it should be a separate follow-up PR if adopted. The current repo
also has uncommitted local overlay-renderer experiments that should not be
committed unless deliberately revived.

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

## 2026-05-08 Rotation Animation Option

Context:

- The repository already had a tracked rotated movie,
  `plaquette_3D_contour_animation24242432beta6.0rot.mp4`.
- Search through the current `src/` and the initial `visualization.jl` commit
  did not find the old rotation-generation code. The retained artifact appears
  to be the rendered movie, not the code path that produced it.

Current PR direction:

- Add an opt-in camera motion keyword to `create_animation`.
- Keep the default camera static so existing calls remain stable.
- Use `camera_motion=VisualizingLQCD.CAMERA_MOTION_ORBIT` and
  `camera_orbit_turns=1` for one full camera orbit.
- Match the old rotated sample timing by default: `640` frames at `14` fps,
  about `45.7` seconds per full turn.
- Orbit movies default to `FRAME_MODE_FIXED`, meaning one fourth-direction slice
  is held fixed while the camera rotates. This separates camera motion from
  fourth-direction slice animation, which looked too violent in early smoke
  tests.
- Static movies keep the existing default framerate; orbit movies default to
  `14` fps unless the caller passes `framerate`.
- Axis limits are fixed to the full spatial lattice volume during rendering so
  the camera orbit does not look like zooming in and out as mesh geometry
  changes.
- Orbit movies use `viewmode=:fit` instead of Makie's default `:fitzoom`.
  `:fitzoom` rescales the projected axis cuboid as azimuth changes, which made
  the movie look like it was moving closer and farther away.
- Orbit movies use `perspectiveness=0.0` by default, leaving the old mesh
  perspective default for static renders.
- Record camera settings and frame selection in the metadata sidecar.

Validation:

- Full test run in `/private/tmp/VisualizingLQCD-rotation-test` passed:
  `VisualizingLQCD.jl | 44 pass`.
- Initial too-fast smoke output was
  `/private/tmp/VisualizingLQCD-rotation-test/orbit-smoke.mp4`; it used only
  `16` frames and is intentionally superseded by the slower orbit timing.
- Speed-check preview using the same angular speed as the reference, but only
  `0.175` turns:
  `/private/tmp/VisualizingLQCD-rotation-test/orbit-slow-speed-preview.mp4`.
- Fixed-slice smoke preview:
  `/private/tmp/VisualizingLQCD-rotation-test/orbit-fixed-slice-preview.mp4`.
- 24^3 sample fixed-slice31 preview:
  `/private/tmp/VisualizingLQCD-rotation-test/orbit-fixed-slice31-24cube-preview.mp4`.
- After switching orbit camera to `viewmode=:fit` and `perspectiveness=0.0`,
  the fixed-slice31 preview is:
  `/private/tmp/VisualizingLQCD-rotation-test/orbit-fixed-slice31-fit-ortho-preview.mp4`.
- Combined fourth-direction sequence plus constant-scale orbit preview:
  `/private/tmp/VisualizingLQCD-rotation-test/orbit-sequence-fit-ortho-preview.mp4`.

## 2026-05-08 Performance Improvement Plan

Next PR target: cache action-density blob mesh geometry by fourth-direction
slice.

Motivation:

- The accepted movie style is fourth-direction slice sequence plus constant
  scale orbit.
- For `NT=32` and a full old-style orbit, the movie can have around `640`
  frames, but only `32` unique fourth-direction slices.
- The current renderer rebuilds the action-density blob mesh every frame, so
  repeated loops redo the same expensive upsampling, smoothing, mesh extraction,
  coloring, and Taubin smoothing work.

Planned small PR:

- Split action-density blob geometry creation from `mesh!` plotting.
- Add a per-animation in-memory cache keyed by `slice4`.
- Use the cache only for mesh renderers and only when enabled.
- Keep visual output unchanged: cached meshes should be the same geometry and
  colors as the uncached per-frame build.
- Record cache settings in metadata.

Expected impact:

- For a full orbit sequence with `NT=32`, mesh builds should drop from about
  `640` to `32`.
- Fixed-slice orbit is already cheap because the mesh is drawn once and only the
  camera changes.

Validation:

- Full test run in `/private/tmp/VisualizingLQCD-rotation-test` passed:
  `VisualizingLQCD.jl | 51 pass`.
- Cache smoke output:
  `/private/tmp/VisualizingLQCD-rotation-test/orbit-sequence-cache-smoke.mp4`.
- Cache smoke metadata confirmed `32` frames with `nloops=2`, `NT=16`, and
  `cached_slice_count=16`.

## 2026-05-09 README Orbit Sample Update

Goal: replace the README sample movie with the accepted fourth-direction
sequence plus constant-scale orbit style.

Generation settings:

- Configuration:
  `/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg`.
- Lattice: `24x24x24x32`, `beta=6.0`, `NC=3`.
- `camera_motion=VisualizingLQCD.CAMERA_MOTION_ORBIT`.
- `frame_mode=VisualizingLQCD.FRAME_MODE_SEQUENCE`.
- `camera_orbit_turns=0.175`.
- Output: `128` frames, `14` fps, about `9.14` seconds.
- Metadata confirmed `cache_render_slices=true` and `cached_slice_count=32`.

Tracked assets:

- `plaquette_3D_contour_animation24242432beta6.0.mp4` compressed to `800x800`.
- `plaquette_3D_contour_animation24242432beta6.0.gif` generated at `420x420`,
  `10` fps.
- `test/plaquette_3D_contour_animation24242432beta6.0.gif` mirrors the root GIF.

Follow-up:

- Add frame-level render progress reporting. The long GLMakie `record` phase is
  currently silent, even though `t_end` is known.

## 2026-05-09 Render Progress PR

Goal: make long GLMakie movie writes visibly advance while keeping the rendered
movie unchanged.

Small change:

- Add `show_render_progress=true` to `create_animation`.
- Use `ProgressMeter.Progress` around the `GLMakie.record` frame loop and call
  `next!` once per rendered frame.
- Allow quiet runs with `show_render_progress=false`.
- Record the progress setting in the metadata sidecar.

Validation:

- `git diff --check` passed.
- Direct package load and progress metadata assertions passed.
- Full direct test run in `/private/tmp/VisualizingLQCD-render-progress-test`
  passed: `VisualizingLQCD.jl | 56 pass`.
- The direct test run showed `Rendering frames...` progress during the
  GLMakie record phase.

## 2026-05-09 YITP Large Sample Generation

Goal: create a larger README/sample GIF source configuration with a wider
spatial volume and doubled Euclidean fourth direction compared with the current
`24^3 x 32` sample.

Target:

- Lattice: `32 x 32 x 32 x 64`.
- `beta=6.0`, `NC=3`.
- Heatbath sweeps: `20`.
- Gradient-flow steps: `200`.
- Output configuration on YITP:
  `/sc/home/akio/VisualizingLQCD-yitp-sample/outputs/Conf32323264beta6.0.ildg`.

Execution notes:

- YITP front can load Julia `1.12.4`, but the existing Gaugefields environment
  is Julia `1.11` based. Use
  `/home/soryushi/akio/julia-1.11.2/bin/julia` with
  `/home/soryushi/akio/.julia/environments/v1.11` for configuration
  generation.
- Do not run the heavy configuration generation or rendering locally. Keep the
  long work on YITP; local work should be limited to script edits, SSH
  monitoring, and final artifact inspection.
- YITP front cannot currently fetch packages from `pkg.julialang.org`. Package
  installation should be done on the YITP login gate alias `yitp-mercury`
  (`venus1`/`venus2`), using the shared project under `/sc/home/akio`.
- `GLMakie`/`Makie` can be installed from `yitp-mercury`, but front/login nodes
  have no `DISPLAY`, so `GLMakie` precompile fails there with
  `X11: The DISPLAY environment variable is missing`.
- Rendering on YITP therefore needs a GPU/graphics-capable batch job or another
  headless rendering strategy; do not fall back to local rendering without an
  explicit decision.
- DEBUG smoke job `9490` succeeded for a `4^4` configuration.
- Production SLURM job `9491` was submitted to partition `S` from
  `/sc/home/akio/VisualizingLQCD-yitp-sample` and started on `scn35`.
- GPU GLMakie smoke job `9494` was submitted to partition `GPU` to check
  whether rendering can run on YITP without using the local machine.

## 2026-05-10 SU(2) Scalar-Instanton Fixture PR

Goal: build a deterministic calibration target for signed topological-density
rendering before the Gaugefields.jl-side SU(3) embedded instanton solution is
available.

Scope:

- This is a scalar-density fixture, not a lattice gauge-field solution.
- The fixture samples the continuum SU(2) instanton topological density on a
  periodic four-dimensional lattice and optionally normalizes each lump to its
  requested integer charge.
- The smoke renderer now has a small default case set and a `--case-set debug`
  mode with radius, off-center, spatial-boundary, same-sign DIGA, plus/minus
  DIGA, and three-lump checks.
- The smoke renderer accepts `--level-quantiles`, `--color-quantile`, and
  `--alpha` so level/color tuning can be compared without changing package
  defaults.

Validation:

- Unit tests confirm charge normalization, sign handling, radius ordering,
  off-center support, boundary peak placement, and multi-lump net charge.
- `julia --project=. test/runtests.jl` passed.
- `julia --project=. -e 'using Pkg; Pkg.test()'` passed.
- `diagnose_su2_instanton_fixtures.jl` passed and reports normalized
  one-lump charges and DIGA-like net charges.
- Debug visual smoke output was generated at
  `/private/tmp/VisualizingLQCD-su2-instanton-fixtures-debug/view.html`.

Follow-up:

- Use these scalar fixtures to tune signed topological-density defaults.
- Later compare against a true SU(2)/SU(3) gauge-field instanton once that is
  available from Gaugefields.jl work.

## 2026-05-10 Topological-Density Style Preset PR

Goal: prepare topological charge-density visual tuning without changing the
current default movie behavior abruptly.

Small change:

- Add named style presets for signed topological-density contours:
  `balanced`, `wide`, and `core`.
- Keep `balanced` equal to the current package defaults.
- Use `wide` as the smoke-script default because it exposes more of the
  scalar-instanton fixture body for visual review.
- Let callers override levels, color quantile, and alpha exactly as before.

Validation:

- Unit tests check that `balanced` preserves the old constants and that
  `wide`/`core` select distinct level/alpha settings.
- `julia --project=. test/runtests.jl` passed.
- SU(2) instanton smoke stills were generated with each preset:
  `/private/tmp/VisualizingLQCD-topology-style-balanced/view.html`,
  `/private/tmp/VisualizingLQCD-topology-style-wide/view.html`, and
  `/private/tmp/VisualizingLQCD-topology-style-core/view.html`.

Correction after visual review:

- The first preset smoke pages did not show single-sign scalar fixtures.
- Cause: topological signed contours were drawn in one GLMakie `contour!` call
  with a symmetric color range. This made one-sign contour groups effectively
  invisible even though the selected levels intersected the rendered slice.
- Fix: split signed topological contours into negative and positive contour
  groups. Negative levels use the negative colormap, positive levels use the
  positive colormap, and both keep the same signed level selection.
- Also raise the balanced/default topological color quantile from `0.995` to
  `0.999`; the old value can make single-sign fixture contours disappear.
