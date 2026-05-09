# YITP 32^3 x 64 failure investigation plan

Last updated: 2026-05-10 JST

Source report:

- `/Users/akio/Downloads/VisualizingLQCD_YITP_32x64_failure_report_20260509.md`

Reference constraints:

- Do not treat the fourth Euclidean lattice direction as real time.
- Do not tune visualization thresholds to hide bad data.
- Keep the current `-log(p + 1e-7)` display transform intact.
- Keep I/O, observables, transforms, level selection, rendering, metadata, and
  configuration generation separated.
- Do not edit `docs/codex/visualization_refactor_v7/`; it is reference
  material.

## Summary

The observed failure is not primarily a GLMakie/display failure. YITP could not
render with GLMakie in the tested setup, but the original report's important
failure was that a studio1 render/diagnostic run saw the YITP-generated
`32 x 32 x 32 x 64` configuration as invalid after reload.

Originally suspected file and old studio1 copy:

```text
/sc/home/akio/VisualizingLQCD-yitp-sample/outputs/Conf32323264beta6.0.ildg
/Users/akio/VisualizingLQCD-yitp-local-render/outputs/Conf32323264beta6.0.ildg
```

Original failure signature from the old studio1 read/render path:

- `local_action_density = 1 - ReTr(U_p) / Nc` has many exact `1.0` values.
- Global `frac_eq1` is about `0.53`.
- Several fourth-direction slices have `frac_eq1 = 1.0`.
- Render metadata collapsed to `display_levels = [1.0]` and
  `color_range = [1.0, 1.0]`.

Control:

- Known-good `Conf24242432beta6.0.ildg` has `frac_eq1 = 0` and density
  quantiles around `1e-4` to `1e-3` under the same diagnostic path.

The current investigation has changed the working assumption: a fresh
checksum-matched copy of the same YITP file now passes YITP same-environment and
local cross-version diagnostics. The remaining suspect is the earlier studio1
copy/workdir/render environment rather than the current YITP file itself.

## Phase 0/1 findings on 2026-05-09

These checks were read-only on YITP/studio1.

Local current script hashes:

```text
870fd3a2fa558f4bfc06119e6a8a8653ff03a732cebcc0b5517063767f9e95cf  scripts/yitp_sample/generate_large_sample.jl
edd433d74bf1db0ffd27891446b1211dc653776f5439a475be558e77e41450b1  scripts/yitp_sample/diagnose_action_density.jl
ea4aad4becebb77d06ab113d29c504623ce5e3cb48630a81945c567de0506952  scripts/yitp_sample/inspect_gaugefields_io.jl
```

YITP deployed script state under
`/sc/home/akio/VisualizingLQCD-yitp-sample`:

```text
ada1165eadea3e81ee780ec2f3d71dfbf26b572bce7280d8001630cd0204773a  scripts/yitp_sample/generate_large_sample.jl
missing scripts/yitp_sample/diagnose_action_density.jl
missing scripts/yitp_sample/inspect_gaugefields_io.jl
missing outputs/Conf32323264beta6.0.ildg.sanity.txt
```

The YITP script used for job `9491` was stale relative to the current local
script. It did not contain before-save / after-reload sanity checks, and the
generation log has no `sanity_check`, `before_save`, or `after_reload` lines.
This means the bad large file was allowed to pass based only on heatbath/flow
progress and `save_binarydata` completion.

Package versions:

```text
YITP:
  Julia 1.11.2
  project: /home/soryushi/akio/.julia/environments/v1.11/Project.toml
  Gaugefields v0.4.0
  Wilsonloop v0.1.5

studio1:
  Julia 1.10.11
  project: /Users/akio/VisualizingLQCD-yitp-local-render/Project.toml
  Gaugefields v0.5.18
  Wilsonloop v0.1.5
  VisualizingLQCD v0.0.1
```

Immediate interpretation before Phase 3:

- The strongest confirmed cause so far is the combination of stale YITP helper
  scripts and a Gaugefields version mismatch (`v0.4.0` writer/generator on YITP
  vs `v0.5.18` reader/diagnostic on studio1).
