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

const DISPLAY_NORMALIZATION_RAW = :raw
const DISPLAY_NORMALIZATION_PER_FRAME_PEAK = :per_frame_peak
const DISPLAY_NORMALIZATION_PER_FRAME_ABSMAX = :per_frame_absmax

const LEVEL_STRATEGY_AUTO = :auto
const LEVEL_STRATEGY_GLOBAL_QUANTILE = :global_quantile
const LEVEL_STRATEGY_FIXED_NORMALIZED = :fixed_normalized
const LEVEL_STRATEGY_POSITIVE_CHARGE_FRACTION = :positive_charge_fraction

const VISIBILITY_GATE_NONE = :none
const VISIBILITY_GATE_TOPOLOGICAL_SECTOR = :topological_sector

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

function parse_display_normalization(raw)
    normalized = replace(lowercase(raw), "-" => "_")
    mode = Symbol(normalized)
    mode in (
        DISPLAY_NORMALIZATION_RAW,
        DISPLAY_NORMALIZATION_PER_FRAME_PEAK,
        DISPLAY_NORMALIZATION_PER_FRAME_ABSMAX,
    ) || throw(ArgumentError(
        "--display-normalization should be raw, per-frame-peak, or per-frame-absmax"))
    return mode
end

function parse_level_strategy(raw)
    normalized = replace(lowercase(raw), "-" => "_")
    mode = Symbol(normalized)
    mode in (
        LEVEL_STRATEGY_AUTO,
        LEVEL_STRATEGY_GLOBAL_QUANTILE,
        LEVEL_STRATEGY_FIXED_NORMALIZED,
        LEVEL_STRATEGY_POSITIVE_CHARGE_FRACTION,
    ) || throw(ArgumentError(
        "--level-strategy should be auto, global-quantile, fixed-normalized, or positive-charge-fraction"))
    return mode
end

function effective_level_strategy(options)
    options.level_strategy != LEVEL_STRATEGY_AUTO && return options.level_strategy
    return options.display_normalization == DISPLAY_NORMALIZATION_RAW ?
           LEVEL_STRATEGY_GLOBAL_QUANTILE : LEVEL_STRATEGY_FIXED_NORMALIZED
end

function parse_visibility_gate(raw)
    normalized = replace(lowercase(raw), "-" => "_")
    gate = Symbol(normalized)
    gate in (
        VISIBILITY_GATE_NONE,
        VISIBILITY_GATE_TOPOLOGICAL_SECTOR,
    ) || throw(ArgumentError(
        "--visibility-gate should be none or topological-sector"))
    return gate
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

function inferred_flow_action_label(samples)
    labels = String[]
    for sample in samples
        label = get(sample.metadata, "flow_action", "")
        isempty(string(label)) || push!(labels, string(label))
    end
    labels = unique(labels)
    return length(labels) == 1 ? labels[1] : ""
end

function level_strategy_label(options)
    strategy = effective_level_strategy(options)
    strategy == LEVEL_STRATEGY_POSITIVE_CHARGE_FRACTION &&
        return @sprintf("positive-charge HDR%.0f", 100 * options.charge_fraction)
    return ""
end

function flow_movie_title(sample, fixed_slice4, action_label, options)
    observable = options.display_normalization == DISPLAY_NORMALIZATION_RAW ? "q_lat" : "q_lat/q_max"
    level_label = level_strategy_label(options)
    prefix_observable = isempty(level_label) ? observable : "$observable $level_label"
    prefix = isempty(action_label) ? "$prefix_observable flow-time movie" :
             "$prefix_observable $(action_label) flow"
    return @sprintf("%s: t/a^2 = %.4g, fixed slice4 = %d, Q = %.6g",
        prefix, sample.tau, fixed_slice4, sample.q_total)
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

function interpolate_sample(samples, tau)
    first(samples).tau <= tau <= last(samples).tau ||
        throw(ArgumentError("frame tau=$tau is outside selected range"))
    sample_taus = [sample.tau for sample in samples]
    exact_index = findfirst(existing_tau -> isapprox(existing_tau, tau; atol=1.0e-10),
        sample_taus)
    exact_index === nothing || return samples[exact_index]

    left_index = searchsortedlast(sample_taus, tau)
    left_index = clamp(left_index, 1, length(samples) - 1)
    right_index = left_index + 1
    left = samples[left_index]
    right = samples[right_index]
    weight = (tau - left.tau) / (right.tau - left.tau)
    q = (1 - weight) .* left.q .+ weight .* right.q
    return (
        path=@sprintf("linear_interpolation(t/a^2=%.8g)", tau),
        tau=Float64(tau),
        q=q,
        metadata=Dict(
            "source" => "linear interpolation between stored flow-time q_density frames",
            "left_t_over_a2" => left.tau,
            "right_t_over_a2" => right.tau,
            "right_weight" => weight,
            "left_file" => left.path,
            "right_file" => right.path,
        ),
        q_total=sum(q),
        q_abs_maximum=maximum(abs, q),
    )
