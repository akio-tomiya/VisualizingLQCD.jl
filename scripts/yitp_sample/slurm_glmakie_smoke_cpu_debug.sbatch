#!/bin/bash
#SBATCH -J vlqcd-gl-smoke-cpu
#SBATCH -N 1
#SBATCH -p DEBUG
#SBATCH -t 00:10:00
#SBATCH --output=logs/vlqcd-gl-smoke-cpu-%j.out
#SBATCH --error=logs/vlqcd-gl-smoke-cpu-%j.err

set -euo pipefail

if ! type module >/dev/null 2>&1; then
  source /etc/profile.d/modules.sh 2>/dev/null || source /usr/share/Modules/init/bash
fi
module use --append /sc/system/modulefiles 2>/dev/null || true
module load julia

mkdir -p logs outputs

echo "job_id=${SLURM_JOB_ID:-}"
echo "host=$(hostname)"
echo "date=$(date -Is)"
echo "workdir=$(pwd)"
echo "DISPLAY=${DISPLAY:-}"
module list
julia --version
glxinfo -B || true

srun julia --project=. --startup-file=no scripts/yitp_sample/glmakie_smoke.jl
