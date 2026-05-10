#!/usr/bin/env julia

using VisualizingLQCD
using GLMakie
using Printf

const DEFAULT_OUTPUT_DIR = "/private/tmp/VisualizingLQCD-su2-instanton-fixtures"
const DEFAULT_FIXTURE_CASE_SET = "basic"
const DEFAULT_FIXTURE_LATTICE = (24, 24, 24, 24)
const DEFAULT_STYLE_PRESET = VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_WIDE
const ALL_STYLE_PRESET = :all
const REVIEW_STYLE_PRESETS = (
    VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_BALANCED,
    VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_WIDE,
    VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_CORE,
)
const RENDER_MODE_CONTOUR = :contour
const RENDER_MODE_VOLUME = :volume
const RENDER_MODE_BOTH = :both
const TOPOLOGY_VOLUME_POSITIVE_COLOR = RGBAf(1.0, 0.82, 0.0, 1.0)
const TOPOLOGY_VOLUME_NEGATIVE_COLOR = RGBAf(0.0, 0.78, 1.0, 1.0)

function parse_style_preset(raw)
    preset = Symbol(raw)
    preset == ALL_STYLE_PRESET && return preset
    return VisualizingLQCD.validate_topological_charge_style_preset(preset)
end

function parse_quantile_list(raw, option_name)
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

function parse_case_set(raw)
    raw in ("basic", "debug", "all") ||
        throw(ArgumentError("--case-set should be one of: basic, debug, all"))
    return raw
end

function parse_render_mode(raw)
    mode = Symbol(raw)
    mode in (RENDER_MODE_CONTOUR, RENDER_MODE_VOLUME, RENDER_MODE_BOTH) ||
        throw(ArgumentError("--render-mode should be one of: contour, volume, both"))
    return mode
end

function parse_args(args)
    output_dir = DEFAULT_OUTPUT_DIR
    frames = 36
    framerate = 12
    render_movies = true
    case_set = DEFAULT_FIXTURE_CASE_SET
    style_preset = DEFAULT_STYLE_PRESET
    render_mode = RENDER_MODE_CONTOUR
    level_quantiles = nothing
    color_quantile = nothing
    render_alpha = nothing
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--output-dir"
            i += 1
            i <= length(args) || throw(ArgumentError("--output-dir requires a value"))
            output_dir = args[i]
        elseif arg == "--frames"
            i += 1
            i <= length(args) || throw(ArgumentError("--frames requires a value"))
            frames = parse(Int, args[i])
        elseif arg == "--framerate"
            i += 1
            i <= length(args) || throw(ArgumentError("--framerate requires a value"))
            framerate = parse(Int, args[i])
        elseif arg == "--no-movie"
            render_movies = false
        elseif arg == "--case-set"
            i += 1
            i <= length(args) || throw(ArgumentError("--case-set requires a value"))
            case_set = parse_case_set(args[i])
        elseif arg == "--style-preset"
            i += 1
            i <= length(args) || throw(ArgumentError("--style-preset requires a value"))
            style_preset = parse_style_preset(args[i])
        elseif arg == "--render-mode"
            i += 1
            i <= length(args) || throw(ArgumentError("--render-mode requires a value"))
            render_mode = parse_render_mode(args[i])
        elseif arg == "--level-quantiles"
            i += 1
            i <= length(args) || throw(ArgumentError("--level-quantiles requires a value"))
            level_quantiles = parse_quantile_list(args[i], "--level-quantiles")
        elseif arg == "--color-quantile"
            i += 1
            i <= length(args) || throw(ArgumentError("--color-quantile requires a value"))
            color_quantile = only(parse_quantile_list(args[i], "--color-quantile"))
        elseif arg == "--alpha"
            i += 1
            i <= length(args) || throw(ArgumentError("--alpha requires a value"))
            render_alpha = parse(Float64, args[i])
            0 <= render_alpha <= 1 ||
                throw(ArgumentError("--alpha should be between 0 and 1"))
        else
            throw(ArgumentError("unsupported argument: $arg"))
        end
        i += 1
    end
    frames > 0 || throw(ArgumentError("--frames should be positive"))
    framerate > 0 || throw(ArgumentError("--framerate should be positive"))
    return (output_dir=output_dir, frames=frames, framerate=framerate,
        render_movies=render_movies, case_set=case_set, style_preset=style_preset,
        render_mode=render_mode,
        level_quantiles_override=level_quantiles,
        color_quantile_override=color_quantile,
        render_alpha_override=render_alpha)
