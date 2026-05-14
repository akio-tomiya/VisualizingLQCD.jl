#!/usr/bin/env julia

using VisualizingLQCD
using GLMakie
using JLD2
using Printf
using Dates
using ProgressMeter

const RENDER_MODE_CONTOUR = :contour
const RENDER_MODE_VOLUME = :volume
const RENDER_MODE_BOTH = :both

const DEFAULT_INPUT_DIR =
    "/Users/akio/repository/gaugefields_instanton_radius/results/yitp_action_scan_tau50_20260513/su2_wilson_long_flow_tau50_20260513/R3p00/q_density"

function arg_value(args, name, default)
    flag = "--$name"
    index = findfirst(==(flag), args)
    index === nothing && return default
    index < length(args) || error("missing value after $flag")
    return args[index + 1]
end

function parse_bool(raw, option_name)
    lowered = lowercase(raw)
    lowered == "true" && return true
    lowered == "false" && return false
    throw(ArgumentError("$option_name should be true or false"))
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
    end
    throw(ArgumentError("unsupported render mode: $mode"))
end

function parse_render_theme(raw)
    if raw == "dark"
        return VisualizingLQCD.RENDER_THEME_DARK
    elseif raw == "light"
        return VisualizingLQCD.RENDER_THEME_LIGHT
    end
    throw(ArgumentError("--render-theme should be dark or light"))
end

function parse_camera_motion(raw)
    if raw == "orbit"
        return VisualizingLQCD.CAMERA_MOTION_ORBIT
    elseif raw == "static"
        return VisualizingLQCD.CAMERA_MOTION_STATIC
    end
    throw(ArgumentError("--camera-motion should be orbit or static"))
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

function parse_tau_list(raw)
    isempty(strip(raw)) && return nothing
    return [parse(Float64, strip(part)) for part in split(raw, ",")]
end

function tau_from_metadata(metadata)
    if metadata isa NamedTuple
        haskey(metadata, :tau) && return Float64(metadata.tau)
        haskey(metadata, "tau") && return Float64(metadata["tau"])
    elseif metadata isa AbstractDict
        haskey(metadata, :tau) && return Float64(metadata[:tau])
        haskey(metadata, "tau") && return Float64(metadata["tau"])
    end
    return nothing
end

function tau_from_filename(path)
    match_result = match(r"tau_([0-9]+(?:p[0-9]+)?)", basename(path))
    match_result === nothing &&
        throw(ArgumentError("could not infer tau from $(basename(path))"))
    return parse(Float64, replace(match_result.captures[1], "p" => "."))
end

function metadata_to_dict(metadata)
    if metadata isa NamedTuple
        return Dict(String(k) => v for (k, v) in pairs(metadata))
    elseif metadata isa AbstractDict
        return Dict(String(k) => v for (k, v) in pairs(metadata))
    end
    return Dict("raw" => string(metadata))
end

function load_q_density_sample(path)
    data = JLD2.load(path)
    haskey(data, "q") || throw(ArgumentError("$path does not contain dataset q"))
    q = Array{Float64}(data["q"])
    if ndims(q) == 5
        size(q, 1) == 1 ||
            throw(ArgumentError("5D q density in $path should have a singleton leading axis"))
        q = Array(@view q[1, :, :, :, :])
    end
    ndims(q) == 4 || throw(ArgumentError("q density in $path should be 4D"))
    metadata = get(data, "metadata", NamedTuple())
    tau = tau_from_metadata(metadata)
    tau === nothing && (tau = tau_from_filename(path))
    return (
        path=path,
        tau=Float64(tau),
        q=q,
        metadata=metadata_to_dict(metadata),
        q_total=sum(q),
        q_abs_maximum=maximum(abs, q),
    )
end

function discover_samples(input_dir)
    isdir(input_dir) || throw(ArgumentError("--input-dir does not exist: $input_dir"))
    paths = sort(filter(path -> endswith(path, ".jld2"), readdir(input_dir; join=true)))
    isempty(paths) && throw(ArgumentError("no JLD2 files found in $input_dir"))
    samples = [load_q_density_sample(path) for path in paths]
    order = sortperm([sample.tau for sample in samples])
    return samples[order]
end