end

function animation_samples(samples, options)
    if options.duration_seconds === nothing
        frames = Any[]
        for sample in samples
            for _ in 1:options.frame_hold
                push!(frames, sample)
            end
        end
        return frames
    end
    frame_count = round(Int, options.duration_seconds * options.framerate)
    frame_count >= 2 || throw(ArgumentError(
        "--duration-seconds times --framerate should produce at least two frames"))
    tau_min = first(samples).tau
    tau_max = last(samples).tau
    return [interpolate_sample(samples,
        tau_min + (tau_max - tau_min) * (frame - 1) / (frame_count - 1))
        for frame in 1:frame_count]
end

function normalization_peak(sample, display_normalization)
    display_normalization == DISPLAY_NORMALIZATION_RAW && return 1.0
    display_normalization == DISPLAY_NORMALIZATION_PER_FRAME_PEAK &&
        return maximum(sample.q)
    display_normalization == DISPLAY_NORMALIZATION_PER_FRAME_ABSMAX &&
        return maximum(abs, sample.q)
    throw(ArgumentError("unsupported display normalization: $display_normalization"))
end

function reference_normalization_peak(samples, display_normalization)
    display_normalization == DISPLAY_NORMALIZATION_RAW && return 1.0
    return normalization_peak(first(samples), display_normalization)
end

function normalization_floor(reference_peak, options)
    options.display_normalization == DISPLAY_NORMALIZATION_RAW && return 0.0
    return max(options.normalization_abs_floor,
        options.normalization_floor_fraction * max(abs(reference_peak), eps(Float64)))
end

function display_q_density(sample, options, reference_peak)
    options.display_normalization == DISPLAY_NORMALIZATION_RAW && return sample.q
    peak = normalization_peak(sample, options.display_normalization)
    floor = normalization_floor(reference_peak, options)
    if !(isfinite(peak)) || abs(peak) <= floor
        return zeros(Float64, size(sample.q))
    end
    return sample.q ./ peak
end

function display_sample_summary(sample, options, reference_peak)
    peak = normalization_peak(sample, options.display_normalization)
    floor = normalization_floor(reference_peak, options)
    active = options.display_normalization == DISPLAY_NORMALIZATION_RAW ||
             (isfinite(peak) && abs(peak) > floor)
    scale = active && options.display_normalization != DISPLAY_NORMALIZATION_RAW ? peak : 1.0
    display_abs_maximum = if options.display_normalization == DISPLAY_NORMALIZATION_RAW
        sample.q_abs_maximum
    elseif active
        maximum(abs, sample.q ./ scale)
    else
        0.0
    end
    return Dict(
        "display_normalization" => String(options.display_normalization),
        "normalization_peak" => peak,
        "normalization_floor" => floor,
        "display_active" => active,
        "display_scale" => scale,
        "display_abs_maximum" => display_abs_maximum,
    )
end

function positive_slice_charge(q, fixed_slice4)
    data = @view q[:, :, :, fixed_slice4]
    return sum(max.(data, 0.0))
end

function charge_fraction_threshold(data, fraction)
    0 < fraction <= 1 ||
        throw(ArgumentError("--charge-fraction should be in (0, 1]"))
    positive_values = Float64[]
    for value in data
        value > 0 && push!(positive_values, Float64(value))
    end
    isempty(positive_values) && return nothing
    total = sum(positive_values)
    total > 0 || return nothing
    sort!(positive_values; rev=true)
    target = fraction * total
    cumulative = 0.0
    threshold = last(positive_values)
    for value in positive_values
        cumulative += value
        threshold = value
        cumulative >= target && break
    end
    return (
        threshold=threshold,
        total_positive=total,
        selected_positive=cumulative,
        selected_fraction=cumulative / total,
        selected_sites=count(>=(threshold), positive_values),
    )
end

function charge_fraction_alpha(sample, options, reference_positive_slice_charge)
    options.charge_fraction_fade || return nothing
    reference_positive_slice_charge > 0 || return 0.0
    charge = positive_slice_charge(sample.q, options.fixed_slice4)
    return clamp(charge / reference_positive_slice_charge, 0.0, 1.0)