end

function resolve_render_options(options, style_preset;
    output_dir=options.output_dir, render_mode=options.render_mode)

    preset_settings = VisualizingLQCD.topological_charge_style_preset_settings(style_preset)
    return (output_dir=output_dir, frames=options.frames, framerate=options.framerate,
        render_movies=options.render_movies, case_set=options.case_set,
        style_preset=style_preset, render_mode=render_mode,
        level_quantiles=something(
            options.level_quantiles_override, preset_settings.level_quantiles),
        color_quantile=something(
            options.color_quantile_override, preset_settings.color_quantile),
        render_alpha=something(options.render_alpha_override, preset_settings.alpha))
end

function instanton_case(name; lattice, rho, center, charge_sign, description)
    return (
        name=name,
        slice4=Int(round(center[4])),
        description=description,
        density=VisualizingLQCD.su2_instanton_topological_density(lattice;
            rho=rho, center=center, charge_sign=charge_sign),
        fixture_metadata=VisualizingLQCD.su2_instanton_fixture_metadata(lattice;
            rho=rho, center=center, charge_sign=charge_sign),
    )
end

function diga_case(name, lumps; lattice, slice4, description)
    return (
        name=name,
        slice4=slice4,
        description=description,
        density=VisualizingLQCD.su2_diga_topological_density(lattice, lumps),
        fixture_metadata=VisualizingLQCD.su2_diga_fixture_metadata(lattice, lumps),
    )
end

function basic_fixture_cases(lattice)
    return [
        instanton_case("single-plus-centered";
            lattice=lattice,
            rho=2.4,
            center=(12, 12, 12, 12),
            charge_sign=1,
            description="positive centered rho=2.4 reference lump"),
        instanton_case("single-minus-centered";
            lattice=lattice,
            rho=2.4,
            center=(12, 12, 12, 12),
            charge_sign=-1,
            description="negative centered rho=2.4 reference lump"),
        diga_case("diga-plus-minus", [
                (rho=1.8, center=(7, 7, 7, 12), charge_sign=1),
                (rho=2.2, center=(17, 17, 17, 12), charge_sign=-1),
            ];
            lattice=lattice,
            slice4=12,
            description="qualitative plus/minus two-lump signed fixture"),
    ]
end

function debug_fixture_cases(lattice)
    return [
        basic_fixture_cases(lattice)...,
        instanton_case("single-plus-small-rho";
            lattice=lattice,
            rho=1.2,
            center=(12, 12, 12, 12),
            charge_sign=1,
            description="positive narrow lump; checks sharp core visibility"),
        instanton_case("single-plus-large-rho";
            lattice=lattice,
            rho=3.8,
            center=(12, 12, 12, 12),
            charge_sign=1,
            description="positive broad lump; checks smooth extended support"),
        instanton_case("single-plus-spatial-boundary";
            lattice=lattice,
            rho=1.8,
            center=(1, 1, 1, 12),
            charge_sign=1,
            description="positive lump crossing spatial periodic boundaries"),
        instanton_case("single-plus-off-center";
            lattice=lattice,
            rho=2.0,
            center=(8.5, 15.0, 11.5, 12.0),
            charge_sign=1,
            description="positive fractional/off-center lump for interpolation-like checks"),
        diga_case("diga-plus-plus", [
                (rho=1.6, center=(7, 8, 8, 12), charge_sign=1),
                (rho=2.4, center=(17, 16, 17, 12), charge_sign=1),
            ];
            lattice=lattice,
            slice4=12,
            description="qualitative same-sign two-lump fixture"),
        diga_case("diga-three-lump-plus-plus-minus", [
                (rho=1.5, center=(6, 7, 8, 12), charge_sign=1),
                (rho=2.0, center=(18, 16, 8, 12), charge_sign=1),
                (rho=1.8, center=(13, 14, 18, 12), charge_sign=-1),
            ];
            lattice=lattice,
            slice4=12,
            description="qualitative three-lump fixture with net charge +1"),
    ]
