# Phase 1 transform and level notes

Goal: make the plaquette logarithm a named display transform and make threshold selection reproducible.

Suggested additions:

- `TransformSpec(:neglog, 1e-7, :fixed, (0.0, 1.0))`
- `LevelSpec(:quantile, [0.80, 0.90, 0.95, 0.98], Float64[], :upper, true)`
- `invert_display_level(level, transform, epsilon)`
- JSON sidecar fields for raw-equivalent levels.

Important semantic note:

- Upper levels of `:log` correspond to large raw plaquette deviation.
- Upper levels of `:neglog` correspond to small raw plaquette deviation.
- Store `raw_focus_for_upper_levels` in metadata to avoid misinterpretation.
