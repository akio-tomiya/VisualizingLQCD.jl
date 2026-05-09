#!/bin/bash
#SBATCH -J vlqcd-gl-smoke
#SBATCH -N 1
#SBATCH -G 1
#SBATCH -p GPU
#SBATCH -t 00:20:00
#SBATCH --output=logs/vlqcd-gl-smoke-%j.out
#SBATCH --error=logs/vlqcd-gl-smoke-%j.err

set -euo pipefail

if ! type module >/dev/null 2>&1; then
  source /etc/profile.d/modules.sh 2>/dev/null || source /usr/share/Modules/init/bash
fi
module use --append /sc/system/modulefiles 2>/dev/null || true
module load julia
module load nv 2>/dev/null || true

mkdir -p logs outputs

echo "job_id=${SLURM_JOB_ID:-}"
echo "host=$(hostname)"
echo "date=$(date -Is)"
echo "workdir=$(pwd)"
echo "DISPLAY=${DISPLAY:-}"
module list
julia --version
nvidia-smi || true
glxinfo -B || true

srun julia --project=. --startup-file=no scripts/yitp_sample/glmakie_smoke.jl
