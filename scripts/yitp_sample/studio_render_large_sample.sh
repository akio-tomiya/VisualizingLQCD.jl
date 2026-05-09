#!/usr/bin/env bash
set -euo pipefail

workdir="${VLQCD_LOCAL_RENDER_DIR:-/Users/akio/VisualizingLQCD-yitp-local-render}"
julia_bin="${JULIA_BIN:-/Users/akio/.juliaup/bin/julia}"
julia_channel="${JULIA_CHANNEL:-+1.10}"
depot="${VLQCD_JULIA_DEPOT:-$workdir/.julia_depot_110_clean}"
timestamp="$(date +%Y%m%d-%H%M%S)"
log="${VLQCD_RENDER_LOG:-$workdir/logs/studio-render-$timestamp.log}"
preflight_log="${VLQCD_PREFLIGHT_LOG:-$workdir/logs/studio-render-preflight-$timestamp.log}"
input="${VLQCD_RENDER_INPUT:-outputs/Conf32323264beta6.0-gf05hb40flow200.ildg}"
output="${VLQCD_RENDER_OUTPUT:-outputs/plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn.mp4}"
orbit_turns="${VLQCD_CAMERA_ORBIT_TURNS:-1.0}"
nloops="${VLQCD_RENDER_NLOOPS:-6}"
framerate="${VLQCD_RENDER_FRAMERATE:-14}"
slice_hold_frames="${VLQCD_SLICE_HOLD_FRAMES:-2}"
figure_size="${VLQCD_FIGURE_SIZE:-480}"
preflight="${VLQCD_PREFLIGHT_DIAGNOSE:-1}"
preflight_loader="${VLQCD_PREFLIGHT_LOADER:-ildg}"
preflight_temp_count="${VLQCD_PREFLIGHT_TEMP_COUNT:-4}"

cd "$workdir"
mkdir -p logs outputs

system_depots="$("$julia_bin" "$julia_channel" --startup-file=no -e 'print(join(DEPOT_PATH[2:end], Sys.iswindows() ? ";" : ":"))')"
export JULIA_DEPOT_PATH="${VLQCD_JULIA_DEPOT_PATH:-$depot:$system_depots}"

echo "workdir=$workdir"
echo "julia=$julia_bin $julia_channel"
echo "JULIA_DEPOT_PATH=$JULIA_DEPOT_PATH"
echo "log=$log"
echo "preflight_log=$preflight_log"
echo "input=$input"
echo "output=$output"
echo "camera_orbit_turns=$orbit_turns"
echo "nloops=$nloops"
echo "framerate=$framerate"
echo "slice_hold_frames=$slice_hold_frames"
echo "figure_size=$figure_size"
echo "preflight=$preflight"

if [[ "$preflight" != "0" ]]; then
  "$julia_bin" "$julia_channel" --project=. --startup-file=no \
    scripts/yitp_sample/diagnose_action_density.jl \
    --loader "$preflight_loader" \
    --nx 32 --ny 32 --nz 32 --nt 64 --nc 3 \
    --input "$input" \
    --temp-count "$preflight_temp_count" \
    --skip-plane-stats \
    --fail-on-contamination \
    > "$preflight_log" 2>&1
  tail -n 80 "$preflight_log"
fi

nohup "$julia_bin" "$julia_channel" --project=. --startup-file=no \
  scripts/yitp_sample/render_large_sample.jl \
  --nx 32 --ny 32 --nz 32 --nt 64 --nc 3 --beta 6.0 \
  --input "$input" \
  --output "$output" \
  --camera-orbit-turns "$orbit_turns" \
  --nloops "$nloops" \
  --framerate "$framerate" \
  --slice-hold-frames "$slice_hold_frames" \
  --figure-size "$figure_size" \
  > "$log" 2>&1 &

echo "pid=$!"
