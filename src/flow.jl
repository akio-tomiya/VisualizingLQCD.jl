# Gradient-flow series: one LatticeField per flow time, and a movie that shows
# them in order at a fixed fourth-direction slice.
#
#   series = flow_series(U, TopologicalChargeDensity(); steps=0:10:200)
#   movie("q_flow.mp4", series; frames=FlowSweep(slice=8))

"""
    FieldSeries(fields, flow_times; name=fields[1].name, info=Dict())

A sequence of `LatticeField`s on the same lattice, labeled by the flow time
`t/a²`. Build one with [`flow_series`](@ref), or from fields computed
elsewhere (for example densities saved by another program).
"""
struct FieldSeries
    fields::Vector{LatticeField}
    flow_times::Vector{Float64}
    name::String
    info::Dict{String,Any}

    function FieldSeries(fields::AbstractVector{<:LatticeField}, flow_times::AbstractVector{<:Real};
        name::AbstractString=first(fields).name, info=Dict{String,Any}())
        isempty(fields) && throw(ArgumentError("FieldSeries needs at least one field"))
        length(fields) == length(flow_times) ||
            throw(ArgumentError("fields and flow_times should have the same length"))
        all(size(f) == size(first(fields)) for f in fields) ||
            throw(ArgumentError("all fields should have the same lattice size"))
        issorted(flow_times) || throw(ArgumentError("flow_times should be increasing"))
        return new(collect(LatticeField, fields), Float64.(collect(flow_times)),
            String(name), Dict{String,Any}(info))
    end
end

Base.length(series::FieldSeries) = length(series.fields)
Base.getindex(series::FieldSeries, i::Integer) = series.fields[i]
Base.size(series::FieldSeries) = size(first(series.fields))

function Base.show(io::IO, series::FieldSeries)
    print(io, "FieldSeries(\"", series.name, "\", ", length(series), " flow times in [",
        first(series.flow_times), ", ", last(series.flow_times), "])")
end

"""
    flow_series(U, op; steps=0:10:200, step_size=0.01)

Apply the Wilson gradient flow to a copy of `U` and measure `op` after each
number of steps in `steps` (flow time `t/a² = steps * step_size`). `U` is not
modified.
"""
function flow_series(U, op::AbstractLatticeOperator;
    steps=0:10:CURRENT_FLOW_STEPS_ANIMATION_DEFAULT,
    step_size::Real=CURRENT_FLOW_STEP_SIZE)

    step_list = collect(Int, steps)
    isempty(step_list) && throw(ArgumentError("steps should not be empty"))
    all(>=(0), step_list) || throw(ArgumentError("steps should be nonnegative"))
    issorted(step_list) && allunique(step_list) ||
        throw(ArgumentError("steps should be strictly increasing"))
    step_size > 0 || throw(ArgumentError("step_size should be positive"))

    V = copy_configuration(U)
    flow = gradient_flow(V; steps=1, step_size=step_size)
    done = 0
    fields = LatticeField[]
    for n in step_list
        while done < n
            flow!(V, flow)
            done += 1
        end
        push!(fields, measure(op, V))
    end
    info = Dict{String,Any}(
        "kind" => "gradient_flow_series",
        "flow" => "Wilson gradient flow (Gaugefields.gradient_flow)",
        "step_size" => Float64(step_size),
        "steps" => step_list,
        "observable" => first(fields).info,
    )
    return FieldSeries(fields, step_list .* Float64(step_size); info=info)
end

const FLOW_TIME_METADATA_KEYS = (:tau, :t_over_a2)

function flow_time_from_metadata(metadata::NamedTuple)
    for key in FLOW_TIME_METADATA_KEYS
        haskey(metadata, key) && return Float64(metadata[key])
    end
    return nothing
end

function flow_time_from_metadata(metadata::AbstractDict)
    for key in FLOW_TIME_METADATA_KEYS, k in (key, String(key))
        haskey(metadata, k) && return Float64(metadata[k])
    end
    return nothing
end

flow_time_from_metadata(metadata) = nothing

function flow_time_from_filename(path::AbstractString)
    m = match(r"tau_([0-9]+(?:p[0-9]+)?)", basename(path))
    m === nothing && throw(ArgumentError("could not infer the flow time from $(basename(path))"))
    return parse(Float64, replace(m.captures[1], "p" => "."))
