#!/bin/bash
#SBATCH -J vlqcd-smoke-conf
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 2
#SBATCH -p DEBUG
#SBATCH -t 00:15:00
#SBATCH --output=logs/vlqcd-smoke-conf-%j.out
#SBATCH --error=logs/vlqcd-smoke-conf-%j.err

set -euo pipefail

JULIA_BIN="${JULIA_BIN:-/home/soryushi/akio/julia-1.11.2/bin/julia}"
JULIA_PROJECT_GENERATE="${JULIA_PROJECT_GENERATE:-/home/soryushi/akio/.julia/environments/v1.11}"
export JULIA_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p logs outputs/smoke

echo "job_id=${SLURM_JOB_ID:-}"
echo "host=$(hostname)"
echo "date=$(date -Is)"
echo "workdir=$(pwd)"
echo "JULIA_NUM_THREADS=${JULIA_NUM_THREADS}"
"${JULIA_BIN}" --version

srun "${JULIA_BIN}" --project="${JULIA_PROJECT_GENERATE}" --startup-file=no \
  scripts/yitp_sample/generate_large_sample.jl \
  --nx 4 --ny 4 --nz 4 --nt 4 --nc 3 --beta 6.0 \
  --flow-steps 1 --heatbath-sweeps 1 \
  --output-dir outputs/smoke --overwrite