end

function visibility_gate_summary(sample, options)
    if options.visibility_gate == VISIBILITY_GATE_NONE
        return Dict(
            "mode" => String(VISIBILITY_GATE_NONE),
            "active" => true,
        )
    elseif options.visibility_gate == VISIBILITY_GATE_TOPOLOGICAL_SECTOR
        distance = abs(sample.q_total - options.target_topological_charge)
        active = distance < 0.5
        return Dict(
            "mode" => String(VISIBILITY_GATE_TOPOLOGICAL_SECTOR),
            "active" => active,
            "target_topological_charge" => options.target_topological_charge,
            "sector_distance" => distance,
            "sector_radius" => 0.5,
            "note" => "active means Q_tot is closer to the target topological sector than to its neighboring integer sector",
        )
    end
    throw(ArgumentError("unsupported visibility gate: $(options.visibility_gate)"))
end

function positive_charge_fraction_level_setup(base_setup, data, sample, options,
    reference_positive_slice_charge)
    effective_level_strategy(options) == LEVEL_STRATEGY_POSITIVE_CHARGE_FRACTION ||
        return base_setup
    (:mesh_renderer in keys(base_setup)) &&
        base_setup.mesh_renderer == :topological_charge_volume ||
        return base_setup

    gate = visibility_gate_summary(sample, options)
    threshold_info = gate["active"] ?
                     charge_fraction_threshold(data, options.charge_fraction) :
                     nothing
    alpha = something(charge_fraction_alpha(sample, options, reference_positive_slice_charge),
        base_setup.alpha)
    render_style_info = merge(Dict(base_setup.render_style_info), Dict(
        "level_strategy" => String(LEVEL_STRATEGY_POSITIVE_CHARGE_FRACTION),
        "charge_fraction" => options.charge_fraction,
        "charge_fraction_fade" => options.charge_fraction_fade,
        "visibility_gate" => gate,
        "positive_slice_charge" => positive_slice_charge(sample.q, options.fixed_slice4),
        "reference_positive_slice_charge" => reference_positive_slice_charge,
        "alpha" => alpha,
        "transparency" => options.charge_fraction_fade || base_setup.transparency,
    ))
    if threshold_info === nothing
        return merge(base_setup, (
            levels=(0.0,),
            positive_body_level=nothing,
            negative_body_level=nothing,
            positive_color_range=nothing,
            negative_color_range=nothing,
            alpha=0.0,
            transparency=true,
            level_selection_info=Dict(
                "method" => "positive_charge_fraction_highest_density_region",
                "charge_fraction" => options.charge_fraction,
                "active" => false,
                "visibility_gate" => gate,
                "note" => gate["active"] ?
                          "no positive density on the displayed slice" :
                          "visibility gate is inactive for this frame",
            ),
            render_style_info=merge(render_style_info, Dict("active" => false)),
        ))
    end
    threshold = threshold_info.threshold
    ceiling = max(maximum(data), threshold)
    level_selection_info = Dict(
        "method" => "positive_charge_fraction_highest_density_region",
        "charge_fraction" => options.charge_fraction,
        "active" => true,
        "visibility_gate" => gate,
        "positive_body_level" => threshold,
        "positive_color_ceiling" => ceiling,
        "total_positive_slice_charge" => threshold_info.total_positive,
        "selected_positive_slice_charge" => threshold_info.selected_positive,
        "selected_fraction" => threshold_info.selected_fraction,
        "selected_sites" => threshold_info.selected_sites,
        "note" => "threshold is chosen on the displayed 3D slice so the highest-density positive region carries the requested fraction of positive slice charge",
    )
    return merge(base_setup, (
        levels=(threshold,),
        positive_body_level=threshold,
        negative_body_level=nothing,
        positive_color_range=(threshold, ceiling),
        negative_color_range=nothing,
        alpha=alpha,
        transparency=options.charge_fraction_fade || base_setup.transparency,
        level_selection_info=level_selection_info,
        render_style_info=merge(render_style_info, level_selection_info),
    ))
end

