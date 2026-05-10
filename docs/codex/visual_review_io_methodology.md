# Visual Review IO Methodology

This memo records a reusable pattern for visual review pages. The goal is to
reduce friction when a human must judge rendered images, movies, or UI states
that cannot be evaluated reliably by unit tests alone.

## Problem

Visual review often fails for mundane IO reasons:

- results are split across many pages or directories;
- each image has to be matched back to a case name by hand;
- review notes are written in free-form chat text, so important labels are lost;
- the reviewer has to copy paths, filenames, and comments manually;
- context is lost after thread compaction or a browser refresh.

For visualization work, those small frictions matter. They make it harder to
notice which cases are blank, which cases are physically correct but visually
awkward, and which cases are good enough to keep.

## Pattern

Generate one self-contained review page that contains:

1. all visual candidates in one page;
2. a stable label for every visual item;
3. review controls next to the visual item;
4. a short free-text note field next to the controls;
5. a live copyable summary textarea at the bottom of the page;
6. local browser persistence for the current review state.

This turns review from "look, remember, and retype" into "look, click, copy".

## Recommended Page Structure

- Use a card/grid layout, one card per visual item.
- Put the image or video first, with controls immediately next to it.
- Keep detailed metadata collapsed in a `details` block.
- Keep a fixed or clearly visible output panel with a textarea at the bottom.
- Use relative asset paths so the entire directory can be moved if needed.
- Include the `file://` or source path in the generated review text.

## Stable Labels

Every card should have a stable review label, for example:

```text
balanced / single-plus-small-rho
wide / diga-plus-minus
core / single-plus-spatial-boundary
```

Good labels should include enough information to identify:

- the preset or method;
- the fixture, input, or parameter set;
- the observable or renderer when several are mixed;
- the frame/slice if the review item is time/slice dependent.

Do not rely on visual ordering alone.

## Checkbox Vocabulary

Start with a small vocabulary. For visualization diagnostics, these are useful:

```text
visible
not visible
good
shell/hollow
needs work
```

Add domain-specific labels only when they support a concrete decision. Examples:

```text
wrong sign
too diffuse
too sparse
bad color range
boundary artifact
physically suspicious
```

Avoid making the checkbox list too long. Use the note field for rare cases.

## Generated Text

The textarea should produce copyable plain text or Markdown. A useful format is:

```text
# VisualizingLQCD visual check

source: file:///private/tmp/example-review/view.html
updated: 2026-05-10T12:34:56.000Z

- balanced / single-plus-centered: visible, good
- wide / single-plus-spatial-boundary: visible, shell/hollow | note: BC looks correct, but the cut surface reads as a shell.
- core / single-plus-small-rho: not visible, needs work
```

Only include rows with at least one checkbox or note, so the pasted result stays
small.

## Persistence

Use `localStorage` to survive refreshes during a local review session. The key
should include both `location.pathname` and a generated review-session id
embedded in the HTML. Do not key only on `location.pathname`: if the page is
regenerated at the same path, stale checkboxes from the previous run will come
back.

Also provide a visible `Clear checks` button. It is cheap, and it prevents a
stale local review from becoming a confusing hidden state.

Do not treat browser storage as archival. The durable record is the copied
textarea pasted into a PR, issue, Codex thread, or status memo.

## Implementation Notes

- Escape labels and descriptions before writing HTML.
- Use relative paths from the review HTML to assets.
- Make single-preset and multi-preset paths share the same page writer where
  possible.
- Keep the generated page static: plain HTML, CSS, and JavaScript.
- Avoid network dependencies, frameworks, or external CDN assets.
- Keep metadata available, but collapsed by default.
- Keep command-line overrides visible in the page metadata.

## Validation Checklist

Before asking for human review:

- the page is generated successfully;
- expected image/video files exist;
- the HTML references every expected asset;
- the number of review cards matches the expected number of visual items;
- the checkbox count matches `cards * labels_per_card`;
- the textarea and copy button are present;
- the clear button is present;
- regenerating the same path creates a new review-session id;
- the old single-case or single-preset rendering path still works;
- unit tests still pass if code paths changed.

For VisualizingLQCD smoke reviews, a quick local validation can include:

```text
render combined review page
count PNG/MP4 assets
count data-review-card entries
check missing asset references
run test/runtests.jl
run Pkg.test()
run git diff --check
```

## When To Use

Use this pattern whenever:

- the correctness criterion is visual or qualitative;
- several rendering styles or parameter sets must be compared;
- user feedback needs to be pasted back into an issue, PR, or Codex thread;
- context compaction may happen before the review loop is complete;
- a reviewer should not need to remember filenames or paths.

It is especially useful for visualization refactors, renderer tuning, generated
sample media, screenshot comparisons, and smoke outputs from remote machines.

## Current VisualizingLQCD Example

The first implementation is in:

```text
scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl
```

Example command:

```sh
/Users/akio/.juliaup/bin/julia --project=. scripts/topology_fixtures/render_su2_instanton_fixture_smoke.jl --case-set debug --style-preset all --no-movie --output-dir /private/tmp/VisualizingLQCD-topology-style-review
```

Example review page:

```text
file:///private/tmp/VisualizingLQCD-topology-style-review/view.html
```
