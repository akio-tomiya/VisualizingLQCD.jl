#!/usr/bin/env bash
set -euo pipefail

workdir="${VLQCD_LOCAL_RENDER_DIR:-/Users/akio/VisualizingLQCD-yitp-local-render}"
julia_bin="${JULIA_BIN:-/Users/akio/.juliaup/bin/julia}"
julia_channel="${JULIA_CHANNEL:-+1.10}"
depot="${VLQCD_JULIA_DEPOT:-$workdir/.julia_depot_110_clean}"
timestamp="$(date +%Y%m%d-%H%M%S)"

cd "$workdir"
mkdir -p logs outputs "$depot"

system_depots="$("$julia_bin" "$julia_channel" --startup-file=no -e 'print(join(DEPOT_PATH[2:end], Sys.iswindows() ? ";" : ":"))')"
export JULIA_DEPOT_PATH="$depot:$system_depots"

julia_minor="$("$julia_bin" "$julia_channel" --startup-file=no -e 'print("$(VERSION.major).$(VERSION.minor)")')"
manifest_minor=""
if [[ -f Manifest.toml ]]; then
  manifest_minor="$(sed -n 's/^julia_version = "\([0-9]*\.[0-9]*\).*/\1/p' Manifest.toml | head -n 1)"
fi

if [[ -n "$manifest_minor" && "$manifest_minor" != "$julia_minor" ]]; then
  backup="Manifest.toml.before-julia${julia_minor//./}-${timestamp}"
  echo "Backing up Julia $manifest_minor manifest to $backup"
  mv Manifest.toml "$backup"
fi

echo "workdir=$workdir"
echo "julia=$julia_bin $julia_channel"
echo "JULIA_DEPOT_PATH=$JULIA_DEPOT_PATH"

"$julia_bin" "$julia_channel" --project=. --startup-file=no -e 'import Pkg; Pkg.resolve(); Pkg.instantiate(); Pkg.precompile()'
"$julia_bin" "$julia_channel" --project=. --startup-file=no -e 'using GLMakie; using VisualizingLQCD; println("studio render environment ok")'
