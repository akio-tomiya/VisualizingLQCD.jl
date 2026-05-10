# AGENTS.md

## Project goal

This repository is VisualizingLQCD.jl. The current task is to refactor the visualization pipeline while preserving the current behavior as much as possible.

Read these design notes first:

- docs/codex/visualization_refactor_v7/main.tex
- docs/codex/visualization_refactor_v7/patch_notes/*.md
- docs/codex/visualization_refactor_v7/code_skeleton/src/*.jl

## Important constraints

- Do not treat the Euclidean temporal direction as real time.
- Remove yoctosecond and real-time-like display from the default rendered movie.
- Keep frame-to-fourth-direction-slice correspondence in metadata.
- Do not remove the current `-log(p + 1e-7)` transform. It is needed in practice for stable threshold selection.
- Preserve current magic numbers as reference defaults before changing behavior.
- Prefer small, reviewable changes.
- Keep I/O, observables, transforms, level selection, rendering, metadata, and configuration generation separated.
- Do not rewrite the whole package in one pass.

## Generated artifacts and visual review outputs

- Do not keep expensive or user-review-critical render artifacts only under
  `/private/tmp`. This includes sample movies, GIFs, review HTML pages,
  thumbnails, and metadata sidecars that would be costly or confusing to
  regenerate.
- Use `/private/tmp` only for disposable scratch outputs. If an artifact is
  shown to the user, needed for a PR decision, or expensive to recompute, also
  place it in a persistent location such as a remote machine work directory,
  Dropbox-backed storage, or another explicitly chosen durable directory.
- Keep review HTML pages next to the media they review, so copied paths remain
  valid after restarts and context compaction.
- Record enough reproduction information in `docs/codex/visualization_refactor_status.md`
  or another task-specific memo: machine name, branch/commit, exact command,
  input configuration path, output directory, generated filenames, and visual
  review result.
- For remote runs, also record the login/manual location and any queue/job IDs
  needed to recover logs or outputs later.

## First implementation target

Start with a behavior-preserving refactor:

1. Add current default constants.
2. Replace hard-coded magic numbers with named constants.
3. Add minimal metadata and return-value contracts if possible.
4. Do not change the generated visualization unless explicitly requested.
5. Run Julia formatting or at least a syntax check and tests when feasible.

## Do not modify

Do not modify files under `docs/codex/visualization_refactor_v7/` unless explicitly asked. They are reference materials.