function sample_level_summary(sample, options, reference_peak, reference_positive_slice_charge)
    strategy = effective_level_strategy(options)
    strategy != LEVEL_STRATEGY_POSITIVE_CHARGE_FRACTION &&
        return Dict("level_strategy" => String(strategy))
    gate = visibility_gate_summary(sample, options)
    q_display = display_q_density(sample, options, reference_peak)
    data = @view q_display[:, :, :, options.fixed_slice4]
    threshold_info = gate["active"] ?
                     charge_fraction_threshold(data, options.charge_fraction) :
                     nothing
    raw_positive_charge = positive_slice_charge(sample.q, options.fixed_slice4)
    alpha = charge_fraction_alpha(sample, options, reference_positive_slice_charge)
    summary = Dict{String,Any}(
        "level_strategy" => String(strategy),
        "charge_fraction" => options.charge_fraction,
        "visibility_gate" => gate,
        "positive_slice_charge" => raw_positive_charge,
        "reference_positive_slice_charge" => reference_positive_slice_charge,
        "charge_fraction_alpha" => alpha,
        "active" => gate["active"] && threshold_info !== nothing,
    )
    threshold_info === nothing && return summary
    summary["positive_body_level"] = threshold_info.threshold
    summary["selected_positive_slice_charge"] = threshold_info.selected_positive
    summary["selected_fraction"] = threshold_info.selected_fraction
    summary["selected_sites"] = threshold_info.selected_sites
    return summary
end

function density_stack(samples, options, reference_peak)
    nx, ny, nz, nt = size(samples[1].q)
    stack = Array{Float64}(undef, nx, ny, nz, nt, length(samples))
    for (i, sample) in enumerate(samples)
        size(sample.q) == (nx, ny, nz, nt) ||
            throw(ArgumentError("all q densities should have the same lattice size"))
        stack[:, :, :, :, i] .= display_q_density(sample, options, reference_peak)
    end
    return stack
end

function fixed_normalized_level_setup(setup, options)
    effective_level_strategy(options) == LEVEL_STRATEGY_FIXED_NORMALIZED || return setup
    options.display_normalization == DISPLAY_NORMALIZATION_RAW && return setup
    is_topological_volume = (:mesh_renderer in keys(setup)) &&
                            setup.mesh_renderer == :topological_charge_volume
    is_topological_volume || return setup
    0 < options.normalized_body_level < options.normalized_color_ceiling ||
        throw(ArgumentError("--normalized-body-level should be positive and smaller than --normalized-color-ceiling"))
    levels = (
        -options.normalized_color_ceiling,
        -options.normalized_body_level,
        options.normalized_body_level,
        options.normalized_color_ceiling,
    )
    level_selection_info = Dict(
        "method" => "fixed_normalized_q_over_qmax_superlevel",
        "display_normalization" => String(options.display_normalization),
        "positive_body_level" => options.normalized_body_level,
        "negative_body_level" => options.normalized_body_level,
        "positive_color_ceiling" => options.normalized_color_ceiling,
        "negative_color_ceiling" => options.normalized_color_ceiling,
        "note" => "levels are in displayed q/q_max units, not raw q_lat units",
    )
    render_style_info = merge(Dict(setup.render_style_info),
        Dict(
            "display_normalization" => String(options.display_normalization),
            "normalized_body_level" => options.normalized_body_level,
            "normalized_color_ceiling" => options.normalized_color_ceiling,
            "positive_body_level" => options.normalized_body_level,
            "negative_body_level" => options.normalized_body_level,
            "positive_color_range" => (
                options.normalized_body_level, options.normalized_color_ceiling),
            "negative_color_range" => (
                options.normalized_body_level, options.normalized_color_ceiling),
        ))
    return merge(setup, (
        levels=levels,
        positive_body_level=options.normalized_body_level,
        negative_body_level=options.normalized_body_level,
        positive_color_range=(options.normalized_body_level, options.normalized_color_ceiling),
        negative_color_range=(options.normalized_body_level, options.normalized_color_ceiling),
        level_selection_info=level_selection_info,
        render_style_info=render_style_info,
    ))
end

function setup_for_mode(samples, mode, options, reference_peak)
    setup = VisualizingLQCD.topological_charge_display_level_setup(
        density_stack(samples, options, reference_peak);
        style_preset=options.style_preset,
        level_quantiles=options.level_quantiles,
        color_quantile=options.color_quantile,
        render_style=render_style_for_mode(mode),
        render_alpha=options.render_alpha)
    return fixed_normalized_level_setup(setup, options)
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

function flowtime_frame_map(samples)
    frame_count = length(samples)
    return [Dict(
                "frame" => frame,
                "t_over_a2" => samples[frame].tau,
                "source_tau" => samples[frame].tau,
                "source" => samples[frame].path,
            ) for frame in 1:frame_count]