function select_samples(samples, tau_values; stride, tolerance)
    stride > 0 || throw(ArgumentError("--stride should be positive"))
    if tau_values === nothing
        return samples[1:stride:end]
    end
    selected = []
    sample_taus = [sample.tau for sample in samples]
    for tau in tau_values
        distances = abs.(sample_taus .- tau)
        distance, index = findmin(distances)
        distance <= tolerance ||
            throw(ArgumentError("could not find tau=$(tau) within tolerance $(tolerance)"))
        push!(selected, samples[index])
    end
    return selected
end

function density_stack(samples)
    nx, ny, nz, nt = size(samples[1].q)
    stack = Array{Float64}(undef, nx, ny, nz, nt, length(samples))
    for (i, sample) in enumerate(samples)
        size(sample.q) == (nx, ny, nz, nt) ||
            throw(ArgumentError("all q densities should have the same lattice size"))
        stack[:, :, :, :, i] .= sample.q
    end
    return stack
end

function setup_for_mode(samples, mode, options)
    return VisualizingLQCD.topological_charge_display_level_setup(density_stack(samples);
        style_preset=options.style_preset,
        level_quantiles=options.level_quantiles,
        color_quantile=options.color_quantile,
        render_style=render_style_for_mode(mode),
        render_alpha=options.render_alpha)
end

function axis_kwargs(title, setup, theme_settings, camera, options)
    labels = options.show_axis_labels
    axis_aspect = setup.render_kind == :mesh ? :data : (1, 1, 1)
    kwargs = Dict{Symbol,Any}(
        :xlabel => labels ? "x/a" : "",
        :ylabel => labels ? "y/a" : "",
        :zlabel => labels ? "z/a" : "",
        :title => title,
        :aspect => axis_aspect,
        :backgroundcolor => theme_settings.axis_background,
        :xlabelcolor => theme_settings.text_color,
        :ylabelcolor => theme_settings.text_color,
        :zlabelcolor => theme_settings.text_color,
        :titlecolor => theme_settings.text_color,
        :xticklabelcolor => theme_settings.text_color,
        :yticklabelcolor => theme_settings.text_color,
        :zticklabelcolor => theme_settings.text_color,
        :xtickcolor => theme_settings.text_color,
        :ytickcolor => theme_settings.text_color,
        :ztickcolor => theme_settings.text_color,
        :xgridcolor => theme_settings.grid_color,
        :ygridcolor => theme_settings.grid_color,
        :zgridcolor => theme_settings.grid_color,
    )
    camera.azimuth === nothing || (kwargs[:azimuth] = camera.azimuth)
    camera.elevation === nothing || (kwargs[:elevation] = camera.elevation)
    camera.perspectiveness === nothing || (kwargs[:perspectiveness] = camera.perspectiveness)
    camera.viewmode === nothing || (kwargs[:viewmode] = camera.viewmode)
    return kwargs
end

function output_video_path(options, mode)
    stem, ext = splitext(options.output_name)
    effective_ext = isempty(ext) ? ".mp4" : ext
    effective_stem = options.render_mode == RENDER_MODE_BOTH ?
                     "$(stem)-$(String(mode))" : stem
    return joinpath(options.output_dir, "$effective_stem$effective_ext")
end

function frame_sample_index(frame, frame_hold)
    return div(frame - 1, frame_hold) + 1
end

function flowtime_frame_map(samples, frame_hold)
    frame_count = length(samples) * frame_hold
    return [Dict(
                "frame" => frame,
                "sample_index" => frame_sample_index(frame, frame_hold),
                "tau" => samples[frame_sample_index(frame, frame_hold)].tau,
            ) for frame in 1:frame_count]
end

