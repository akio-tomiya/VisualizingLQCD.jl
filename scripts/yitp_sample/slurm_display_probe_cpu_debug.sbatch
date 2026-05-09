#!/bin/bash
#SBATCH -J vlqcd-display-probe
#SBATCH -N 1
#SBATCH -p DEBUG
#SBATCH -t 00:05:00
#SBATCH --output=logs/vlqcd-display-probe-%j.out
#SBATCH --error=logs/vlqcd-display-probe-%j.err

set -euo pipefail

mkdir -p logs outputs

echo "job_id=${SLURM_JOB_ID:-}"
echo "host=$(hostname)"
echo "date=$(date -Is)"
echo "workdir=$(pwd)"
echo "DISPLAY=${DISPLAY:-}"

for c in Xvfb xvfb-run Xorg Xwayland vglrun glxinfo eglinfo nvidia-smi timeout; do
  path=$(command -v "$c" || true)
  if [ -n "$path" ]; then
    printf "%s FOUND %s\n" "$c" "$path"
  else
    printf "%s MISSING\n" "$c"
  fi
done

echo "[probe] glxinfo without DISPLAY"
glxinfo -B || true

echo "[probe] VirtualGL without DISPLAY"
vglrun glxinfo -B || true

echo "[probe] VirtualGL against :0"
vglrun -d :0 glxinfo -B || true

echo "[probe] Xorg :99 short-lived"
xorg_log="logs/xorg-probe-${SLURM_JOB_ID:-manual}.log"
timeout 20s Xorg :99 -noreset -logfile "$xorg_log" &
xorg_pid=$!
sleep 5
DISPLAY=:99 glxinfo -B || true
LIBGL_ALWAYS_SOFTWARE=1 DISPLAY=:99 glxinfo -B || true
kill "$xorg_pid" 2>/dev/null || true
wait "$xorg_pid" || true

echo "[probe] Xorg log tail"
tail -n 120 "$xorg_log" || true
