#!/usr/bin/env julia

using VisualizingLQCD
using Printf

const RENDER_MODE_CONTOUR = :contour
const RENDER_MODE_VOLUME = :volume
const RENDER_MODE_BOTH = :both

function arg_value(args, name, default)
    flag = "--$name"
    index = findfirst(==(flag), args)
    index === nothing && return default
    index < length(args) || error("missing value after $flag")
    return args[index + 1]
end

function parse_render_mode(raw)
    mode = Symbol(raw)
    mode in (RENDER_MODE_CONTOUR, RENDER_MODE_VOLUME, RENDER_MODE_BOTH) ||
        throw(ArgumentError("--render-mode should be one of: contour, volume, both"))
    return mode
end

function render_modes(mode)
    mode == RENDER_MODE_BOTH && return (RENDER_MODE_CONTOUR, RENDER_MODE_VOLUME)
    return (mode,)
end

function render_style_for_mode(mode)
    if mode == RENDER_MODE_VOLUME
        return VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME
    elseif mode == RENDER_MODE_CONTOUR
        return VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED
    else
        throw(ArgumentError("unsupported render mode: $mode"))
    end
end

function parse_style_preset(raw)
    return VisualizingLQCD.validate_topological_charge_style_preset(Symbol(raw))
end

function parse_optional_quantiles(raw, option_name)
    isempty(raw) && return nothing
    values = Float64[]
    for part in split(raw, ",")
        value = parse(Float64, strip(part))
        0 <= value <= 1 ||
            throw(ArgumentError("$option_name entries should be between 0 and 1"))
        push!(values, value)
    end
    isempty(values) && throw(ArgumentError("$option_name requires at least one value"))
    return Tuple(values)
end

function parse_optional_float(raw)
    isempty(raw) && return nothing
    return parse(Float64, raw)
end

function parse_optional_int(raw)
    isempty(raw) && return nothing
    return parse(Int, raw)
end

function parse_bool(raw, option_name)
    lowered = lowercase(raw)
    lowered == "true" && return true
    lowered == "false" && return false
    throw(ArgumentError("$option_name should be true or false"))
end

function parse_frame_mode(raw)
    if raw in ("sequence", "slice4_sequence")
        return VisualizingLQCD.FRAME_MODE_SEQUENCE
    elseif raw in ("fixed", "fixed_slice4")
        return VisualizingLQCD.FRAME_MODE_FIXED
    end
    throw(ArgumentError("--frame-mode should be sequence or fixed"))
end

function parse_camera_motion(raw)
    if raw == "orbit"
        return VisualizingLQCD.CAMERA_MOTION_ORBIT
    elseif raw == "static"
        return VisualizingLQCD.CAMERA_MOTION_STATIC
    end
    throw(ArgumentError("--camera-motion should be orbit or static"))
end

function html_escape(value)
    text = string(value)
    text = replace(text, "&" => "&amp;")
    text = replace(text, "<" => "&lt;")
    text = replace(text, ">" => "&gt;")
    text = replace(text, "\"" => "&quot;")
    return replace(text, "'" => "&#39;")
end

function html_path_for(path, output_dir)
    return replace(relpath(path, output_dir), "\\" => "/")
end

function output_video_path(options, mode)
    stem, ext = splitext(options.output_name)
    effective_ext = isempty(ext) ? ".mp4" : ext
    effective_stem = options.render_mode == RENDER_MODE_BOTH ?
                     "$(stem)-$(String(mode))" : stem
    return joinpath(options.output_dir, "$effective_stem$effective_ext")
end

function render_movie(mode, options)
    video_path = output_video_path(options, mode)
    metadata_path = string(video_path, ".metadata.json")
    @printf("rendering topological-density %-7s movie -> %s\n", String(mode), video_path)
    result = VisualizingLQCD.create_animation(
        options.nx, options.ny, options.nz, options.nt, options.nc, video_path;
        beta=options.beta,
        filename=options.input,
        metadata_filename=metadata_path,
        level_target=VisualizingLQCD.LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY,
        topological_level_quantiles=options.level_quantiles,
        topological_color_quantile=options.color_quantile,
        topological_style_preset=options.style_preset,
        render_style=render_style_for_mode(mode),
        render_alpha=options.render_alpha,
        render_theme=VisualizingLQCD.RENDER_THEME_DARK,
        cache_render_slices=options.cache_render_slices,
        figure_size=(options.figure_size, options.figure_size),
        framerate=options.framerate,
        nloops=options.nloops,
        frame_mode=options.frame_mode,
        fixed_slice4=options.fixed_slice4,
        slice_hold_frames=options.slice_hold_frames,
        camera_motion=options.camera_motion,
        camera_orbit_turns=options.camera_orbit_turns,
        camera_orbit_seconds=options.camera_orbit_seconds,
        show_axis_labels=options.show_axis_labels,
        show_render_progress=options.show_render_progress)
    return (
        label="$(String(mode)) movie",
        mode=String(mode),
        video=result.video,
        metadata=result.metadata,
        metadata_text=read(result.metadata, String),
    )
