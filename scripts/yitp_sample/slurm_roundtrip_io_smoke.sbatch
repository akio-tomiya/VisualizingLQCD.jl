#!/bin/bash
#SBATCH -J vlqcd-io-smoke
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 2
#SBATCH -p DEBUG
#SBATCH -t 00:15:00
#SBATCH --output=logs/vlqcd-io-smoke-%j.out
#SBATCH --error=logs/vlqcd-io-smoke-%j.err

set -euo pipefail

JULIA_BIN="${JULIA_BIN:-/home/soryushi/akio/julia-1.11.2/bin/julia}"
JULIA_PROJECT_GENERATE="${JULIA_PROJECT_GENERATE:-/home/soryushi/akio/.julia/environments/v1.11}"
export JULIA_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p logs outputs/roundtrip

job_id="${SLURM_JOB_ID:-manual}"
output="outputs/roundtrip/RoundTrip4448beta6.0-${job_id}.ildg"

echo "job_id=${SLURM_JOB_ID:-}"
echo "host=$(hostname)"
echo "date=$(date -Is)"
echo "workdir=$(pwd)"
echo "JULIA_NUM_THREADS=${JULIA_NUM_THREADS}"
echo "output=${output}"
"${JULIA_BIN}" --version

srun "${JULIA_BIN}" --project="${JULIA_PROJECT_GENERATE}" --startup-file=no \
  scripts/yitp_sample/roundtrip_io_smoke.jl \
  --nx 4 --ny 4 --nz 4 --nt 8 --nc 3 --beta 6.0 \
  --flow-steps 1 --heatbath-sweeps 1 \
  --output "${output}" \
  --loaders binary,ildg
