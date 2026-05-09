#!/bin/bash
#SBATCH -J vlqcd-mp4-gif
#SBATCH -N 1
#SBATCH -p DEBUG
#SBATCH -t 00:15:00
#SBATCH --output=logs/vlqcd-mp4-gif-%j.out
#SBATCH --error=logs/vlqcd-mp4-gif-%j.err

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
module list
julia --version

srun julia --project=. --startup-file=no \
  scripts/yitp_sample/convert_mp4_to_gif.jl \
  --input outputs/plaquette_3D_contour_animation32323264beta6.0.mp4 \
  --output outputs/plaquette_3D_contour_animation32323264beta6.0.gif \
  --width 520 \
  --fps 10
