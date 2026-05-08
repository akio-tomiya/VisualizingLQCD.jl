# Minimal JSON sidecar support for animation metadata.

function validate_frame_mode(frame_mode::Symbol)
    if frame_mode == FRAME_MODE_SEQUENCE || frame_mode == FRAME_MODE_FIXED
        return frame_mode
    end
    throw(ArgumentError("unsupported frame_mode: $frame_mode"))
end

function default_frame_mode(camera_motion::Symbol)
    validate_camera_motion(camera_motion)
    return camera_motion == CAMERA_MOTION_ORBIT ? FRAME_MODE_FIXED : CURRENT_FRAME_MODE
end

function slice4_for_frame(frame::Integer, NT::Integer;
    frame_mode=FRAME_MODE_SEQUENCE, fixed_slice4=CURRENT_FIXED_SLICE4)::Int

    frame > 0 || throw(ArgumentError("frame should be positive"))
    NT > 0 || throw(ArgumentError("NT should be positive"))
    mode = validate_frame_mode(frame_mode)
    if mode == FRAME_MODE_SEQUENCE
        return (frame - 1) % NT + 1
    elseif mode == FRAME_MODE_FIXED
        fixed_slice4 isa Integer || throw(ArgumentError("fixed_slice4 should be an integer"))
        1 <= fixed_slice4 <= NT || throw(ArgumentError("fixed_slice4 should be in 1:NT"))
        return fixed_slice4
    else
        throw(ArgumentError("unsupported frame_mode: $mode"))
    end
end

function frame_slice_map(NT::Integer; nloops::Integer=CURRENT_MOVIE_NLOOPS,
    frame_mode=FRAME_MODE_SEQUENCE, fixed_slice4=CURRENT_FIXED_SLICE4)

    NT > 0 || throw(ArgumentError("NT should be positive"))
    nloops > 0 || throw(ArgumentError("nloops should be positive"))
    return [Dict(
                "frame" => i,
                "slice4" => slice4_for_frame(i, NT;
                    frame_mode=frame_mode, fixed_slice4=fixed_slice4),
            ) for i in 1:(NT * nloops)]
end

function frame_sequence_description(frame_mode::Symbol)
    mode = validate_frame_mode(frame_mode)
    if mode == FRAME_MODE_SEQUENCE
        return "fourth-direction slices"
    elseif mode == FRAME_MODE_FIXED
        return "fixed fourth-direction slice"
    else
        throw(ArgumentError("unsupported frame_mode: $mode"))
    end
end

function frame_mode_metadata(frame_mode::Symbol, fixed_slice4)
    mode = validate_frame_mode(frame_mode)
    return Dict(
        "frame_mode" => String(mode),
        "fixed_slice4" => mode == FRAME_MODE_FIXED ? fixed_slice4 : nothing,
    )
end

default_metadata_filename(videoname::AbstractString) = string(videoname, ".metadata.json")

function animation_metadata(;
    videoname,
    metadata_filename,
    filename,
    lattice_size,
    nc,
    beta,
    flow_steps,
    levels,
    level_summary,
    framerate,
    nloops,
    title,
    frame_mode=FRAME_MODE_SEQUENCE,
    fixed_slice4=CURRENT_FIXED_SLICE4,
    display_transform_info=display_transform_metadata(),
    level_selection_info=level_selection_metadata(levels, level_summary),
    render_style_info=Dict{String,Any}(),
    render_theme_info=render_theme_metadata(CURRENT_RENDER_THEME),
    camera_info=camera_motion_metadata(camera_settings(:contour)),
    render_cache_info=Dict{String,Any}(),
    observable_info=plaquette_plane_observable_metadata(),
)
    render_info = merge(
        Dict(
            "output" => String(videoname),
            "metadata_output" => String(metadata_filename),
            "framerate" => framerate,
            "nloops" => nloops,
            "title" => title,
        ),
        render_theme_info,
        render_style_info,
        camera_info,
        render_cache_info,
    )
    return Dict(
        "schema_version" => 1,
        "interpretation" => Dict(
            "spacetime" => "Euclidean lattice configuration",
            "frame_sequence" => frame_sequence_description(frame_mode),
            "not_real_time_minkowski_evolution" => true,
            "screen_time_label" => false,
        ),
        "configuration" => Dict(
            "filename" => String(filename),
            "lattice_size" => collect(lattice_size),
            "nc" => nc,
            "beta" => beta,
        ),
        "observable" => observable_info,
        "display_transform" => display_transform_info,
        "level_selection" => level_selection_info,
        "frame_selection" => frame_mode_metadata(frame_mode, fixed_slice4),
        "frame_map" => frame_slice_map(lattice_size[4];
            nloops=nloops, frame_mode=frame_mode, fixed_slice4=fixed_slice4),
        "flow" => Dict("steps" => flow_steps),
        "render" => render_info,
    )
end

function write_animation_metadata(path::AbstractString, metadata::Dict)
    open(path, "w") do io
        write(io, json_value(metadata))
        write(io, "\n")
    end
    return path
end

function json_value(value)
    if value isa AbstractString
        return json_string(value)
    elseif value isa Symbol
        return json_string(String(value))
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value === nothing
        return "null"
    elseif value isa Integer || value isa AbstractFloat
        return string(value)
    elseif value isa AbstractDict
        pairs = [string(json_string(String(k)), ": ", json_value(v)) for (k, v) in sort(collect(value); by=first)]
        return string("{", join(pairs, ", "), "}")
    elseif value isa Tuple || value isa AbstractVector
        return string("[", join((json_value(v) for v in value), ", "), "]")
    else
        return json_string(string(value))
    end
end

function json_string(value::AbstractString)
    escaped = replace(value,
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\b" => "\\b",
        "\f" => "\\f",
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t")
    return string("\"", escaped, "\"")
end