end

function fixture_cases(case_set)
    lattice = DEFAULT_FIXTURE_LATTICE
    case_set == "basic" && return basic_fixture_cases(lattice)
    return debug_fixture_cases(lattice)
end

function display_options_metadata(options)
    return Dict(
        "case_set" => options.case_set,
        "style_preset" => String(options.style_preset),
        "render_mode" => String(options.render_mode),
        "level_quantiles" => collect(options.level_quantiles),
        "color_quantile" => options.color_quantile,
        "render_alpha" => options.render_alpha,
        "lattice_size" => collect(DEFAULT_FIXTURE_LATTICE),
    )
end

function combined_options_metadata(options, style_presets)
    return Dict(
        "case_set" => options.case_set,
        "style_preset" => String(options.style_preset),
        "style_presets" => [String(style_preset) for style_preset in style_presets],
        "render_mode" => String(options.render_mode),
        "level_quantiles_override" => options.level_quantiles_override === nothing ?
                                      nothing : collect(options.level_quantiles_override),
        "color_quantile_override" => options.color_quantile_override,
        "render_alpha_override" => options.render_alpha_override,
        "lattice_size" => collect(DEFAULT_FIXTURE_LATTICE),
    )
end

function render_modes(render_mode)
    render_mode == RENDER_MODE_BOTH && return (RENDER_MODE_CONTOUR, RENDER_MODE_VOLUME)
    return (render_mode,)
end

function axis_kwargs(title)
    return (
        xlabel="x",
        ylabel="y",
        zlabel="z",
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
        perspectiveness=VisualizingLQCD.CURRENT_CAMERA_ORBIT_PERSPECTIVENESS,
        viewmode=VisualizingLQCD.CURRENT_CAMERA_ORBIT_VIEWMODE,
    )
end

function render_contour_case(case, output_dir, options)
    density = case.density
    nx, ny, nz, _ = size(density)
    setup = VisualizingLQCD.topological_charge_display_level_setup(density;
        style_preset=options.style_preset,
        level_quantiles=options.level_quantiles,
        color_quantile=options.color_quantile,
        render_alpha=options.render_alpha)
    diagnostics = VisualizingLQCD.topological_density_fixture_diagnostics(density)

    @printf("rendering %-34s slice4=%d levels=%d\n",
        case.name, case.slice4, length(setup.levels))

    fig = Figure(size=(560, 560), backgroundcolor=:black)
    ax = Axis3(fig[1, 1]; axis_kwargs(case.name)...)
    limits!(ax, 1, nx, 1, ny, 1, nz)
    for spec in VisualizingLQCD.contour_plot_specs(setup.contour_style, setup.levels)
        contour_kwargs = VisualizingLQCD.contour_plot_kwargs(spec.style, spec.levels)
        GLMakie.contour!(ax, (1.0, Float64(nx)), (1.0, Float64(ny)), (1.0, Float64(nz)),
            @view(density[:, :, :, case.slice4]); contour_kwargs...)
    end

    png_path = joinpath(output_dir, "$(case.name).png")
    save(png_path, fig)

    mp4_path = joinpath(output_dir, "$(case.name).mp4")
    if options.render_movies
        record(fig, mp4_path, 1:options.frames; framerate=options.framerate) do frame
            ax.azimuth[] = VisualizingLQCD.CURRENT_CAMERA_AZIMUTH +
                           2pi * (frame - 1) / options.frames
        end
    else
        mp4_path = nothing
    end

    return (
        style_preset=String(options.style_preset),
        render_mode=String(RENDER_MODE_CONTOUR),
        name=case.name,
        description=case.description,
        slice4=case.slice4,
        png=png_path,
        mp4=mp4_path,
        levels=setup.levels,
        color_range=setup.render_style_info["color_range"],
        diagnostics=diagnostics,
        fixture_metadata=case.fixture_metadata,
    )
