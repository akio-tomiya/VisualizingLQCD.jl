#!/bin/bash
#SBATCH -J vlqcd-render-32x64
#SBATCH -N 1
#SBATCH -G 1
#SBATCH -p GPU
#SBATCH -t 24:00:00
#SBATCH --output=logs/vlqcd-render-32x64-%j.out
#SBATCH --error=logs/vlqcd-render-32x64-%j.err

set -euo pipefail

if ! type module >/dev/null 2>&1; then
  source /etc/profile.d/modules.sh 2>/dev/null || source /usr/share/Modules/init/bash
fi
module use --append /sc/system/modulefiles 2>/dev/null || true
module load julia
module load nv 2>/dev/null || true

export JULIA_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
input="${VLQCD_RENDER_INPUT:-outputs/Conf32323264beta6.0.ildg}"
output="${VLQCD_RENDER_OUTPUT:-outputs/plaquette_3D_contour_animation32323264beta6.0.mp4}"
preflight="${VLQCD_PREFLIGHT_DIAGNOSE:-1}"
preflight_loader="${VLQCD_PREFLIGHT_LOADER:-ildg}"
preflight_temp_count="${VLQCD_PREFLIGHT_TEMP_COUNT:-4}"

mkdir -p logs outputs

echo "job_id=${SLURM_JOB_ID:-}"
echo "host=$(hostname)"
echo "date=$(date -Is)"
echo "workdir=$(pwd)"
echo "DISPLAY=${DISPLAY:-}"
echo "JULIA_NUM_THREADS=${JULIA_NUM_THREADS}"
echo "input=$input"
echo "output=$output"
echo "preflight=$preflight"
module list
julia --version
nvidia-smi || true
glxinfo -B || true

if [[ "$preflight" != "0" ]]; then
  julia --project=. --startup-file=no \
    scripts/yitp_sample/diagnose_action_density.jl \
    --loader "$preflight_loader" \
    --nx 32 --ny 32 --nz 32 --nt 64 --nc 3 \
    --input "$input" \
    --temp-count "$preflight_temp_count" \
    --skip-plane-stats \
    --fail-on-contamination
fi

srun julia --project=. --startup-file=no \
  scripts/yitp_sample/render_large_sample.jl \
  --nx 32 --ny 32 --nz 32 --nt 64 --nc 3 --beta 6.0 \
  --input "$input" \
  --output "$output" \
  --camera-orbit-turns 0.175
