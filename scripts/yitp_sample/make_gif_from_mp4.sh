#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 INPUT.mp4 OUTPUT.gif [width] [fps]" >&2
  exit 2
fi

input="$1"
output="$2"
width="${3:-200}"
fps="${4:-14}"
palette="$(mktemp "${TMPDIR:-/tmp}/vlqcd-palette.XXXXXX.png")"
trap 'rm -f "$palette"' EXIT

ffmpeg -y -i "$input" \
  -vf "fps=${fps},scale=${width}:-1:flags=lanczos,palettegen=stats_mode=diff" \
  "$palette"
ffmpeg -y -i "$input" -i "$palette" \
  -lavfi "fps=${fps},scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" \
  "$output"