end

function smallest_positive_level(levels)
    positive_levels = [level for level in levels if level > 0]
    isempty(positive_levels) && return nothing
    return minimum(positive_levels)
end

function smallest_negative_magnitude_level(levels)
    negative_levels = [-level for level in levels if level < 0]
    isempty(negative_levels) && return nothing
    return minimum(negative_levels)
end

function constant_color_geometry(geometry, color)
    return (mesh=geometry.mesh, colors=fill(color, length(geometry.colors)),
        info=geometry.info)
end

function topology_volume_geometry(data, body_level; a, lattice_size)
    body_level === nothing && return nothing
    render_field = VisualizingLQCD.smooth_periodic_3d(data)
    maximum(render_field) > body_level || return nothing
    count(>=(body_level), render_field) > 0 || return nothing
    setup = (body_level=body_level, color_range=(body_level, maximum(render_field)))
    return VisualizingLQCD.action_density_blob_geometry(render_field, setup;
        a=a, lattice_size=lattice_size)
end

function plot_constant_geometry!(ax, geometry, color)
    recolored = constant_color_geometry(geometry, color)
    return mesh!(ax, recolored.mesh; color=recolored.colors,
        shading=FastShading, transparency=false), recolored.info
end

function render_volume_case(case, output_dir, options)
    density = case.density
    nx, ny, nz, _ = size(density)
    setup = VisualizingLQCD.topological_charge_display_level_setup(density;
        style_preset=options.style_preset,
        level_quantiles=options.level_quantiles,
        color_quantile=options.color_quantile,
        render_alpha=options.render_alpha)
    diagnostics = VisualizingLQCD.topological_density_fixture_diagnostics(density)

    positive_level = smallest_positive_level(setup.levels)
    negative_level = smallest_negative_magnitude_level(setup.levels)
    @printf("rendering %-34s slice4=%d mode=volume levels=%d\n",
        case.name, case.slice4, length(setup.levels))

    fig = Figure(size=(560, 560), backgroundcolor=:black)
    ax = Axis3(fig[1, 1]; axis_kwargs("volume / $(case.name)")...)
    limits!(ax, 1, nx, 1, ny, 1, nz)
    density_slice = @view density[:, :, :, case.slice4]
    volume_info = Dict{String,Any}(
        "positive_body_level" => positive_level,
        "negative_body_level" => negative_level,
        "positive_info" => nothing,
        "negative_info" => nothing,
    )

    positive_data = max.(density_slice, 0.0)
    positive_geometry = topology_volume_geometry(positive_data, positive_level;
        a=1.0, lattice_size=(nx, ny, nz))
    if positive_geometry !== nothing
        _, info = plot_constant_geometry!(
            ax, positive_geometry, TOPOLOGY_VOLUME_POSITIVE_COLOR)
        volume_info["positive_info"] = info
    end

    negative_data = max.(-density_slice, 0.0)
    negative_geometry = topology_volume_geometry(negative_data, negative_level;
        a=1.0, lattice_size=(nx, ny, nz))
    if negative_geometry !== nothing
        _, info = plot_constant_geometry!(
            ax, negative_geometry, TOPOLOGY_VOLUME_NEGATIVE_COLOR)
        volume_info["negative_info"] = info
    end

    png_path = joinpath(output_dir, "$(case.name).png")
    save(png_path, fig)

    mp4_path = joinpath(output_dir, "$(case.name).mp4")
    if options.render_movies
        record(fig, mp4_path, 1:options.frames; framerate=options.framerate) do frame
            ax.azimuth[] = VisualizingLQCD.CURRENT_CAMERA_AZIMUTH +
                           2pi * (frame - 1) / options.frames
        end
    else
        mp4_path = nothing
    end

    return (
        style_preset=String(options.style_preset),
        render_mode=String(RENDER_MODE_VOLUME),
        name=case.name,
        description=case.description,
        slice4=case.slice4,
        png=png_path,
        mp4=mp4_path,
        levels=setup.levels,
        color_range=setup.render_style_info["color_range"],
        diagnostics=diagnostics,
        fixture_metadata=case.fixture_metadata,
        volume_info=volume_info,
    )
