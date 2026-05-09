#!/usr/bin/env bash
set -euo pipefail

remote_user_host="${YITP_FRONT_USER_HOST:-akio.tomiya@front.yukawa.kyoto-u.ac.jp}"
remote_dir="${YITP_WORKDIR:-/sc/home/akio/VisualizingLQCD-yitp-sample}"
output_dir="${VLQCD_LOCAL_RENDER_DIR:-/Users/akio/VisualizingLQCD-yitp-local-render}"

ssh_cmd="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o 'ProxyCommand=ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -W %h:%p akio.tomiya@mercury.yukawa.kyoto-u.ac.jp'"

mkdir -p "$output_dir/outputs"
cd "$output_dir"

rsync -a --append --progress -e "$ssh_cmd" \
  "$remote_user_host:$remote_dir/outputs/Conf32323264beta6.0.ildg" \
  "$remote_user_host:$remote_dir/outputs/Conf32323264beta6.0.ildg.metadata.txt" \
  outputs/