- This does not yet prove Gaugefields `v0.4.0` wrote a corrupt file. It proves
  that the production run lacked the sanity checks that would have caught the
  invalid saved data before rendering.
- Any fix should first prevent unsanitized large files from being treated as
  renderable.

## Phase 2 update on 2026-05-09

A tiny same-environment round-trip smoke test was added and run on YITP in a new
investigation directory:

```text
/sc/home/akio/VisualizingLQCD-yitp-io-investigation-20260509_1845
```

Job `9723` failed before exercising Gaugefields I/O because the first version of
the smoke script used `Base.pkgid`, which is not available in that YITP Julia
environment. The script was fixed to report package paths with `pathof`.

Job `9724` completed successfully on YITP:

```text
lattice: 4 x 4 x 4 x 8
writer: save_binarydata
output: outputs/roundtrip/RoundTrip4448beta6.0-9724.ildg
bytes: 295056
sha256: 8cb259dd4dd5ab063fe71a466755917653d3ec3a93b0048e7940b625e294fb9b
```

Result:

- `before_save` action-density sanity passed.
- `after_reload_binary` sanity passed.
- `after_reload_ildg` sanity passed.
- All checked slices had `frac_eq1 = 0.0` and `frac_ge099 = 0.0`.
- The global `q90` was about `0.3617`, below the smoke-test failure threshold.

Interpretation:

- YITP's current Gaugefields `v0.4.0` environment can write and reload a tiny
  file in the same environment without the exact-1 contamination seen in the bad
  `32^3 x 64` output.
- The bad production file is therefore not explained by a universal tiny-file
  same-environment `save_binarydata`/`load_binarydata!` failure.
- Remaining likely causes are a stale unsanitized generation path, cross-version
  reader/writer incompatibility, or a large-lattice-specific failure.

The YITP tiny output was copied to studio1 for a cross-version read test, but
the studio1 scratch render environment failed before diagnostics could run:

```text
ArgumentError: Package JLLWrappers ... is required but does not seem to be
installed
```

This is an environment-instantiation blocker, not yet evidence about the tiny
file's portability.

After creating a temporary Julia 1.10 reader project from a Julia-1.10-compatible
manifest, the same tiny YITP output was diagnosed locally with Gaugefields
`v0.5.18`:

```text
input: /private/tmp/VisualizingLQCD_RoundTrip4448beta6.0-9724.ildg
sha256: 8cb259dd4dd5ab063fe71a466755917653d3ec3a93b0048e7940b625e294fb9b
reader: Julia 1.10.10, Gaugefields v0.5.18
loaders tested: binary, ildg
```

Both local cross-version tiny reads passed with `frac_eq1 = 0.0` and
`frac_ge099 = 0.0` for the global local-action-density check.

## Phase 3 update on 2026-05-09

The existing `32^3 x 64` file was re-diagnosed directly on YITP and after a
fresh local copy:

```text
input: /sc/home/akio/VisualizingLQCD-yitp-sample/outputs/Conf32323264beta6.0.ildg
bytes: 1207959696
sha256: 9bc6165178f48b7b49d678d807eb2293fb04bc245fd8aef61e17b81164b716d0
```

Initial large diagnostic attempts exposed script/environment issues rather than
data contamination:

- Job `9728` failed before loading because the YITP environment did not have
  `StatsBase` as a direct dependency. The scripts now use the standard
  `Statistics` module for `quantile` and no longer require `StatsBase`.
- Jobs `9729` and `9730` hit the DEBUG queue memory limit. The diagnostic
  wrapper now requests memory explicitly and supports `--temp-count` plus
  `--skip-plane-stats`; the large default uses `TEMP_COUNT=4` and
  `SKIP_PLANE_STATS=1`.

Successful large diagnostics:

```text
YITP job 9731, loader=binary, Julia 1.11.2, Gaugefields v0.4.0:
  density q90 = 0.0010912513678454417
  density max = 0.16746249416639056
  frac_eq1 = 0.0
  frac_ge099 = 0.0
  result: diagnose_action_density ok

YITP job 9732, loader=ildg, Julia 1.11.2, Gaugefields v0.4.0:
  same density statistics as binary loader
  frac_eq1 = 0.0
  frac_ge099 = 0.0
  result: diagnose_action_density ok
```

The file was then copied freshly to:

```text
/private/tmp/Conf32323264beta6.0-yitp-9731.ildg
```

The local checksum matched YITP:

```text
9bc6165178f48b7b49d678d807eb2293fb04bc245fd8aef61e17b81164b716d0
```

Local cross-version large diagnostics with Julia `1.10.10` and Gaugefields
`v0.5.18` also passed with both loaders:

```text
loader=binary:
  density q90 = 0.0010912513678454417
  density max = 0.16746249416639056
  frac_eq1 = 0.0
  frac_ge099 = 0.0
  result: diagnose_action_density ok

loader=ildg:
  same density statistics as binary loader
  frac_eq1 = 0.0
  frac_ge099 = 0.0
  result: diagnose_action_density ok
```

Revised interpretation:

- The currently existing YITP `32^3 x 64` file is not intrinsically corrupt
  under the tested YITP same-environment or local Julia-1.10/Gaugefields-0.5.18
  readers.
- The exact-`1.0` failure recorded in the original report is not reproducible
  from a fresh checksum-matched copy of the YITP file.
- The most likely remaining explanations are a stale/corrupted earlier studio1
  copy, stale render/diagnostic code in the earlier studio workdir, or an
  environment/project mismatch during the previous render.
- The guardrail fix is still valuable: every render path should record file
  checksum/environment and refuse to render files that fail the action-density
  sanity check.

## Main hypotheses

1. **Version mismatch**
   - YITP generated with Julia `1.11.2` and the global
     `/home/soryushi/akio/.julia/environments/v1.11` environment.
   - studio1 rendered/diagnosed with Julia `1.10` in a scratch project aligned
     with this repository.
   - Gaugefields.jl and Wilsonloop.jl versions may differ.

2. **Format mismatch hidden by `.ildg`**
   - The file name ends in `.ildg`, but the writer path is `save_binarydata`.
   - The file may not be portable ILDG in the sense expected by
     `load_gaugefield!(..., ILDG(...))`.
   - The extension alone must not decide the loader.

3. **Old deployed script or missing sanity check on YITP**
   - The current local `scripts/yitp_sample/generate_large_sample.jl` already
     has before-save and after-reload sanity checks unless `--no-sanity-check`
     is passed.
   - The failed YITP job may have used an older copied script, a different
     project, or a code path that did not run these checks.

4. **YITP same-environment write/read failure**
   - If YITP generates and then reloads a tiny lattice in the same environment
     and still shows exact-1 contamination, the bug is in the YITP generation or
     Gaugefields.jl save/load path, not just cross-version portability.

5. **Large-lattice specific issue**
   - If tiny round trips all pass but `32^3 x 64` fails, investigate
     size-dependent I/O, memory pressure, file-record layout, or dimension-order
     handling.

## Investigation phases

### Phase 0: Local audit, no heavy execution

Goal: make sure the current repository state and the failure report agree.

Checklist:

- Read the failure report and preserve its evidence.
- Confirm that current helper scripts include:
  - `scripts/yitp_sample/generate_large_sample.jl`
  - `scripts/yitp_sample/diagnose_action_density.jl`
  - `scripts/yitp_sample/inspect_gaugefields_io.jl`
- Record that the current local generator has post-save reload sanity checks.
- Compare the YITP-deployed `generate_large_sample.jl` hash/content with the
  current local script before reusing old job results.

Useful commands:

```bash
shasum -a 256 scripts/yitp_sample/generate_large_sample.jl
ssh -F /Users/akio/repository/supercomputers_info/login_info.md yitpsc \
  'cd /sc/home/akio/VisualizingLQCD-yitp-sample && shasum -a 256 scripts/yitp_sample/generate_large_sample.jl'
```

