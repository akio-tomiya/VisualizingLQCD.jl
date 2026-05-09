# YITP Large Sample Workflow

This directory keeps the scripts used to generate a larger sample configuration
and render a sample movie without running heavy work on the local machine.

## Target

- Lattice: `32 x 32 x 32 x 64`
- `beta=6.0`
- `NC=3`
- Heatbath sweeps:
  - YITP first attempt: `20`
  - studio1 fallback sample used in the current README media: `40`
- Gradient-flow steps: `200`

## YITP Paths

Working directory on YITP:

```bash
/sc/home/akio/VisualizingLQCD-yitp-sample
```

Generated configuration:

```bash
outputs/Conf32323264beta6.0.ildg
```

The first studio1 read/render attempt using the YITP-generated `32^3 x 64`
configuration failed diagnostics: many slices showed exact-`1.0`
action-density contamination. A later investigation fresh-copied the current
YITP file, verified checksum agreement, and could not reproduce the
contamination. Treat the old failure as a stale copy, stale workdir,
script/environment mix-up, or missing-preflight problem unless the original bad
studio1 copy can be reproduced with a checksum. It is not evidence that the
whole visualization code is broken.

Current YITP file checksum:

```bash
sha256 9bc6165178f48b7b49d678d807eb2293fb04bc245fd8aef61e17b81164b716d0
```

The detailed failure report is saved locally at:

```bash
/Users/akio/Downloads/VisualizingLQCD_YITP_32x64_failure_report_20260509.md
```

The follow-up investigation report is saved locally at:

```bash
/Users/akio/Downloads/VisualizingLQCD_YITP_32x64_investigation_report_20260509.md
```

## Package Setup

Do not run `Pkg.add` on `front` or in batch jobs. Use the YITP login gate
alias `yitp-mercury`, then activate this shared project:

```bash
ssh -F /Users/akio/repository/supercomputers_info/login_info.md yitp-mercury
cd /sc/home/akio/VisualizingLQCD-yitp-sample
source /etc/profile.d/modules.sh 2>/dev/null || source /usr/share/Modules/init/bash
module use --append /sc/system/modulefiles 2>/dev/null || true
module load julia
julia --project=. --startup-file=no -e 'import Pkg; Pkg.instantiate()'
```

`GLMakie` needs a display/OpenGL context. It fails on login/front nodes without
`DISPLAY`; use the smoke/probe jobs below to test whether rendering is possible
on YITP.

Current display findings:

- CPU queues can be idle and usable for configuration generation.
- CPU compute nodes tested through `DEBUG` do not expose `Xorg`, `Xwayland`,
  `Xvfb`, `xvfb-run`, or `vglrun`.
- `glxinfo` is present on CPU compute nodes, but fails without `DISPLAY`.
- Front/login nodes expose `Xorg` and `vglrun`, but `Xorg` is not usable from a
  normal SSH session (`Only console users are allowed to run the X server`).
- GPU partition display behavior still needs a GPU-node probe.

## Generate Configuration

Before trusting a large generated configuration, run a tiny I/O round-trip smoke
test in the same Julia/Gaugefields environment:

```bash
julia --project=. --startup-file=no scripts/yitp_sample/roundtrip_io_smoke.jl \
  --nx 4 --ny 4 --nz 4 --nt 8 \
  --output outputs/roundtrip/RoundTrip4448beta6.0.ildg \
  --overwrite
```

The smoke test writes a tiny configuration, reloads it, computes local action
density, and exits nonzero if exact-`1.0` contamination appears.

Batch version:

```bash
sbatch scripts/yitp_sample/slurm_roundtrip_io_smoke.sbatch
```

Diagnose an existing configuration before rendering:

```bash
sbatch scripts/yitp_sample/slurm_diagnose_action_density.sbatch
```

The diagnostic prints Julia/Gaugefields paths, file size/checksum, link norms,
plaquette-plane quantiles, local-action-density quantiles, and exits nonzero
when contamination criteria are violated. Override inputs with environment
variables, for example:

```bash
LOADER=ildg INPUT_PATH=outputs/Conf32323264beta6.0.ildg \
  sbatch scripts/yitp_sample/slurm_diagnose_action_density.sbatch
```

For large lattices the batch wrapper defaults to `TEMP_COUNT=4` and
`SKIP_PLANE_STATS=1` to keep memory below the DEBUG queue limit. Set
`SKIP_PLANE_STATS=0` only when per-plane forensic output is needed and enough
memory is available.

Smoke test:

```bash
sbatch scripts/yitp_sample/slurm_generate_smoke.sbatch
```

Production:

```bash
sbatch scripts/yitp_sample/slurm_generate_large_sample.sbatch
```

The production script intentionally uses the existing Julia 1.11 Gaugefields
environment:

