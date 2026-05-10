#!/usr/bin/env julia

using VisualizingLQCD
using GLMakie
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

function parse_slice_spec(raw, density; auto_count)
    _, _, _, nt = size(density)
    if raw == "auto"
        scores = [maximum(abs, @view density[:, :, :, t]) for t in 1:nt]
        order = sortperm(scores; rev=true)
        return order[1:min(auto_count, nt)]
    end
    slices = [parse(Int, strip(part)) for part in split(raw, ",")]
    all(1 <= slice4 <= nt for slice4 in slices) ||
        throw(ArgumentError("--slice4 entries should be in 1:$nt"))
    return unique(slices)
end

function render_modes(render_mode)
    render_mode == RENDER_MODE_BOTH && return (RENDER_MODE_CONTOUR, RENDER_MODE_VOLUME)
    return (render_mode,)
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

function axis_kwargs(title)
    return (
        xlabel="x [fm]",
        ylabel="y [fm]",
        zlabel="z [fm]",
        title=title,
        aspect=(1, 1, 1),
        backgroundcolor=:black,
        xlabelcolor=:white,
        ylabelcolor=:white,
        zlabelcolor=:white,
        titlecolor=:white,
        xticklabelcolor=:white,
        yticklabelcolor=:white,
        zticklabelcolor=:white,
        xtickcolor=:white,
        ytickcolor=:white,
        ztickcolor=:white,
        xgridcolor=:gray,
        ygridcolor=:gray,
        zgridcolor=:gray,
        azimuth=VisualizingLQCD.CURRENT_CAMERA_AZIMUTH,
        elevation=VisualizingLQCD.CURRENT_CAMERA_ELEVATION,
        perspectiveness=VisualizingLQCD.CURRENT_CAMERA_MESH_PERSPECTIVENESS,
        viewmode=VisualizingLQCD.CURRENT_CAMERA_ORBIT_VIEWMODE,
    )
end

function setup_for_mode(density, mode, options)
    render_style = mode == RENDER_MODE_VOLUME ?
                   VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME :
                   VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED
    return VisualizingLQCD.topological_charge_display_level_setup(density;
        style_preset=options.style_preset,
        level_quantiles=options.level_quantiles,
        color_quantile=options.color_quantile,
        render_style=render_style,
        render_alpha=options.render_alpha)
end

function render_contour_slice!(ax, data, setup, x_range, y_range, z_range)
    objects = Any[]
    for spec in VisualizingLQCD.contour_plot_specs(setup.contour_style, setup.levels)
        contour_kwargs = VisualizingLQCD.contour_plot_kwargs(spec.style, spec.levels)
        push!(objects, GLMakie.contour!(
            ax, x_range, y_range, z_range, data; contour_kwargs...))
    end
    return objects
end

function render_review_item(density, slice4, mode, output_dir, options)
    nx, ny, nz, _ = size(density)
    a = VisualizingLQCD.calculate_a(options.beta)
    x_range = (a, a * nx)
    y_range = (a, a * ny)
    z_range = (a, a * nz)
    setup = setup_for_mode(density, mode, options)
    data = @view density[:, :, :, slice4]
    suffix = "$(String(mode))-slice$(slice4)"
    png_path = joinpath(output_dir, "$suffix.png")

    @printf("rendering %-8s slice4=%d levels=%d\n", String(mode), slice4, length(setup.levels))
    fig = Figure(size=(options.figure_size, options.figure_size), backgroundcolor=:black)
    ax = Axis3(fig[1, 1]; axis_kwargs("$(String(mode)) / slice4=$slice4")...)
    limits!(ax, 0, a * nx, 0, a * ny, 0, a * nz)
    volume_info = nothing
    if mode == RENDER_MODE_VOLUME
        geometry = VisualizingLQCD.topological_charge_volume_geometry(data, setup;
            a=a, lattice_size=(nx, ny, nz))
        _, volume_info = VisualizingLQCD.topological_charge_volume_plot!(ax, geometry)
    else
        render_contour_slice!(ax, data, setup, x_range, y_range, z_range)
    end
    save(png_path, fig)
    return (
        label="$(String(mode)) / slice4=$slice4",
        mode=String(mode),
        slice4=slice4,
        png=png_path,
        levels=setup.levels,
        render_style_info=setup.render_style_info,
        volume_info=volume_info,
        slice_maximum=maximum(data),
        slice_minimum=minimum(data),
        slice_abs_maximum=maximum(abs, data),
    )
end