function render_movie(mode, samples, options)
    setup = setup_for_mode(samples, mode, options)
    nx, ny, nz, nt = size(samples[1].q)
    1 <= options.fixed_slice4 <= nt ||
        throw(ArgumentError("--fixed-slice4 should be in 1:$nt"))

    video_path = output_video_path(options, mode)
    metadata_path = string(video_path, ".metadata.json")
    theme_settings = VisualizingLQCD.render_theme_settings(options.render_theme)
    camera = VisualizingLQCD.camera_settings(setup.render_kind;
        camera_motion=options.camera_motion,
        camera_orbit_turns=options.camera_orbit_turns,
        camera_orbit_seconds=options.camera_orbit_seconds)

    fig = Figure(
        size=(options.figure_size, options.figure_size),
        backgroundcolor=theme_settings.figure_background)
    title = @sprintf("q_lat flow-time movie: flow tau = %.4g, fixed slice4 = %d",
        samples[1].tau, options.fixed_slice4)
    ax = Axis3(fig[1, 1]; axis_kwargs(title, setup, theme_settings, camera, options)...)
    limits!(ax, 0, options.a * nx, 0, options.a * ny, 0, options.a * nz)

    x_physical = (options.a, options.a * nx)
    y_physical = (options.a, options.a * ny)
    z_physical = (options.a, options.a * nz)
    plot_obj = Ref{Any}(nothing)
    total_frames = length(samples) * options.frame_hold

    function draw_sample!(sample)
        VisualizingLQCD.delete_plot_obj!(ax, plot_obj[])
        data = @view sample.q[:, :, :, options.fixed_slice4]
        ax.title = @sprintf("q_lat flow-time movie: flow tau = %.4g, fixed slice4 = %d, Q = %.6g",
            sample.tau, options.fixed_slice4, sample.q_total)
        plot_obj[] = VisualizingLQCD.plot_animation_slice!(ax, data, setup, setup.levels;
            a=options.a,
            lattice_size=(nx, ny, nz),
            x_physical=x_physical,
            y_physical=y_physical,
            z_physical=z_physical)
        limits!(ax, 0, options.a * nx, 0, options.a * ny, 0, options.a * nz)
        return nothing
    end

    progress = options.show_render_progress ?
               Progress(total_frames; desc="Rendering flow-time frames") :
               nothing
    @printf("rendering %-7s flow-time movie -> %s\n", String(mode), video_path)
    record(fig, video_path, 1:total_frames; framerate=options.framerate) do frame
        sample = samples[frame_sample_index(frame, options.frame_hold)]
        VisualizingLQCD.apply_camera_settings!(ax, camera, frame, total_frames)
        draw_sample!(sample)
        progress === nothing || next!(progress)
    end

    metadata = Dict(
        "schema_version" => 1,
        "created_at" => string(Dates.now(Dates.UTC)),
        "interpretation" => Dict(
            "spacetime" => "Euclidean lattice scalar topological-charge-density field",
            "frame_sequence" => "gradient flow time tau",
            "fixed_euclidean_fourth_direction_slice" => options.fixed_slice4,
            "not_real_time_minkowski_evolution" => true,
        ),
        "input" => Dict(
            "input_dir" => options.input_dir,
            "file_count" => length(samples),
            "files" => [sample.path for sample in samples],
        ),
        "configuration" => Dict(
            "lattice_size" => [nx, ny, nz, nt],
            "axis_unit" => "lattice spacing a",
            "a" => options.a,
        ),
        "observable" => Dict(
            "kind" => "q_lat",
            "normalization" => "Q_tot(tau) = sum_n q_lat(n,tau)",
        ),
        "frame_map" => flowtime_frame_map(samples, options.frame_hold),
        "sample_summary" => [Dict(
            "tau" => sample.tau,
            "Q_tot" => sample.q_total,
            "q_abs_maximum" => sample.q_abs_maximum,
            "metadata" => sample.metadata,
        ) for sample in samples],
        "display_transform" => setup.display_transform_info,
        "level_selection" => setup.level_selection_info,
        "render" => Dict(
            "output" => video_path,
            "metadata_output" => metadata_path,
            "render_mode" => String(mode),
            "render_theme" => String(options.render_theme),
            "style_preset" => String(options.style_preset),
            "levels" => collect(setup.levels),
            "render_style_info" => setup.render_style_info,
            "framerate" => options.framerate,
            "frame_hold" => options.frame_hold,
            "frame_count" => total_frames,
            "figure_size" => [options.figure_size, options.figure_size],
            "camera" => VisualizingLQCD.camera_motion_metadata(camera),
            "show_axis_labels" => options.show_axis_labels,
        ),
    )
    VisualizingLQCD.write_animation_metadata(metadata_path, metadata)
    return (label="$(String(mode)) movie", video=video_path, metadata=metadata_path)
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