```bash
/home/soryushi/akio/julia-1.11.2/bin/julia
/home/soryushi/akio/.julia/environments/v1.11
```

## Render on YITP

First test GLMakie on the GPU partition:

```bash
sbatch scripts/yitp_sample/slurm_glmakie_smoke_gpu.sbatch
```

CPU display probe, expected to fail unless the YITP node image changes:

```bash
sbatch scripts/yitp_sample/slurm_display_probe_cpu_debug.sbatch
```

GPU display probe:

```bash
sbatch scripts/yitp_sample/slurm_display_probe_gpu.sbatch
```

If the smoke test succeeds, render the large sample on YITP:

```bash
sbatch scripts/yitp_sample/slurm_render_large_sample_gpu.sbatch
```

The render job runs `diagnose_action_density.jl --fail-on-contamination` first
unless `VLQCD_PREFLIGHT_DIAGNOSE=0` is set.

Do not fall back to local rendering unless explicitly decided.

## Render on studio1 Fallback

Use this only after explicitly deciding to render on `studio1`.

The studio fallback keeps the render in a scratch workdir and avoids writing to
the global Julia environments:

```bash
ssh -F /Users/akio/repository/supercomputers_info/login_info.md studio1
/Users/akio/VisualizingLQCD-yitp-local-render/scripts/yitp_sample/studio_prepare_render_env.sh
/Users/akio/VisualizingLQCD-yitp-local-render/scripts/yitp_sample/studio_render_large_sample.sh
```

The prepare step uses the scratch depot
`/Users/akio/VisualizingLQCD-yitp-local-render/.julia_depot_110_clean` plus the
Julia 1.10 system depots. If a copied `Manifest.toml` was generated by a
different Julia minor version, it is backed up in the scratch directory before a
Julia 1.10 manifest is created.

The current README media in this branch use the sane studio1-generated
`32^3 x 64` fallback configuration:

```bash
/Users/akio/VisualizingLQCD-yitp-local-render/outputs/Conf32323264beta6.0-gf05hb40flow200.ildg
```

Its `before_save` and `after_reload` sanity checks passed. Render from this file
by default with:

```bash
/Users/akio/VisualizingLQCD-yitp-local-render/scripts/yitp_sample/studio_render_large_sample.sh
```

The render script can also be controlled with:

```bash
VLQCD_RENDER_INPUT=outputs/Conf32323264beta6.0-gf05hb40flow200.ildg
VLQCD_RENDER_OUTPUT=outputs/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.mp4
VLQCD_CAMERA_ORBIT_TURNS=1.0
VLQCD_RENDER_NLOOPS=6
VLQCD_RENDER_FRAMERATE=14
VLQCD_SLICE_HOLD_FRAMES=2
VLQCD_FIGURE_SIZE=480
VLQCD_RENDER_LOG=/Users/akio/VisualizingLQCD-yitp-local-render/logs/studio-render-custom.log
```

The studio render wrapper also runs the same preflight diagnostic before
starting the background render. Disable it only with
`VLQCD_PREFLIGHT_DIAGNOSE=0` after a matching diagnostic log already exists.

The full-turn README candidate uses `camera_orbit_turns=1.0`, `nloops=6`,
`framerate=14`, `slice_hold_frames=2`, and `figure_size=480`. This gives `768`
frames at `14` fps, about `55` seconds. The Euclidean fourth direction runs
through all `64` slices exactly six times, with each slice held for two frames,
while the camera makes one full turn. Do not make the README GIF by dropping
frames from a higher-fps source; that can skip a nontrivial subset of
fourth-direction slices and make the loop boundary look discontinuous.

## Convert MP4 to GIF

YITP currently does not expose a system `ffmpeg` command in the tested shell
environment. The Julia converter first tries `ffmpeg` on `PATH`, then tries
`FFMPEG_jll` if it has been added to the active Julia project.

Manual conversion:

```bash
julia --project=. --startup-file=no scripts/yitp_sample/convert_mp4_to_gif.jl \
  --input outputs/plaquette_3D_contour_animation32323264beta6.0.mp4 \
  --output outputs/plaquette_3D_contour_animation32323264beta6.0.gif \
  --width 200 \
  --fps 14
```

Batch conversion:

```bash
sbatch scripts/yitp_sample/slurm_convert_gif_debug.sbatch
```

If both `ffmpeg` and `FFMPEG_jll` are unavailable, add `FFMPEG_jll` from
`yitp-mercury`, not from `front`:

```bash
ssh -F /Users/akio/repository/supercomputers_info/login_info.md yitp-mercury
cd /sc/home/akio/VisualizingLQCD-yitp-sample
julia --project=. --startup-file=no -e 'import Pkg; Pkg.add("FFMPEG_jll")'
```

## Quick Status Check

From the local machine:

```bash
scripts/yitp_sample/check_remote_status.sh
```