end

metadata_dict(metadata::Union{NamedTuple,AbstractDict}) =
    Dict{String,Any}(String(k) => v for (k, v) in pairs(metadata))
metadata_dict(metadata) = Dict{String,Any}("raw" => string(metadata))

"""
    load_field_series(source; dataset="q", name="topological_charge_density",
                      signed=true, flow_times=nothing, tolerance=1e-8)

Read one density per JLD2 file into a [`FieldSeries`](@ref). `source` is a
directory (all `*.jld2` files in it) or a list of files. Each file holds a 4D
array under `dataset` (a 5D array with a singleton first axis is also
accepted). The flow time `t/a²` comes from `metadata.tau` (or `t_over_a2`)
when present, otherwise from a `tau_12p5`-style part of the file name.
`flow_times` keeps only the files nearest to the given times.
"""
function load_field_series(source; dataset::AbstractString="q",
    name::AbstractString="topological_charge_density", signed::Bool=true,
    flow_times=nothing, tolerance::Real=1e-8)

    paths = if source isa AbstractString
        isdir(source) || throw(ArgumentError("directory not found: $source"))
        sort(filter(endswith(".jld2"), readdir(source; join=true)))
    else
        collect(String, source)
    end
    isempty(paths) && throw(ArgumentError("no JLD2 files in $source"))

    samples = map(paths) do path
        data = JLD2.load(path)
        haskey(data, dataset) || throw(ArgumentError("$path has no dataset $dataset"))
        values = Array{Float64}(data[dataset])
        if ndims(values) == 5
            size(values, 1) == 1 ||
                throw(ArgumentError("5D data in $path should have a singleton first axis"))
            values = values[1, :, :, :, :]
        end
        ndims(values) == 4 || throw(ArgumentError("data in $path should be 4D"))
        metadata = get(data, "metadata", NamedTuple())
        t = flow_time_from_metadata(metadata)
        t === nothing && (t = flow_time_from_filename(path))
        (path=path, flow_time=t, values=values, metadata=metadata_dict(metadata))
    end
    sort!(samples; by=sample -> sample.flow_time)

    if flow_times !== nothing
        available = [sample.flow_time for sample in samples]
        samples = map(collect(flow_times)) do t
            distance, index = findmin(abs.(available .- t))
            distance <= tolerance ||
                throw(ArgumentError("no file with t/a^2 = $t (nearest $(available[index]))"))
            samples[index]
        end
        sort!(samples; by=sample -> sample.flow_time)
    end

    fields = [LatticeField(sample.values; name=name, signed=signed, info=Dict{String,Any}(
        "kind" => "loaded_density", "name" => name, "source_file" => sample.path,
        "dataset" => dataset, "file_metadata" => sample.metadata)) for sample in samples]
    info = Dict{String,Any}(
        "kind" => "loaded_flow_series",
        "dataset" => dataset,
        "files" => [sample.path for sample in samples],
        "observable" => Dict{String,Any}("kind" => "loaded_density", "name" => name),
    )
    return FieldSeries(fields, [sample.flow_time for sample in samples]; name=name, info=info)
end

"""
    resample(series, flow_times)

Linearly interpolate a `FieldSeries` in flow time, for example to make a
movie of fixed length with evenly spaced flow times:
`resample(series, range(first(series.flow_times), last(series.flow_times); length=300))`.
"""
function resample(series::FieldSeries, flow_times)
    times = series.flow_times
    targets = Float64.(collect(flow_times))
    all(t -> first(times) <= t <= last(times), targets) ||
        throw(ArgumentError("resample times should lie in [$(first(times)), $(last(times))]"))
    fields = map(targets) do t
        exact = findfirst(s -> isapprox(s, t; atol=1e-10), times)
        exact === nothing || return series.fields[exact]
        left = clamp(searchsortedlast(times, t), 1, length(times) - 1)
        w = (t - times[left]) / (times[left + 1] - times[left])
        a, b = series.fields[left], series.fields[left + 1]
        LatticeField((1 - w) .* a.data .+ w .* b.data; name=a.name, signed=a.signed,
            info=merge(a.info, Dict{String,Any}("interpolated_between" =>
                [times[left], times[left + 1]], "right_weight" => w)))
    end
    info = merge(series.info, Dict{String,Any}("resampled" => true))
    return FieldSeries(fields, targets; name=series.name, info=info)