end

function render_case(case, output_dir, options)
    if options.render_mode == RENDER_MODE_CONTOUR
        return render_contour_case(case, output_dir, options)
    elseif options.render_mode == RENDER_MODE_VOLUME
        return render_volume_case(case, output_dir, options)
    else
        throw(ArgumentError("unsupported render_mode: $(options.render_mode)"))
    end
end

function html_path_for(path, output_dir)
    return replace(relpath(path, output_dir), "\\" => "/")
end

function html_escape(value)
    text = string(value)
    text = replace(text, "&" => "&amp;")
    text = replace(text, "<" => "&lt;")
    text = replace(text, ">" => "&gt;")
    text = replace(text, "\"" => "&quot;")
    return replace(text, "'" => "&#39;")
end

function review_label(result)
    if result.render_mode == String(RENDER_MODE_CONTOUR)
        return "$(result.style_preset) / $(result.name)"
    end
    return "$(result.style_preset) / $(result.render_mode) / $(result.name)"
end

function write_review_controls(io, result)
    label = html_escape(review_label(result))
    write(io, """
<div class="review-controls">
<div class="review-label">Visual check</div>
<label><input type="checkbox" data-kind="visible"> visible</label>
<label><input type="checkbox" data-kind="missing"> not visible</label>
<label><input type="checkbox" data-kind="good"> good</label>
<label><input type="checkbox" data-kind="shell"> shell/hollow</label>
<label><input type="checkbox" data-kind="needs-work"> needs work</label>
<input class="review-note" type="text" data-note placeholder="short note for $label">
</div>
""")
end