end

function options_summary_text(options)
    return join((
        "input = $(options.input)",
        "lattice_size = $((options.nx, options.ny, options.nz, options.nt))",
        "render_mode = $(String(options.render_mode))",
        "style_preset = $(String(options.style_preset))",
        "frame_mode = $(String(options.frame_mode))",
        "camera_motion = $(String(options.camera_motion))",
        "show_axis_labels = $(options.show_axis_labels)",
    ), "\n")
end

function write_review_script(io)
    write(io, """
<script>
(() => {
  const root = document.querySelector("[data-review-session]");
  const session = root ? root.dataset.reviewSession : "unknown";
  const storageKey = "VisualizingLQCD:topology-config-movie-review:" + location.pathname + ":" + session;
  const cards = Array.from(document.querySelectorAll("[data-review-card]"));
  const output = document.getElementById("review-output");
  const copyButton = document.getElementById("copy-review");
  const clearButton = document.getElementById("clear-review");

  function loadState() {
    try { return JSON.parse(localStorage.getItem(storageKey) || "{}"); }
    catch { return {}; }
  }
  function saveState(state) {
    localStorage.setItem(storageKey, JSON.stringify(state));
  }
  function cardState(card) {
    const checks = {};
    card.querySelectorAll("input[type=checkbox][data-kind]").forEach((checkbox) => {
      checks[checkbox.dataset.kind] = checkbox.checked;
    });
    return { checks, note: card.querySelector("[data-note]").value };
  }
  function collectState() {
    const state = {};
    cards.forEach((card) => { state[card.dataset.reviewId] = cardState(card); });
    return state;
  }
  function applyState(state) {
    cards.forEach((card) => {
      const saved = state[card.dataset.reviewId] || { checks: {}, note: "" };
      card.querySelectorAll("input[type=checkbox][data-kind]").forEach((checkbox) => {
        checkbox.checked = Boolean(saved.checks && saved.checks[checkbox.dataset.kind]);
      });
      card.querySelector("[data-note]").value = saved.note || "";
    });
  }
  function renderOutput() {
    const lines = [
      "# VisualizingLQCD topological-density config movie visual check",
      "",
      "source: " + location.href,
      "session: " + session,
      "updated: " + new Date().toISOString(),
      "",
    ];
    cards.forEach((card) => {
      const state = cardState(card);
      const flags = Object.entries(state.checks).filter(([, checked]) => checked).map(([kind]) => kind);
      const note = state.note.trim();
      if (flags.length || note.length) {
        const status = flags.length ? flags.join(", ") : "note";
        lines.push("- " + card.dataset.reviewLabel + ": " + status +
          (note.length ? " | note: " + note : ""));
      }
    });
    output.value = lines.join("\\n");
  }
  function persistAndRender() {
    saveState(collectState());
    renderOutput();
  }
  cards.forEach((card) => {
    card.querySelectorAll("input, [data-note]").forEach((input) => {
      input.addEventListener("change", persistAndRender);
      input.addEventListener("input", persistAndRender);
    });
  });
  copyButton.addEventListener("click", async () => {
    output.focus();
    output.select();
    try {
      await navigator.clipboard.writeText(output.value);
      copyButton.textContent = "Copied";
      setTimeout(() => { copyButton.textContent = "Copy review text"; }, 1200);
    } catch {
      document.execCommand("copy");
    }
  });
  clearButton.addEventListener("click", () => {
    localStorage.removeItem(storageKey);
    cards.forEach((card) => {
      card.querySelectorAll("input[type=checkbox][data-kind]").forEach((checkbox) => {
        checkbox.checked = false;
      });
      card.querySelector("[data-note]").value = "";
    });
    renderOutput();
  });
  applyState(loadState());
  renderOutput();
})();
</script>
""")
end

