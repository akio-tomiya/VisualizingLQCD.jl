#!/bin/bash
#SBATCH -J vlqcd-32x64-conf
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p S
#SBATCH -t 24:00:00
#SBATCH --output=logs/vlqcd-32x64-conf-%j.out
#SBATCH --error=logs/vlqcd-32x64-conf-%j.err

set -euo pipefail

JULIA_BIN="${JULIA_BIN:-/home/soryushi/akio/julia-1.11.2/bin/julia}"
JULIA_PROJECT_GENERATE="${JULIA_PROJECT_GENERATE:-/home/soryushi/akio/.julia/environments/v1.11}"
export JULIA_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p logs outputs

echo "job_id=${SLURM_JOB_ID:-}"
echo "host=$(hostname)"
echo "date=$(date -Is)"
echo "workdir=$(pwd)"
echo "JULIA_NUM_THREADS=${JULIA_NUM_THREADS}"
"${JULIA_BIN}" --version

srun "${JULIA_BIN}" --project="${JULIA_PROJECT_GENERATE}" --startup-file=no \
  scripts/yitp_sample/generate_large_sample.jl \
  --nx 32 --ny 32 --nz 32 --nt 64 --nc 3 --beta 6.0 \
  --flow-steps 200 --heatbath-sweeps 20 \
  --output-dir outputs
