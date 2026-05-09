#!/usr/bin/env bash
set -euo pipefail

ssh_config="${YITP_SSH_CONFIG:-/Users/akio/repository/supercomputers_info/login_info.md}"
host="${YITP_HOST:-yitpsc}"
remote_dir="${YITP_WORKDIR:-/sc/home/akio/VisualizingLQCD-yitp-sample}"

ssh -F "$ssh_config" -o BatchMode=yes -o ConnectTimeout=15 "$host" \
  bash -s -- "$remote_dir" <<'REMOTE_STATUS'
set -euo pipefail
remote_dir="$1"

echo "== queue =="
squeue -u "$USER" -o "%i|%P|%j|%T|%M|%D|%R" || true

cd "$remote_dir"

echo
echo "== outputs =="
ls -lh outputs 2>/dev/null || true

echo
echo "== generated configuration metadata =="
cat outputs/Conf32323264beta6.0.ildg.metadata.txt 2>/dev/null || true

echo
echo "== generation log tail =="
tail -n 80 logs/vlqcd-32x64-conf-9491.out 2>/dev/null || true
tail -n 40 logs/vlqcd-32x64-conf-9491.err 2>/dev/null || true

echo
echo "== display and render logs =="
ls -ltr logs/vlqcd-gl-smoke-* logs/vlqcd-display-gpu-* logs/vlqcd-render-32x64-* 2>/dev/null | tail -n 30 || true
for f in logs/vlqcd-gl-smoke-9494.out logs/vlqcd-gl-smoke-9494.err logs/vlqcd-display-gpu-9509.out logs/vlqcd-display-gpu-9509.err; do
  if [ -f "$f" ]; then
    echo
    echo "-- $f --"
    tail -n 120 "$f"
  fi
done
REMOTE_STATUS
