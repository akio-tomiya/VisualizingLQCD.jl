# Visualization refactor status

This memo tracks the VisualizingLQCD.jl visualization refactor outside the
`docs/codex/visualization_refactor_v7/` reference directory. Do not edit the v7
reference materials for status updates.

Last updated during the PR10 action-density blob trials.

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