end

"""
    FlowSweep(; slice=1, hold=1, levels=:per_frame)

Show the fields of a `FieldSeries` in order of flow time at one
fourth-direction slice, each for `hold` frames. `levels=:per_frame` chooses
the thresholds of each flow time from its own field (the surfaces stay
visible while the field smooths out); `:first` or `:last` uses the
thresholds of that flow time for all frames (the decay is visible).
"""
Base.@kwdef struct FlowSweep <: AbstractFrames
    slice::Int = 1
    hold::Int = 1
    levels::Symbol = :per_frame
end

function flow_display_setups(style, series::FieldSeries, levels::Symbol)
    frame_setups = [display_setup(style, field.data) for field in series.fields]
    levels == :per_frame && return frame_setups
    reference = levels == :first ? first(frame_setups) :
                levels == :last ? last(frame_setups) :
                throw(ArgumentError("unsupported FlowSweep levels: $levels"))
    return [merge(reference, (display_field=setup.display_field,)) for setup in frame_setups]
end

flow_time_label(series::FieldSeries, i::Integer, slice4::Integer) =
    @sprintf("Flow  t/a^2 %06.2f/%06.2f  x4=%d", series.flow_times[i],
        last(series.flow_times), slice4)

function flow_progress_fraction(series::FieldSeries, i::Integer)
    t0, t1 = first(series.flow_times), last(series.flow_times)
    t1 > t0 || return 1.0
    return clamp((series.flow_times[i] - t0) / (t1 - t0), 0.0, 1.0)
end

flow_progress_points(fraction) = Point2f[(0.02, 0.18), (0.02 + 0.96 * fraction, 0.18)]

# A thin row above the 3D axis with the flow time and a progress bar.
function flow_progress_overlay!(fig, theme_settings, series::FieldSeries, slice4::Integer)
    # fig[0, 1] prepends a row; GridLayout then numbers the rows from 0.
    bar_ax = Axis(fig[0, 1]; backgroundcolor=theme_settings.figure_background)
    rowsize!(fig.layout, 0, Fixed(FLOW_PROGRESS_BAR_HEIGHT))
    hidedecorations!(bar_ax)
    hidespines!(bar_ax)
    xlims!(bar_ax, 0, 1)
    ylims!(bar_ax, 0, 1)
    label = Observable(flow_time_label(series, 1, slice4))
    points = Observable(flow_progress_points(flow_progress_fraction(series, 1)))
    text!(bar_ax, 0.02, 0.64; text=label, align=(:left, :center), fontsize=11,
        color=theme_settings.text_color)
    lines!(bar_ax, Point2f[(0.02, 0.18), (0.98, 0.18)];
        color=(theme_settings.text_color, 0.22), linewidth=7)
    lines!(bar_ax, points; color=theme_settings.text_color, linewidth=7)
    return (label=label, points=points)
end