Expected outcome:

- If hashes differ, first determine whether the failed run used a stale script.

### Phase 1: Environment and API inventory

Goal: pin down the actual Julia/Gaugefields/Wilsonloop versions and available
I/O APIs on each machine.

On YITP:

```bash
/home/soryushi/akio/julia-1.11.2/bin/julia \
  --project=/home/soryushi/akio/.julia/environments/v1.11 \
  -e 'using InteractiveUtils; versioninfo(); import Pkg; Pkg.status(["Gaugefields","Wilsonloop","VisualizingLQCD"])'
```

On studio1:

```bash
cd /Users/akio/VisualizingLQCD-yitp-local-render
/Users/akio/.juliaup/bin/julia +1.10 --project=. --startup-file=no \
  -e 'using InteractiveUtils; versioninfo(); import Pkg; Pkg.status(["Gaugefields","Wilsonloop","VisualizingLQCD"])'
```

On both:

```bash
julia --project=. --startup-file=no scripts/yitp_sample/inspect_gaugefields_io.jl
```

Record:

- Julia version and executable path.
- Project path and depot path.
- Gaugefields.jl version/commit if available.
- Wilsonloop.jl version/commit if available.
- Existence and signatures of `save_binarydata`, `load_binarydata!`, `ILDG`,
  and `load_gaugefield!`.

### Phase 2: Tiny same-environment round-trip tests

Goal: test write/read correctness before any large job or rendering.

Use tiny lattices first:

- `4 x 4 x 4 x 8`
- then `8 x 8 x 8 x 8` if the tiny test passes

Test matrix:

| Test | Generate | Reload/diagnose | Purpose |
| --- | --- | --- | --- |
| A | YITP Julia 1.11 env | YITP same env | Does YITP save/load work at all? |
| B | YITP Julia 1.11 env | studio1 Julia 1.10 env | Cross-version portability |
| C | studio1 Julia 1.10 env | studio1 same env | Local control |
| D | studio1 Julia 1.10 env | YITP Julia 1.11 env | Reverse cross-version portability |

Failure criteria:

```text
frac_eq1 >= 1e-6
frac_ge099 >= 1e-6
q90 > 0.5
any selected slice has frac_eq1 >= 1e-6
any render metadata has display_levels = [1.0] or color_range = [1.0, 1.0]
```

Pass criteria:

- `before_save` sanity check passes.
- `after_reload` sanity check passes.
- `diagnose_action_density.jl --loader binary` passes.
- `diagnose_action_density.jl --loader ildg` is either confirmed valid or
  explicitly marked unsupported for this file type.

### Phase 3: Existing large-file forensics

Goal: characterize the existing large file without trusting render output.

For the suspect `32^3 x 64` file:

- Verify byte size and checksum on YITP and studio1.
- Run diagnostics with both loaders on the same machine where practical.
- Dump selected link norms for contaminated and uncontaminated slices.
- Compare exact bad slices across all plaquette planes.
- Record whether the contamination begins at a specific fourth-direction slice
  or appears in a repeated block pattern.

Interpretation:

- Same checksum plus same bad diagnostics on both machines means transfer is
  probably not the cause.
- Bad under `ILDG` but good under `binary` means loader/format mismatch.
- Bad under both loaders only after cross-machine transfer is unlikely if
  checksum matches; then inspect writer/reader compatibility.
- Bad under YITP same-environment reload means the file was already invalid on
  YITP.

### Phase 4: Choose the fix path

Only implement a fix after the phase-2/phase-3 evidence identifies the class of
failure.

Possible fixes:

1. **Stale YITP script**
   - Re-deploy the current script.
   - Require sanity checks in production.
   - Make the Slurm script fail if `.sanity.txt` is missing or contains no
     `after_reload ok`.

