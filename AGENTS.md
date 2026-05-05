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

## First implementation target

Start with a behavior-preserving refactor:

1. Add current default constants.
2. Replace hard-coded magic numbers with named constants.
3. Add minimal metadata and return-value contracts if possible.
4. Do not change the generated visualization unless explicitly requested.
5. Run Julia formatting or at least a syntax check and tests when feasible.

## Do not modify

Do not modify files under `docs/codex/visualization_refactor_v7/` unless explicitly asked. They are reference materials.