function write_review_html(output_dir, results, options)
    path = joinpath(output_dir, "view.html")
    summary = html_escape(join((
        "input_dir = $(options.input_dir)",
        "fixed_slice4 = $(options.fixed_slice4)",
        "render_mode = $(String(options.render_mode))",
        "frame direction = gradient flow time tau",
    ), "\n"))
    open(path, "w") do io
        write(io, """
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>VisualizingLQCD flow-time q-density movie review</title>
<style>
body { margin: 0; background: #101010; color: #f4f4f4; font-family: sans-serif; }
main { padding: 24px; display: grid; gap: 24px; }
.review-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(560px, 1fr)); gap: 22px; }
.review-card { border-top: 1px solid #444; padding-top: 18px; }
video { width: 560px; max-width: 100%; background: #000; display: block; margin-bottom: 12px; }
pre { white-space: pre-wrap; color: #ddd; overflow-x: auto; }
a { color: #8cc8ff; }
</style>
</head>
<body>
<main>
<h1>VisualizingLQCD flow-time q-density movie review</h1>
<pre>$summary</pre>
<div class="review-grid">
""")
        for result in results
            label = html_escape(result.label)
            video_path = html_escape(html_path_for(result.video, output_dir))
            metadata_path = html_escape(html_path_for(result.metadata, output_dir))
            write(io, """
<section class="review-card">
<h2>$label</h2>
<video controls muted loop playsinline src="$video_path"></video>
<a href="$video_path">movie file</a> / <a href="$metadata_path">metadata</a>
</section>
""")
        end
        write(io, """
</div>
</main>
</body>
</html>
""")
    end
    return path
end

function print_sample_summary(samples)
    println("selected q_density samples = ", length(samples))
    for sample in samples
        @printf("tau=%8.4f  Q=% .8e  max|q|=% .8e  file=%s\n",
            sample.tau, sample.q_total, sample.q_abs_maximum, basename(sample.path))
    end
    return nothing
end

function main(args=ARGS)
    options = (
        input_dir=arg_value(args, "input-dir", DEFAULT_INPUT_DIR),
        output_dir=arg_value(args, "output-dir", "/private/tmp/VisualizingLQCD-flowtime-q-density"),
        output_name=arg_value(args, "output-name", "flowtime_q_density_slice7.mp4"),
        fixed_slice4=parse(Int, arg_value(args, "fixed-slice4", "7")),
        tau_list=parse_tau_list(arg_value(args, "tau-list", "")),
        tau_tolerance=parse(Float64, arg_value(args, "tau-tolerance", "1.0e-8")),
        stride=parse(Int, arg_value(args, "stride", "1")),
        frame_hold=parse(Int, arg_value(args, "frame-hold", "1")),
        render_mode=parse_render_mode(arg_value(args, "render-mode", "volume")),
        style_preset=parse_style_preset(arg_value(args, "style-preset", "balanced")),
        level_quantiles=parse_optional_quantiles(arg_value(args, "level-quantiles", ""),
            "--level-quantiles"),
        color_quantile=parse_optional_float(arg_value(args, "color-quantile", "")),
        render_alpha=parse_optional_float(arg_value(args, "alpha", "")),
        render_theme=parse_render_theme(arg_value(args, "render-theme", "dark")),
        figure_size=parse(Int, arg_value(args, "figure-size", "560")),
        framerate=parse(Int, arg_value(args, "framerate", "8")),
        camera_motion=parse_camera_motion(arg_value(args, "camera-motion", "static")),
        camera_orbit_turns=parse(Float64, arg_value(args, "camera-orbit-turns", "1")),
        camera_orbit_seconds=parse(Float64, arg_value(args, "camera-orbit-seconds",
            string(VisualizingLQCD.CURRENT_CAMERA_ORBIT_SECONDS))),
        a=parse(Float64, arg_value(args, "a", "1.0")),
        show_axis_labels=parse_bool(arg_value(args, "show-axis-labels", "true"),
            "--show-axis-labels"),
        show_render_progress=parse_bool(arg_value(args, "show-render-progress", "true"),
            "--show-render-progress"),
        dry_run=parse_bool(arg_value(args, "dry-run", "false"), "--dry-run"),
    )
    options.frame_hold > 0 || throw(ArgumentError("--frame-hold should be positive"))
    options.framerate > 0 || throw(ArgumentError("--framerate should be positive"))
    options.a > 0 || throw(ArgumentError("--a should be positive"))

    samples = select_samples(discover_samples(options.input_dir), options.tau_list;
        stride=options.stride, tolerance=options.tau_tolerance)
    isempty(samples) && throw(ArgumentError("no samples selected"))
    print_sample_summary(samples)
    options.dry_run && return nothing

    mkpath(options.output_dir)
    results = [render_movie(mode, samples, options) for mode in render_modes(options.render_mode)]
    view_html = write_review_html(options.output_dir, results, options)
    println("wrote $view_html")
    return view_html
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
