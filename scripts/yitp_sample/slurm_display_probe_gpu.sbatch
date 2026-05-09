#!/bin/bash
#SBATCH -J vlqcd-display-gpu
#SBATCH -N 1
#SBATCH -G 1
#SBATCH -p GPU
#SBATCH -t 00:10:00
#SBATCH --output=logs/vlqcd-display-gpu-%j.out
#SBATCH --error=logs/vlqcd-display-gpu-%j.err

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

for c in Xvfb xvfb-run Xorg Xwayland vglrun glxinfo eglinfo nvidia-smi timeout; do
  path=$(command -v "$c" || true)
  if [ -n "$path" ]; then
    printf "%s FOUND %s\n" "$c" "$path"
  else
    printf "%s MISSING\n" "$c"
  fi
done

echo "[probe] X sockets"
ls -la /tmp/.X11-unix 2>/dev/null || true

echo "[probe] X-related processes"
ps -ef | grep -Ei "Xorg|Xvfb|Xwayland|vgl|wayland" | grep -v grep || true

echo "[probe] nvidia-smi"
nvidia-smi || true

echo "[probe] glxinfo without DISPLAY"
glxinfo -B || true

echo "[probe] glxinfo with DISPLAY=:0"
DISPLAY=:0 glxinfo -B || true

echo "[probe] glxinfo with DISPLAY=:0 and software mesa"
LIBGL_ALWAYS_SOFTWARE=1 DISPLAY=:0 glxinfo -B || true

echo "[probe] VirtualGL without DISPLAY"
vglrun glxinfo -B || true

echo "[probe] VirtualGL against :0"
vglrun -d :0 glxinfo -B || true