"""
    movie(path, series::FieldSeries; frames=FlowSweep(), style, camera, beta,
          spacing, theme, framerate=12, figure_size, title,
          show_axis_labels=true, show_flow_progress=true)

Render a gradient-flow series at one fourth-direction slice in order of flow
time, with a flow-time label and progress bar above the plot.
"""
function movie(path::AbstractString, series::FieldSeries;
    frames::FlowSweep=FlowSweep(),
    style::AbstractRenderStyle=default_style(first(series.fields)),
    camera::AbstractCamera=StaticCamera(),
    beta=nothing,
    spacing=nothing,
    theme=nothing,
    framerate::Real=CURRENT_MOVIE_FRAMERATE,
    figure_size=CURRENT_FIGURE_SIZE,
    title=nothing,
    show_axis_labels::Bool=CURRENT_SHOW_AXIS_LABELS,
    show_flow_progress::Bool=true,
    show_render_progress::Bool=CURRENT_SHOW_RENDER_PROGRESS,
    metadata_filename=default_metadata_filename(path))

    NX, NY, NZ, NT = size(series)
    slice4 = frames.slice
    1 <= slice4 <= NT || throw(ArgumentError("FlowSweep slice should be in 1:$NT"))
    frames.hold > 0 || throw(ArgumentError("FlowSweep hold should be positive"))
    framerate > 0 || throw(ArgumentError("framerate should be positive"))

    setups = flow_display_setups(style, series, frames.levels)
    scale = resolve_spacing(spacing, beta)
    camera_spec = camera_settings(first(setups).render_kind, camera)
    effective_theme = effective_render_theme(render_style_symbol(style), theme)
    theme_settings = render_theme_settings(effective_theme)
    base_title = something(title, default_title(first(series.fields), first(setups)))
    scene = initialize_animation_scene(first(setups), theme_settings, camera_spec;
        a=scale.a,
        lattice_size=(NX, NY, NZ),
        movie_title=base_title,
        figure_size=validate_figure_size(figure_size),
        show_axis_labels=show_axis_labels,
        length_unit=scale.length_unit)
    fig, ax = scene.fig, scene.ax
    overlay = show_flow_progress ?
              flow_progress_overlay!(fig, theme_settings, series, slice4) : nothing

    total_frames = length(series) * frames.hold
    plot_obj = Ref{Any}(nothing)
    current = Ref(0)
    progress = show_render_progress ?
               Progress(total_frames; desc=CURRENT_RENDER_PROGRESS_DESCRIPTION,
                   showspeed=CURRENT_RENDER_PROGRESS_SHOWSPEED) : nothing
    record(fig, path, 1:total_frames; framerate=framerate) do frame
        apply_camera_settings!(ax, camera_spec, frame, total_frames)
        i = div(frame - 1, frames.hold) + 1
        if current[] != i
            delete_plot_obj!(ax, plot_obj[])
            setup = setups[i]
            plot_obj[] = plot_animation_slice!(ax, @view(setup.display_field[:, :, :, slice4]),
                setup, setup.levels;
                a=scale.a,
                lattice_size=(NX, NY, NZ),
                x_physical=scene.x_physical,
                y_physical=scene.y_physical,
                z_physical=scene.z_physical)
            limits!(ax, scene.axis_limits...)
            ax.title = @sprintf("%s, t/a^2 = %.4g", base_title, series.flow_times[i])
            if overlay !== nothing
                overlay.label[] = flow_time_label(series, i, slice4)
                overlay.points[] = flow_progress_points(flow_progress_fraction(series, i))
            end
            current[] = i
        end
        progress === nothing || next!(progress)
    end

    metadata = Dict{String,Any}(
        "schema_version" => 1,
        "interpretation" => Dict(
            "spacetime" => "Euclidean lattice configuration",
            "frame_sequence" => "gradient flow time at a fixed fourth-direction slice",
            "not_real_time_minkowski_evolution" => true,
            "screen_time_label" => false,
        ),
        "configuration" => Dict("lattice_size" => [NX, NY, NZ, NT], "beta" => beta),
        "observable" => first(series.fields).info,
        "series" => series.info,
        "flow" => Dict("flow_times" => series.flow_times),
        "frame_selection" => Dict(
            "frame_mode" => "flow_sweep",
            "fixed_slice4" => slice4,
            "hold_frames" => frames.hold,
            "level_policy" => String(frames.levels),
        ),
        "level_selection" => [setup.level_selection_info for setup in setups],
        "frame_map" => [Dict(
            "frame" => frame,
            "flow_index" => div(frame - 1, frames.hold) + 1,
            "flow_time" => series.flow_times[div(frame - 1, frames.hold) + 1],
            "slice4" => slice4,
        ) for frame in 1:total_frames],
        "render" => merge(
            Dict(
                "output" => String(path),
                "metadata_output" => String(metadata_filename),
                "framerate" => framerate,
                "frame_count" => total_frames,
                "duration_seconds" => total_frames / framerate,
                "figure_size" => collect(validate_figure_size(figure_size)),
                "title" => base_title,
                "show_flow_progress" => show_flow_progress,
                "length_unit" => String(scale.length_unit),
                "lattice_spacing" => scale.a,
            ),
            render_theme_metadata(effective_theme),
            first(setups).render_style_info,
            camera_motion_metadata(camera_spec),
        ),
    )
    return finalize_animation_output(path, metadata_filename, metadata)
end

export FieldSeries, flow_series, load_field_series, resample, FlowSweep