function write_review_script(io)
    write(io, """
<script>
(() => {
  const reviewRoot = document.querySelector("[data-review-session]");
  const reviewSession = reviewRoot ? reviewRoot.dataset.reviewSession : "unknown";
  const storageKey = "VisualizingLQCD:topology-fixture-review:" + location.pathname + ":" + reviewSession;
  const output = document.getElementById("review-output");
  const copyButton = document.getElementById("copy-review");
  const clearButton = document.getElementById("clear-review");
  const cards = Array.from(document.querySelectorAll("[data-review-card]"));

  function loadState() {
    try {
      return JSON.parse(localStorage.getItem(storageKey) || "{}");
    } catch {
      return {};
    }
  }

  function saveState(state) {
    localStorage.setItem(storageKey, JSON.stringify(state));
  }

  function cardState(card) {
    const checks = {};
    card.querySelectorAll("input[type=checkbox][data-kind]").forEach((checkbox) => {
      checks[checkbox.dataset.kind] = checkbox.checked;
    });
    return {
      checks,
      note: card.querySelector("[data-note]").value.trim(),
    };
  }

  function applyState(state) {
    cards.forEach((card) => {
      const item = state[card.dataset.reviewId] || {};
      card.querySelectorAll("input[type=checkbox][data-kind]").forEach((checkbox) => {
        checkbox.checked = Boolean(item.checks && item.checks[checkbox.dataset.kind]);
      });
      const note = card.querySelector("[data-note]");
      note.value = item.note || "";
    });
  }

  function collectState() {
    const state = {};
    cards.forEach((card) => {
      state[card.dataset.reviewId] = cardState(card);
    });
    return state;
  }

  function renderOutput() {
    const lines = [
      "# VisualizingLQCD topological-density fixture visual check",
      "",
      "source: " + location.href,
      "session: " + reviewSession,
      "updated: " + new Date().toISOString(),
      "",
    ];
    let itemCount = 0;
    cards.forEach((card) => {
      const state = cardState(card);
      const active = Object.entries(state.checks)
        .filter(([, checked]) => checked)
        .map(([kind]) => kind);
      if (active.length > 0 || state.note.length > 0) {
        itemCount += 1;
        const status = active.length > 0 ? active.join(", ") : "note";
        const note = state.note.length > 0 ? " | note: " + state.note : "";
        lines.push("- " + card.dataset.reviewLabel + ": " + status + note);
      }
    });
    if (itemCount === 0) {
      lines.push("- no visual checks selected yet");
    }
    output.value = lines.join("\\n");
    saveState(collectState());
  }

  document.addEventListener("input", renderOutput);
  document.addEventListener("change", renderOutput);
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
    cards.forEach((card) => {
      card.querySelectorAll("input[type=checkbox][data-kind]").forEach((checkbox) => {
        checkbox.checked = false;
      });
      card.querySelector("[data-note]").value = "";
    });
    localStorage.removeItem(storageKey);
    renderOutput();
  });

  applyState(loadState());
  renderOutput();
})();
</script>
""")
end

function write_view_html(output_dir, results, metadata; title="SU2 instanton topology fixture smoke")
    path = joinpath(output_dir, "view.html")
    open(path, "w") do io
        escaped_title = html_escape(title)
        review_session_id = string(round(Int, 1000 * time()))
        write(io, """
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>$escaped_title</title>
<style>
body { margin: 0; background: #101010; color: #f4f4f4; font-family: sans-serif; }
main { padding: 24px 24px 320px; display: grid; gap: 24px; }
.review-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(520px, 1fr)); gap: 22px; }
.review-card { border-top: 1px solid #444; padding-top: 18px; }
.review-card h2 { font-size: 18px; margin: 0 0 8px; }
.preset { color: #a7d8ff; font-weight: 700; }
.media-row { display: grid; grid-template-columns: minmax(280px, 420px) minmax(180px, 1fr); gap: 16px; align-items: start; }
img, video { width: 420px; max-width: 100%; background: #000; display: block; margin-bottom: 12px; }
pre { white-space: pre-wrap; color: #ddd; }
.review-controls { display: grid; gap: 9px; background: #181818; border: 1px solid #333; padding: 12px; }
.review-controls label { display: flex; align-items: center; gap: 8px; }
.review-label { font-weight: 700; color: #ddd; }
.review-note { background: #0b0b0b; color: #f4f4f4; border: 1px solid #555; padding: 8px; }
details { margin-top: 12px; }
summary { cursor: pointer; color: #ccc; }
.review-output-panel { position: fixed; left: 0; right: 0; bottom: 0; background: #151515; border-top: 1px solid #555; padding: 14px 24px; box-shadow: 0 -8px 24px rgba(0, 0, 0, 0.45); }
.review-output-panel h2 { margin: 0 0 8px; font-size: 18px; }
#review-output { width: 100%; height: 170px; box-sizing: border-box; background: #050505; color: #f4f4f4; border: 1px solid #555; padding: 10px; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
#copy-review { margin-top: 8px; padding: 8px 12px; background: #2d6cdf; color: white; border: 0; border-radius: 4px; cursor: pointer; }
#clear-review { margin-top: 8px; margin-left: 8px; padding: 8px 12px; background: #444; color: white; border: 0; border-radius: 4px; cursor: pointer; }
</style>
</head>
<body>
<main data-review-session="$review_session_id">
<h1>$escaped_title</h1>
""")
        write(io, "<pre>")
        write(io, "display_options = $(metadata)\n")
        write(io, "</pre>\n<div class=\"review-grid\">\n")
        for result in results
            label = review_label(result)
            escaped_label = html_escape(label)
            escaped_preset = html_escape(result.style_preset)
            escaped_name = html_escape(result.name)
            escaped_description = html_escape(result.description)
            png_path = html_escape(html_path_for(result.png, output_dir))
            write(io, """
<section class="review-card" data-review-card data-review-id="$escaped_label" data-review-label="$escaped_label">
<h2><span class="preset">$escaped_preset</span> / $escaped_name</h2>
<p>$escaped_description</p>
<div class="media-row">
<div>
<img src="$png_path" alt="$escaped_label still">
""")
            if result.mp4 !== nothing
                mp4_path = html_escape(html_path_for(result.mp4, output_dir))
                write(io, "<video src=\"$mp4_path\" controls loop muted></video>\n")
            end
            write(io, "</div>\n")
            write_review_controls(io, result)
            write(io, "</div>\n<details>\n<summary>metadata</summary>\n")
            write(io, "<pre>")
            write(io, "slice4 = $(result.slice4)\n")
            write(io, "levels = $(result.levels)\n")
            write(io, "color_range = $(result.color_range)\n")
            write(io, "diagnostics = $(result.diagnostics)\n")
            write(io, "fixture_metadata = $(result.fixture_metadata)\n")
            if hasproperty(result, :volume_info)
                write(io, "volume_info = $(result.volume_info)\n")
            end
            write(io, "</pre>\n</details>\n</section>\n")
        end
        write(io, """
</div>
</main>
<section class="review-output-panel">
<h2>Copyable review text</h2>
<textarea id="review-output" readonly></textarea>
<button id="copy-review" type="button">Copy review text</button>
<button id="clear-review" type="button">Clear checks</button>
</section>
""")
        write_review_script(io)
        write(io, """
</body>
</html>
""")
    end
    return path
