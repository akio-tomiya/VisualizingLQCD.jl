# Minimal JSON sidecar support for animation metadata.

function slice4_for_frame(frame::Integer, NT::Integer)::Int
    frame > 0 || throw(ArgumentError("frame should be positive"))
    NT > 0 || throw(ArgumentError("NT should be positive"))
    return (frame - 1) % NT + 1
end

function frame_slice_map(NT::Integer; nloops::Integer=CURRENT_MOVIE_NLOOPS)
    NT > 0 || throw(ArgumentError("NT should be positive"))
    nloops > 0 || throw(ArgumentError("nloops should be positive"))
    return [Dict("frame" => i, "slice4" => slice4_for_frame(i, NT)) for i in 1:(NT * nloops)]
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
)
    return Dict(
        "schema_version" => 1,
        "interpretation" => Dict(
            "spacetime" => "Euclidean lattice configuration",
            "frame_sequence" => "fourth-direction slices",
            "not_real_time_minkowski_evolution" => true,
            "screen_time_label" => false,
        ),
        "configuration" => Dict(
            "filename" => String(filename),
            "lattice_size" => collect(lattice_size),
            "nc" => nc,
            "beta" => beta,
        ),
        "observable" => Dict(
            "kind" => "plaquette_plane",
            "wilsonline_loop" => [collect(step) for step in CURRENT_WILSONLINE_LOOP],
        ),
        "display_transform" => Dict(
            "kind" => "neglog",
            "formula" => "-log(p + epsilon)",
            "epsilon" => CURRENT_LOG_EPSILON,
        ),
        "level_selection" => Dict(
            "method" => "mean_std",
            "std_multiplier" => CURRENT_LEVEL_STD_MULTIPLIER,
            "step" => CURRENT_LEVEL_STEP,
            "display_levels" => collect(levels),
            "summary" => Dict(
                "level" => level_summary.level,
                "isorange" => level_summary.isorange,
                "min" => level_summary.min,
                "max" => level_summary.max,
            ),
        ),
        "frame_map" => frame_slice_map(lattice_size[4]; nloops=nloops),
        "flow" => Dict("steps" => flow_steps),
        "render" => Dict(
            "output" => String(videoname),
            "metadata_output" => String(metadata_filename),
            "framerate" => framerate,
            "nloops" => nloops,
            "title" => title,
        ),
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
