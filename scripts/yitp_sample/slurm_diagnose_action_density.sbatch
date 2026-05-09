#!/usr/bin/env bash
#SBATCH --job-name=vlqcd-diagnose
#SBATCH --partition=DEBUG
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:15:00
#SBATCH --output=logs/diagnose_action_density-%j.out
#SBATCH --error=logs/diagnose_action_density-%j.err

set -euo pipefail

julia_bin="${JULIA_BIN:-/home/soryushi/akio/julia-1.11.2/bin/julia}"
project="${JULIA_PROJECT:-/home/soryushi/akio/.julia/environments/v1.11}"
input="${INPUT_PATH:-/sc/home/akio/VisualizingLQCD-yitp-sample/outputs/Conf32323264beta6.0.ildg}"
loader="${LOADER:-binary}"
nx="${NX:-32}"
ny="${NY:-32}"
nz="${NZ:-32}"
nt="${NT:-64}"
nc="${NC:-3}"
temp_count="${TEMP_COUNT:-4}"
skip_plane_stats="${SKIP_PLANE_STATS:-1}"
extra_args=()

if [[ "$skip_plane_stats" != "0" ]]; then
  extra_args+=(--skip-plane-stats)
fi

mkdir -p logs

echo "job_id=${SLURM_JOB_ID:-manual}"
echo "julia=$julia_bin"
echo "project=$project"
echo "input=$input"
echo "loader=$loader"
echo "dims=$nx,$ny,$nz,$nt nc=$nc"
echo "temp_count=$temp_count"
echo "skip_plane_stats=$skip_plane_stats"

"$julia_bin" --project="$project" --startup-file=no \
  scripts/yitp_sample/diagnose_action_density.jl \
  --loader "$loader" \
  --nx "$nx" --ny "$ny" --nz "$nz" --nt "$nt" --nc "$nc" \
  --temp-count "$temp_count" \
  --input "$input" \
  --fail-on-contamination \
  "${extra_args[@]}"