end

function render_cases(cases, output_dir, options)
    mkpath(output_dir)
    return [render_case(case, output_dir, options) for case in cases]
end

function review_output_dir(base_dir, style_preset, render_mode, all_styles, all_modes)
    parts = String[]
    all_modes && push!(parts, String(render_mode))
    all_styles && push!(parts, String(style_preset))
    isempty(parts) && return base_dir
    return joinpath(base_dir, parts...)
end

function main(args=ARGS)
    options = parse_args(args)
    mkpath(options.output_dir)
    GLMakie.activate!()
    cases = fixture_cases(options.case_set)
    modes = render_modes(options.render_mode)
    all_modes = length(modes) > 1
    if options.style_preset == ALL_STYLE_PRESET
        all_results = []
        for render_mode in modes, style_preset in REVIEW_STYLE_PRESETS
            style_output_dir = review_output_dir(
                options.output_dir, style_preset, render_mode, true, all_modes)
            style_options = resolve_render_options(options, style_preset;
                output_dir=style_output_dir, render_mode=render_mode)
            append!(all_results, render_cases(cases, style_output_dir, style_options))
        end
        view_html = write_view_html(
            options.output_dir, all_results,
            combined_options_metadata(options, REVIEW_STYLE_PRESETS);
            title="SU2 instanton topology fixture smoke review")
    else
        all_results = []
        for render_mode in modes
            mode_output_dir = review_output_dir(
                options.output_dir, options.style_preset, render_mode, false, all_modes)
            style_options = resolve_render_options(options, options.style_preset;
                output_dir=mode_output_dir, render_mode=render_mode)
            append!(all_results, render_cases(cases, mode_output_dir, style_options))
        end
        view_html = write_view_html(options.output_dir, all_results,
            display_options_metadata(resolve_render_options(options, options.style_preset)))
    end
    println("wrote $(view_html)")
    return view_html
end

main()