2. **Binary-vs-ILDG mismatch**
   - Stop naming `save_binarydata` outputs `.ildg` unless it is proven to be a
     true compatible ILDG file.
   - Add explicit `--storage-format binary|ildg` metadata.
   - Make render/diagnostic scripts choose the loader from metadata or an
     explicit CLI option, not from extension alone.
   - If true ILDG writing exists in Gaugefields.jl, use that writer for `.ildg`
     files and keep `save_binarydata` outputs as `.bin` or a clearly documented
     Gaugefields binary format.

3. **Version mismatch**
   - Stop using the global Julia `v1.11` environment for production sample
     generation.
   - Instantiate the repository project or a dedicated YITP sample project with
     pinned `Project.toml`/`Manifest.toml`.
   - Write package versions into configuration metadata.
   - Require a tiny cross-version round-trip before cross-machine rendering.

4. **Same-environment YITP save/load failure**
   - Minimize a reproducer independent of GLMakie.
   - Test smaller lattices and both file formats.
   - Report or patch the Gaugefields.jl I/O path if the reproducer isolates it.
   - Use a known-good alternative serialization path only as an explicit
     mitigation, not silently.

5. **Large-lattice specific failure**
   - Add a `32^3 x 64` pre-render diagnostic job on the generation host.
   - Avoid rendering until the large saved file passes reload checks.
   - Check memory use and any file-record or dimension-order assumptions.

### Phase 5: Guardrails before final rendering

Before producing a final GIF/MP4:

- Use only a configuration that passed same-environment reload sanity checks.
- Run `diagnose_action_density.jl` and save its output next to the movie.
- Verify render metadata:
  - `display_levels` not equal to `[1.0]`
  - `color_range` not equal to `[1.0, 1.0]`
  - frame map present and uses fourth-direction slice metadata
- Inspect a contact sheet or selected frames.
- Keep bad outputs outside the repository.

## Immediate implementation candidates

These are small, reviewable changes if the investigation confirms the need.

1. Add `scripts/yitp_sample/roundtrip_io_smoke.jl`. **Done locally on
   2026-05-09.**
   - Generate a tiny lattice.
   - Save.
   - Reload via `load_binarydata!`.
   - Optionally reload via `ILDG`.
   - Run the exact action-density failure criteria and exit nonzero on failure.
   - The script passed a YITP same-environment run in job `9724`.
   - Cross-version execution on studio1 is blocked until the scratch render
     environment is instantiated cleanly.

2. Harden `diagnose_action_density.jl`. **Done locally on 2026-05-09.**
   - Print Julia/package versions.
   - Print input file size/checksum when feasible.
   - Support `--fail-on-contamination`.
   - Exit nonzero when failure criteria are violated.
   - Remove the unnecessary `VisualizingLQCD`/GLMakie dependency so the
     diagnostic can run in lightweight Gaugefields/Wilsonloop environments.
   - Add memory controls for large lattices: `--temp-count` and
     `--skip-plane-stats`.

3. Extend generation metadata.
   - Record Julia version, executable, project path, Gaugefields/Wilsonloop
     versions, writer API, loader tested, and sanity-check result.
   - Record `storage_format` separately from filename extension.

4. Harden Slurm scripts. **Partly done locally on 2026-05-09.**
   - Run tiny round-trip smoke before a large generation job.
   - Make production generation fail if post-save reload sanity fails.
   - Avoid global user environments unless deliberately selected and recorded.
   - Added `slurm_roundtrip_io_smoke.sbatch` and
     `slurm_diagnose_action_density.sbatch`.
   - Added pre-render diagnostics to the YITP and studio1 render wrappers,
     enabled by default and disabled only with `VLQCD_PREFLIGHT_DIAGNOSE=0`.

## Current next action

This plan has mostly served its immediate purpose. The current YITP file now
passes checksum-matched diagnostics, and the README media in the active branch
were rendered from the sane studio1 fallback configuration
`Conf32323264beta6.0-gf05hb40flow200.ildg`.

Retain the guardrail as the operational rule: render only from a
checksum-recorded file that passes
`diagnose_action_density.jl --fail-on-contamination`. The active PR-prep step is
to include the helper scripts and notes without committing local scratch
artifacts such as root `Manifest.toml` or `tempconf.dat`.
