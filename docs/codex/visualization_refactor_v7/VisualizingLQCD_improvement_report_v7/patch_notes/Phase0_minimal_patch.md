# Phase 0 minimal patch notes

Goal: remove misleading on-screen time labels while keeping the current visual look.

1. Remove `const LtoSec = 10 / 3` from the display path.
2. Replace `t = i % NT + 1` with `slice4 = (i - 1) % NT + 1`.
3. Keep the title static, for example `Plaquette log iso-surface`.
4. Do not remove `-log(tmp + 1e-7)`. Treat it as a display transform.
5. Add README wording that the animation shows Euclidean slices, not real-time Minkowski evolution.

Acceptance:

- The movie title contains no yoctosecond, `t`, `tau`, or slice index by default.
- The frame order for `NT=4` is `1, 2, 3, 4`.
- The current log-transformed look remains available.