function write_review_html(output_dir, results, options)
    path = joinpath(output_dir, "view.html")
    review_session_id = string(round(Int, 1000 * time()))
    summary_text = html_escape(options_summary_text(options))
    open(path, "w") do io
        write(io, """
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>VisualizingLQCD topological-density config movie review</title>
<style>
body { margin: 0; background: #101010; color: #f4f4f4; font-family: sans-serif; }
main { padding: 24px 24px 320px; display: grid; gap: 24px; }
.review-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(560px, 1fr)); gap: 22px; }
.review-card { border-top: 1px solid #444; padding-top: 18px; }
.review-card h2 { font-size: 18px; margin: 0 0 8px; }
.media-row { display: grid; grid-template-columns: minmax(280px, 560px) minmax(180px, 1fr); gap: 16px; align-items: start; }
video, img { width: 560px; max-width: 100%; background: #000; display: block; margin-bottom: 12px; }
pre { white-space: pre-wrap; color: #ddd; overflow-x: auto; }
.review-controls { display: grid; gap: 9px; background: #181818; border: 1px solid #333; padding: 12px; }
.review-controls label { display: flex; align-items: center; gap: 8px; }
.review-note { background: #0b0b0b; color: white; border: 1px solid #555; padding: 7px; }
.review-output { position: fixed; left: 0; right: 0; bottom: 0; background: #181818; border-top: 1px solid #444; padding: 14px 20px; }
.review-output textarea { width: 100%; height: 180px; background: #050505; color: #eaeaea; border: 1px solid #555; padding: 10px; }
.review-output button { margin-top: 8px; margin-right: 8px; padding: 8px 12px; }
</style>
</head>
<body>
<main data-review-session="$review_session_id">
<h1>VisualizingLQCD topological-density config movie review</h1>
<pre>$summary_text</pre>
<div class="review-grid">
""")
        for result in results
            label = html_escape(result.label)
            video_path = html_escape(html_path_for(result.video, output_dir))
            metadata_path = html_escape(html_path_for(result.metadata, output_dir))
            metadata_text = html_escape(result.metadata_text)
            write(io, """
<section class="review-card" data-review-card data-review-id="$label" data-review-label="$label">
<h2>$label</h2>
<div class="media-row">
<div>
<video controls muted loop playsinline src="$video_path"></video>
<a href="$video_path">movie file</a> / <a href="$metadata_path">metadata</a>
</div>
<div class="review-controls">
<div>Visual check</div>
<label><input type="checkbox" data-kind="visible"> visible</label>
<label><input type="checkbox" data-kind="missing"> not visible</label>
<label><input type="checkbox" data-kind="good"> good</label>
<label><input type="checkbox" data-kind="notable / promising"> notable / promising</label>
<label><input type="checkbox" data-kind="comment only"> comment only</label>
<label><input type="checkbox" data-kind="shell"> shell/hollow</label>
<label><input type="checkbox" data-kind="needs-work"> needs work</label>
<input class="review-note" type="text" data-note placeholder="optional comment for $label; note-only rows are copied too">
</div>
</div>
<details>
<summary>metadata</summary>
<pre>$metadata_text</pre>
</details>
</section>
""")
        end
        write(io, """
</div>
</main>
<div class="review-output">
<textarea id="review-output" readonly></textarea>
<button id="copy-review">Copy review text</button>
<button id="clear-review">Clear checks</button>
</div>
""")
        write_review_script(io)
        write(io, """
</body>
</html>
""")
    end
    return path
end

function main(args=ARGS)
    options = (
        nx=parse(Int, arg_value(args, "nx", "24")),
        ny=parse(Int, arg_value(args, "ny", "24")),
        nz=parse(Int, arg_value(args, "nz", "24")),
        nt=parse(Int, arg_value(args, "nt", "32")),
        nc=parse(Int, arg_value(args, "nc", "3")),
        beta=parse(Float64, arg_value(args, "beta", "6.0")),
        input=arg_value(args, "input", "/Users/akio/Dropbox/configuration_gauge/Conf24242432beta6.0.ildg"),
        output_dir=arg_value(args, "output-dir", "/private/tmp/VisualizingLQCD-topological-config-movie-review"),
        output_name=arg_value(args, "output-name", "topological_density_config_movie.mp4"),
        render_mode=parse_render_mode(arg_value(args, "render-mode", "volume")),
        style_preset=parse_style_preset(arg_value(args, "style-preset", "balanced")),
        level_quantiles=parse_optional_quantiles(arg_value(args, "level-quantiles", ""),
            "--level-quantiles"),
        color_quantile=parse_optional_float(arg_value(args, "color-quantile", "")),
        render_alpha=parse_optional_float(arg_value(args, "alpha", "")),
        figure_size=parse(Int, arg_value(args, "figure-size", "560")),
        framerate=parse_optional_int(arg_value(args, "framerate", "")),
        nloops=parse_optional_int(arg_value(args, "nloops", "")),
        frame_mode=parse_frame_mode(arg_value(args, "frame-mode", "sequence")),
        fixed_slice4=parse(Int, arg_value(args, "fixed-slice4", "1")),
        slice_hold_frames=parse(Int, arg_value(args, "slice-hold-frames", "1")),
        camera_motion=parse_camera_motion(arg_value(args, "camera-motion", "orbit")),
        camera_orbit_turns=parse(Float64, arg_value(args, "camera-orbit-turns", "1")),
        camera_orbit_seconds=parse(Float64, arg_value(args, "camera-orbit-seconds",
            string(VisualizingLQCD.CURRENT_CAMERA_ORBIT_SECONDS))),
        cache_render_slices=parse_bool(arg_value(args, "cache-render-slices", "true"),
            "--cache-render-slices"),
        show_axis_labels=parse_bool(arg_value(args, "show-axis-labels", "true"),
            "--show-axis-labels"),
        show_render_progress=parse_bool(arg_value(args, "show-render-progress", "true"),
            "--show-render-progress"),
    )

    mkpath(options.output_dir)
    results = [render_movie(mode, options) for mode in render_modes(options.render_mode)]
    view_html = write_review_html(options.output_dir, results, options)
    println("wrote $view_html")
    return view_html
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