end

function render_movie(mode, samples, options)
    frames = animation_samples(samples, options)
    reference_peak = reference_normalization_peak(frames, options.display_normalization)
    setup = setup_for_mode(frames, mode, options, reference_peak)
    nx, ny, nz, nt = size(samples[1].q)
    1 <= options.fixed_slice4 <= nt ||
        throw(ArgumentError("--fixed-slice4 should be in 1:$nt"))
    reference_positive_slice_charge = positive_slice_charge(first(frames).q,
        options.fixed_slice4)

    video_path = output_video_path(options, mode)
    metadata_path = string(video_path, ".metadata.json")
    theme_settings = VisualizingLQCD.render_theme_settings(options.render_theme)
    camera = VisualizingLQCD.camera_settings(setup.render_kind;
        camera_motion=options.camera_motion,
        camera_orbit_turns=options.camera_orbit_turns,
        camera_orbit_seconds=options.camera_orbit_seconds)
    action_label = isempty(options.action_label) ?
                   inferred_flow_action_label(samples) : options.action_label

    fig = Figure(
        size=(options.figure_size, options.figure_size),
        backgroundcolor=theme_settings.figure_background)
    title = flow_movie_title(samples[1], options.fixed_slice4, action_label, options)
    ax = Axis3(fig[1, 1]; axis_kwargs(title, setup, theme_settings, camera, options)...)
    limits!(ax, 0, options.a * nx, 0, options.a * ny, 0, options.a * nz)

    x_physical = (options.a, options.a * nx)
    y_physical = (options.a, options.a * ny)
    z_physical = (options.a, options.a * nz)
    plot_obj = Ref{Any}(nothing)
    total_frames = length(frames)

    function draw_sample!(sample)
        VisualizingLQCD.delete_plot_obj!(ax, plot_obj[])
        q_display = display_q_density(sample, options, reference_peak)
        data = @view q_display[:, :, :, options.fixed_slice4]
        sample_setup = positive_charge_fraction_level_setup(setup, data, sample, options,
            reference_positive_slice_charge)
        ax.title = flow_movie_title(sample, options.fixed_slice4, action_label, options)
        plot_obj[] = VisualizingLQCD.plot_animation_slice!(ax, data, sample_setup,
            sample_setup.levels;
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
        sample = frames[frame]
        VisualizingLQCD.apply_camera_settings!(ax, camera, frame, total_frames)
        draw_sample!(sample)
        progress === nothing || next!(progress)
    end

    metadata = Dict(
        "schema_version" => 1,
        "created_at" => string(Dates.now(Dates.UTC)),
        "interpretation" => Dict(
            "spacetime" => "Euclidean lattice scalar topological-charge-density field",
            "frame_sequence" => "gradient flow time t/a^2",
            "source_tau_equals_t_over_a2" => true,
            "fixed_euclidean_fourth_direction_slice" => options.fixed_slice4,
            "not_real_time_minkowski_evolution" => true,
        ),
        "input" => Dict(
            "input_dir" => options.input_dir,
            "file_count" => length(samples),
            "files" => [sample.path for sample in samples],
            "flow_action_label" => action_label,
        ),
        "configuration" => Dict(
            "lattice_size" => [nx, ny, nz, nt],
            "axis_unit" => "lattice spacing a",
            "a" => options.a,
        ),
        "observable" => Dict(
            "kind" => options.display_normalization == DISPLAY_NORMALIZATION_RAW ?
                      "q_lat" : "displayed q_lat/q_max",
            "normalization" => "Q_tot(t) = sum_n q_lat(n,t)",
            "display_normalization" => String(options.display_normalization),
        ),
        "level_strategy" => Dict(
            "mode" => String(effective_level_strategy(options)),
            "requested" => String(options.level_strategy),
            "charge_fraction" => options.charge_fraction,
            "charge_fraction_fade" => options.charge_fraction_fade,
            "reference_positive_slice_charge" => reference_positive_slice_charge,
            "visibility_gate" => String(options.visibility_gate),
            "target_topological_charge" => options.target_topological_charge,
        ),
        "frame_map" => flowtime_frame_map(frames),
        "sample_summary" => [Dict(
            "t_over_a2" => sample.tau,
            "source_tau" => sample.tau,
            "Q_tot" => sample.q_total,
            "q_abs_maximum" => sample.q_abs_maximum,
            "display" => display_sample_summary(sample, options, reference_peak),
            "level" => sample_level_summary(sample, options, reference_peak,
                reference_positive_slice_charge),
            "metadata" => sample.metadata,
        ) for sample in frames],
        "display_transform" => setup.display_transform_info,
        "display_normalization" => Dict(
            "mode" => String(options.display_normalization),
            "reference_peak" => reference_peak,
            "floor_fraction" => options.normalization_floor_fraction,
            "abs_floor" => options.normalization_abs_floor,
            "effective_floor" => normalization_floor(reference_peak, options),
            "normalized_body_level" => options.normalized_body_level,
            "normalized_color_ceiling" => options.normalized_color_ceiling,
            "collapse_policy" => "render zero field when per-frame normalization peak is at or below the effective floor",
        ),
        "level_selection" => setup.level_selection_info,
        "render" => Dict(
            "output" => video_path,
            "metadata_output" => metadata_path,
            "render_mode" => String(mode),
            "render_theme" => String(options.render_theme),
            "style_preset" => String(options.style_preset),
            "flow_action_label" => action_label,
            "levels" => collect(setup.levels),
            "render_style_info" => setup.render_style_info,
            "framerate" => options.framerate,
            "frame_hold" => options.frame_hold,
            "duration_seconds" => options.duration_seconds,
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
        "display_normalization = $(String(options.display_normalization))",
        "level_strategy = $(String(effective_level_strategy(options)))",
        "visibility_gate = $(String(options.visibility_gate))",
        "duration_seconds = $(options.duration_seconds)",
        "frame direction = gradient flow time t/a^2",
        "source tau metadata is interpreted as t/a^2",
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
        @printf("t/a^2=%8.4f  Q=% .8e  max|q|=% .8e  file=%s\n",
            sample.tau, sample.q_total, sample.q_abs_maximum, basename(sample.path))
    end
    return nothing
end

function main(args=ARGS)
    options = (
        input_dir=arg_value(args, "input-dir", DEFAULT_INPUT_DIR),
        output_dir=arg_value(args, "output-dir", "/private/tmp/VisualizingLQCD-flowtime-q-density"),
        output_name=arg_value(args, "output-name", "flowtime_q_density_slice7.mp4"),
        action_label=arg_value(args, "action-label", ""),
        fixed_slice4=parse(Int, arg_value(args, "fixed-slice4", "7")),
        tau_list=parse_tau_list(arg_value(args, "t-over-a2-list",
            arg_value(args, "tau-list", ""))),
        tau_tolerance=parse(Float64, arg_value(args, "tau-tolerance", "1.0e-8")),
        stride=parse(Int, arg_value(args, "stride", "1")),
        frame_hold=parse(Int, arg_value(args, "frame-hold", "1")),
        duration_seconds=parse_optional_float(arg_value(args, "duration-seconds", "")),
        render_mode=parse_render_mode(arg_value(args, "render-mode", "volume")),
        display_normalization=parse_display_normalization(arg_value(args,
            "display-normalization", "raw")),
        level_strategy=parse_level_strategy(arg_value(args, "level-strategy", "auto")),
        charge_fraction=parse(Float64, arg_value(args, "charge-fraction", "0.50")),
        charge_fraction_fade=parse_bool(arg_value(args, "charge-fraction-fade", "true"),
            "--charge-fraction-fade"),
        visibility_gate=parse_visibility_gate(arg_value(args, "visibility-gate", "none")),
        target_topological_charge=parse(Float64, arg_value(args,
            "target-topological-charge", "1.0")),
        normalization_floor_fraction=parse(Float64, arg_value(args,
            "normalization-floor-fraction", "1.0e-3")),
        normalization_abs_floor=parse(Float64, arg_value(args,
            "normalization-abs-floor", "0.0")),
        normalized_body_level=parse(Float64, arg_value(args,
            "normalized-body-level", "0.25")),
        normalized_color_ceiling=parse(Float64, arg_value(args,
            "normalized-color-ceiling", "1.0")),
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
    (options.duration_seconds === nothing || options.duration_seconds > 0) ||
        throw(ArgumentError("--duration-seconds should be positive"))
    options.a > 0 || throw(ArgumentError("--a should be positive"))
    options.normalization_floor_fraction >= 0 ||
        throw(ArgumentError("--normalization-floor-fraction should be nonnegative"))
    options.normalization_abs_floor >= 0 ||
        throw(ArgumentError("--normalization-abs-floor should be nonnegative"))
    0 < options.charge_fraction <= 1 ||
        throw(ArgumentError("--charge-fraction should be in (0, 1]"))

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