function write_review_script(io)
    write(io, """
<script>
(() => {
  const root = document.querySelector("[data-review-session]");
  const session = root ? root.dataset.reviewSession : "unknown";
  const storageKey = "VisualizingLQCD:topology-config-review:" + location.pathname + ":" + session;
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
      "# VisualizingLQCD topological-density config visual check",
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
        lines.push("- " + card.dataset.reviewLabel + ": " + flags.join(", ") +
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

function write_review_html(output_dir, results, metadata)
    path = joinpath(output_dir, "view.html")
    review_session_id = string(round(Int, 1000 * time()))
    open(path, "w") do io
        write(io, """
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>VisualizingLQCD topological-density config review</title>
<style>
body { margin: 0; background: #101010; color: #f4f4f4; font-family: sans-serif; }
main { padding: 24px 24px 320px; display: grid; gap: 24px; }
.review-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(520px, 1fr)); gap: 22px; }
.review-card { border-top: 1px solid #444; padding-top: 18px; }
.review-card h2 { font-size: 18px; margin: 0 0 8px; }
.media-row { display: grid; grid-template-columns: minmax(280px, 420px) minmax(180px, 1fr); gap: 16px; align-items: start; }
img { width: 420px; max-width: 100%; background: #000; display: block; margin-bottom: 12px; }
pre { white-space: pre-wrap; color: #ddd; }
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
<h1>VisualizingLQCD topological-density config review</h1>
<pre>metadata = $(metadata)</pre>
<div class="review-grid">
""")
        for result in results
            label = html_escape(result.label)
            png_path = html_escape(html_path_for(result.png, output_dir))
            write(io, """
<section class="review-card" data-review-card data-review-id="$label" data-review-label="$label">
<h2>$label</h2>
<div class="media-row">
<div><img src="$png_path" alt="$label"></div>
<div class="review-controls">
<div>Visual check</div>
<label><input type="checkbox" data-kind="visible"> visible</label>
<label><input type="checkbox" data-kind="missing"> not visible</label>
<label><input type="checkbox" data-kind="good"> good</label>
<label><input type="checkbox" data-kind="shell"> shell/hollow</label>
<label><input type="checkbox" data-kind="needs-work"> needs work</label>
<input class="review-note" type="text" data-note placeholder="short note for $label">
</div>
</div>
<details>
<summary>metadata</summary>
<pre>slice4 = $(result.slice4)
levels = $(result.levels)
render_style_info = $(result.render_style_info)
volume_info = $(result.volume_info)
slice_minimum = $(result.slice_minimum)
slice_maximum = $(result.slice_maximum)
slice_abs_maximum = $(result.slice_abs_maximum)</pre>
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

function load_topological_density(options)
    U = VisualizingLQCD.Initialize_Gaugefields(options.nc, VisualizingLQCD.CURRENT_NWING,
        options.nx, options.ny, options.nz, options.nt;
        condition=VisualizingLQCD.CURRENT_GENERATION_INITIAL_CONDITION)
    ildg = VisualizingLQCD.ILDG(options.input)
    VisualizingLQCD.load_gaugefield!(
        U, 1, ildg, [options.nx, options.ny, options.nz, options.nt], options.nc)
    return VisualizingLQCD.topological_charge_density(
        U, options.nx, options.ny, options.nz, options.nt, options.nc)
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
        output_dir=arg_value(args, "output-dir", "/private/tmp/VisualizingLQCD-topological-config-review"),
        render_mode=parse_render_mode(arg_value(args, "render-mode", "both")),
        style_preset=parse_style_preset(arg_value(args, "style-preset", "balanced")),
        level_quantiles=parse_optional_quantiles(arg_value(args, "level-quantiles", ""),
            "--level-quantiles"),
        color_quantile=parse_optional_float(arg_value(args, "color-quantile", "")),
        render_alpha=parse_optional_float(arg_value(args, "alpha", "")),
        slice4=arg_value(args, "slice4", "auto"),
        auto_slices=parse(Int, arg_value(args, "auto-slices", "4")),
        figure_size=parse(Int, arg_value(args, "figure-size", "560")),
    )

    mkpath(options.output_dir)
    density = load_topological_density(options)
    slices = parse_slice_spec(options.slice4, density; auto_count=options.auto_slices)
    modes = render_modes(options.render_mode)
    results = [
        render_review_item(density, slice4, mode, options.output_dir, options)
        for slice4 in slices for mode in modes
    ]
    metadata = Dict(
        "input" => options.input,
        "lattice_size" => [options.nx, options.ny, options.nz, options.nt],
        "nc" => options.nc,
        "beta" => options.beta,
        "render_mode" => String(options.render_mode),
        "style_preset" => String(options.style_preset),
        "slice4" => options.slice4,
        "selected_slices" => slices,
        "level_quantiles_override" => options.level_quantiles === nothing ?
                                      nothing : collect(options.level_quantiles),
        "color_quantile_override" => options.color_quantile,
        "render_alpha_override" => options.render_alpha,
        "density_minimum" => minimum(density),
        "density_maximum" => maximum(density),
        "density_abs_maximum" => maximum(abs, density),
        "total_topological_charge" => VisualizingLQCD.topological_charge_from_density(density),
    )
    view_html = write_review_html(options.output_dir, results, metadata)
    println("wrote $view_html")
    return view_html
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
