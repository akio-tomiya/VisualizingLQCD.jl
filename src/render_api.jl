# Rendering a LatticeField: styles, cameras, frame sequences, snapshot, movie.
#
#   snapshot("q.png", q; slice=5)                         one still image
#   movie("q.mp4", q)                                      fourth-direction slices in order
#   movie("q.mp4", q; frames=FixedSlice(5), camera=Orbit()) one slice, rotating camera
#
# The styles reuse the existing display setups and mesh/contour renderers, so
# the pictures are the same as those of create_animation.

# ---------------------------------------------------------------------------
# Styles

abstract type AbstractRenderStyle end

"""
    Blob()

Filled superlevel-set solid of an unsigned field, smoothed and colored by the
local field value (the VisualQCD / QCD Lava Lamp look). Default for unsigned fields.
"""
struct Blob <: AbstractRenderStyle end

"""
    SignedVolume(; preset=:balanced, level_quantiles=nothing, color_quantile=nothing, alpha=nothing)

Separate solids for the positive and negative parts of a signed field, with
their own palettes. Default for signed fields such as the topological charge density.
"""
Base.@kwdef struct SignedVolume <: AbstractRenderStyle
    preset::Symbol = CURRENT_TOPOLOGICAL_CHARGE_STYLE_PRESET
    level_quantiles = nothing
    color_quantile = nothing
    alpha = nothing
    transparency = nothing
end

"""
    SignedContour(; preset=:balanced, level_quantiles=nothing, color_quantile=nothing)

Iso-surfaces at symmetric positive and negative levels (GLMakie only).
"""
Base.@kwdef struct SignedContour <: AbstractRenderStyle
    preset::Symbol = CURRENT_TOPOLOGICAL_CHARGE_STYLE_PRESET
    level_quantiles = nothing
    color_quantile = nothing
    alpha = nothing
    transparency = nothing
end

"""
    LogIsosurface()

The original renderer: iso-surfaces of `-log(p + 1e-7)` at mean + 1.2σ and
above, in steps of 0.05 (GLMakie only).
"""
struct LogIsosurface <: AbstractRenderStyle end

"""
    RawIsosurface(; thermal=false, level_quantiles=nothing, color_quantiles=nothing)

Iso-surfaces of the raw field at high quantiles; `thermal=true` uses the
cyan-to-red thermal palette (GLMakie only).
"""
Base.@kwdef struct RawIsosurface <: AbstractRenderStyle
    thermal::Bool = false
    level_quantiles = nothing
    color_quantiles = nothing
    alpha = nothing
    transparency = nothing
end

default_style(field::LatticeField) = field.signed ? SignedVolume() : Blob()

render_style_symbol(::Blob) = RENDER_STYLE_ACTION_DENSITY_BLOB
render_style_symbol(::SignedVolume) = RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME
render_style_symbol(::SignedContour) = RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED
render_style_symbol(::LogIsosurface) = RENDER_STYLE_CURRENT
render_style_symbol(style::RawIsosurface) =
    style.thermal ? RENDER_STYLE_PLAQUETTE_THERMAL : RENDER_STYLE_CURRENT

display_setup(::Blob, data) = action_density_blob_display_setup(data)

function display_setup(style::Union{SignedVolume,SignedContour}, data)
    return topological_charge_display_level_setup(data;
        style_preset=style.preset,
        level_quantiles=style.level_quantiles,
        color_quantile=style.color_quantile,
        render_style=render_style_symbol(style),
        render_alpha=style.alpha,
        render_transparency=style.transparency)
end

display_setup(::LogIsosurface, data) =
    plaquette_display_level_setup(data; level_target=LEVEL_TARGET_LEGACY_NEGLOG_HIGH)

function display_setup(style::RawIsosurface, data)
    return plaquette_display_level_setup(data;
        level_target=LEVEL_TARGET_RAW_HIGH,
        raw_high_level_quantiles=style.level_quantiles,
        raw_high_color_quantiles=style.color_quantiles,
        render_style=render_style_symbol(style),
        render_alpha=style.alpha,
        render_transparency=style.transparency)
end

# Titles of the built-in fields keep the names used by create_animation.
function default_title(field::LatticeField, setup)
    field.name in ("action_density", "topological_charge_density", "plaquette_density") &&
        return setup.title
    words = split(replace(field.name, "_" => " "))
    isempty(words) && return setup.title
    return join([i == 1 ? uppercasefirst(w) : w for (i, w) in enumerate(words)], " ")
end

# ---------------------------------------------------------------------------
# Cameras and frame sequences

abstract type AbstractCamera end

"""
    StaticCamera(; azimuth=nothing, elevation=nothing, perspectiveness=nothing)

A fixed view. `nothing` keeps the style default.
"""
Base.@kwdef struct StaticCamera <: AbstractCamera
    azimuth = nothing
    elevation = nothing
    perspectiveness = nothing
end

"""
    Orbit(; turns=1.0, seconds=640/14, azimuth=nothing, elevation=nothing)

The camera turns `turns` times around the vertical axis during the movie.
"""
Base.@kwdef struct Orbit <: AbstractCamera
    turns::Float64 = CURRENT_CAMERA_ORBIT_TURNS
    seconds::Float64 = CURRENT_CAMERA_ORBIT_SECONDS
    azimuth = nothing
    elevation = nothing
    perspectiveness = nothing
    viewmode = nothing
end

camera_motion_symbol(::StaticCamera) = CAMERA_MOTION_STATIC
camera_motion_symbol(::Orbit) = CAMERA_MOTION_ORBIT

function camera_settings(render_kind::Symbol, camera::StaticCamera)
    return camera_settings(render_kind; camera_motion=CAMERA_MOTION_STATIC,
        camera_azimuth=camera.azimuth, camera_elevation=camera.elevation,
        camera_perspectiveness=camera.perspectiveness)
end

function camera_settings(render_kind::Symbol, camera::Orbit)
    return camera_settings(render_kind; camera_motion=CAMERA_MOTION_ORBIT,
        camera_azimuth=camera.azimuth, camera_elevation=camera.elevation,
        camera_orbit_turns=camera.turns, camera_orbit_seconds=camera.seconds,
        camera_perspectiveness=camera.perspectiveness, camera_viewmode=camera.viewmode)
end

abstract type AbstractFrames end

"""
    SliceSweep(; hold=1, loops=nothing)

Show the fourth-direction slices 1, 2, …, NT in order, each for `hold`
frames, `loops` times (default: once, or enough to cover an orbit).
"""
Base.@kwdef struct SliceSweep <: AbstractFrames
    hold::Int = CURRENT_SLICE_HOLD_FRAMES
    loops::Union{Nothing,Int} = nothing
end

"""
    FixedSlice(t)

Show one fourth-direction slice for the whole movie (useful with `Orbit`).
"""
struct FixedSlice <: AbstractFrames
    slice::Int
end

frame_arguments(frames::SliceSweep) = (frame_mode=FRAME_MODE_SEQUENCE,
    fixed_slice4=CURRENT_FIXED_SLICE4, slice_hold_frames=frames.hold, nloops=frames.loops)
frame_arguments(frames::FixedSlice) = (frame_mode=FRAME_MODE_FIXED,
    fixed_slice4=frames.slice, slice_hold_frames=CURRENT_SLICE_HOLD_FRAMES, nloops=nothing)

# Lattice spacing in fm: explicit, from beta (hep-lat/9806005), or lattice units.
function resolve_spacing(spacing, beta)
    spacing !== nothing && return (a=Float64(spacing), length_unit=:fm)
    beta !== nothing && return (a=calculate_a(Float64(beta)), length_unit=:fm)
    return (a=1.0, length_unit=:lattice)
end

# ---------------------------------------------------------------------------
# Rendering core shared by movie and create_animation

function render_field_movie(field::LatticeField, videoname::AbstractString;
    setup,
    render_style::Symbol,
    camera,
    a::Real,
    length_unit::Symbol=:fm,
    title,
    frame_mode=nothing,
    fixed_slice4=CURRENT_FIXED_SLICE4,
    slice_hold_frames=CURRENT_SLICE_HOLD_FRAMES,
    nloops=nothing,
    framerate=nothing,
    render_theme=nothing,
    cache_render_slices=CURRENT_CACHE_RENDER_SLICES,
    figure_size=CURRENT_FIGURE_SIZE,
    show_render_progress=CURRENT_SHOW_RENDER_PROGRESS,
    show_axis_labels=CURRENT_SHOW_AXIS_LABELS,
    metadata_filename=default_metadata_filename(videoname),
    source=Dict{String,Any}())

    NX, NY, NZ, NT = size(field)
    data_t = field.data
    effective_theme = effective_render_theme(render_style, render_theme)
    theme_settings = render_theme_settings(effective_theme)
    levels = setup.levels
    render_plan = animation_render_plan(NT, setup, camera;
        framerate=framerate,
        nloops=nloops,
        frame_mode=frame_mode,
        fixed_slice4=fixed_slice4,
        slice_hold_frames=slice_hold_frames,
        cache_render_slices=cache_render_slices,
        figure_size=figure_size,
        show_render_progress=show_render_progress,
        show_axis_labels=show_axis_labels)
    cache_active = render_plan.cache_active

    scene = initialize_animation_scene(setup, theme_settings, camera;
        a=a,
        lattice_size=(NX, NY, NZ),
        movie_title=title,
        figure_size=render_plan.figure_size,
        show_axis_labels=render_plan.show_axis_labels,
        length_unit=length_unit)
    fig = scene.fig
    ax = scene.ax

    draw_context = animation_draw_context()
    plot_obj = draw_context.plot_obj
    current_slice4 = draw_context.current_slice4
    mesh_cache = draw_context.mesh_cache

    function draw_slice!(slice4)
        delete_plot_obj!(ax, plot_obj[])
        slice_data = @view setup.display_field[:, :, :, slice4]
        ax.title = title
        plot_obj[] = plot_animation_slice!(ax, slice_data, setup, levels;
            a=a,
            lattice_size=(NX, NY, NZ),
            x_physical=scene.x_physical,
            y_physical=scene.y_physical,
            z_physical=scene.z_physical,
            mesh_cache=cache_active ? mesh_cache : nothing,
            slice4=slice4)
        limits!(ax, scene.axis_limits...)
        current_slice4[] = slice4
        return nothing
    end

    record_animation_frames!(fig, ax, videoname, NT, camera, draw_slice!, current_slice4,
        render_plan)

    metadata = animation_metadata(
        videoname=videoname,
        metadata_filename=metadata_filename,
        filename=get(source, "filename", nothing),
        lattice_size=(NX, NY, NZ, NT),
        nc=get(source, "nc", nothing),
        beta=get(source, "beta", nothing),
        flow_steps=get(source, "flow_steps", nothing),
        levels=levels,
        level_summary=setup.level_summary,
        framerate=render_plan.framerate,
        nloops=render_plan.nloops,
        title=title,
        figure_size=render_plan.figure_size,
        frame_mode=render_plan.frame_mode,
        fixed_slice4=render_plan.fixed_slice4,
        slice_hold_frames=render_plan.slice_hold_frames,
        display_transform_info=setup.display_transform_info,
        level_selection_info=setup.level_selection_info,
        render_style_info=setup.render_style_info,
        render_theme_info=render_theme_metadata(effective_theme),
        render_progress_info=render_progress_metadata(render_plan.show_render_progress),
        render_axis_info=merge(render_axis_metadata(render_plan.show_axis_labels),
            Dict("length_unit" => String(length_unit), "lattice_spacing" => a)),
        camera_info=camera_motion_metadata(camera),
        render_cache_info=Dict(
            "cache_render_slices" => cache_active,
            "cached_slice_count" => length(mesh_cache),
            "cache_key" => "slice4",
        ),
        observable_info=field.info,
    )
    return finalize_animation_output(videoname, metadata_filename, metadata)
end

# ---------------------------------------------------------------------------
# Public entry points

"""
    movie(path, field; style=default_style(field), frames=SliceSweep(),
          camera=StaticCamera(), beta=nothing, spacing=nothing, theme=nothing,
          framerate=nothing, figure_size=(800, 800), title=nothing,
          show_axis_labels=true, show_render_progress=true)

Render `field` to a movie file and write a JSON sidecar `path * ".metadata.json"`.
Axes are in fm when `beta` (hep-lat/9806005 scale) or `spacing` (fm) is
given, and in lattice units otherwise. Returns `(video=path, metadata=...)`.
"""
function movie(path::AbstractString, field::LatticeField;
    style::AbstractRenderStyle=default_style(field),
    frames::AbstractFrames=SliceSweep(),
    camera::AbstractCamera=StaticCamera(),
    beta=nothing,
    spacing=nothing,
    theme=nothing,
    framerate=nothing,
    figure_size=CURRENT_FIGURE_SIZE,
    title=nothing,
    show_axis_labels::Bool=CURRENT_SHOW_AXIS_LABELS,
    show_render_progress::Bool=CURRENT_SHOW_RENDER_PROGRESS,
    cache_render_slices::Bool=CURRENT_CACHE_RENDER_SLICES,
    metadata_filename=default_metadata_filename(path),
    source=Dict{String,Any}())

    setup = display_setup(style, field.data)
    scale = resolve_spacing(spacing, beta)
    camera_spec = camera_settings(setup.render_kind, camera)
    frame_args = frame_arguments(frames)
    return render_field_movie(field, path;
        setup=setup,
        render_style=render_style_symbol(style),
        camera=camera_spec,
        a=scale.a,
        length_unit=scale.length_unit,
        title=something(title, default_title(field, setup)),
        frame_mode=frame_args.frame_mode,
        fixed_slice4=frame_args.fixed_slice4,
        slice_hold_frames=frame_args.slice_hold_frames,
        nloops=frame_args.nloops,
        framerate=framerate,
        render_theme=theme,
        cache_render_slices=cache_render_slices,
        figure_size=figure_size,
        show_render_progress=show_render_progress,
        show_axis_labels=show_axis_labels,
        metadata_filename=metadata_filename,
        source=merge(Dict{String,Any}("beta" => beta), Dict{String,Any}(source)))
end

"""
    snapshot(field; slice=1, style=default_style(field), camera=StaticCamera(),
             beta=nothing, spacing=nothing, theme=nothing, figure_size=(800, 800),
             title=nothing, show_axis_labels=true)
    snapshot(path, field; kwargs...)

Draw one fourth-direction slice and return the Makie figure; with `path`,
also save it (format from the extension, for example `.png`).
"""
function snapshot(field::LatticeField;
    slice::Integer=CURRENT_FIXED_SLICE4,
    style::AbstractRenderStyle=default_style(field),
    camera::AbstractCamera=StaticCamera(),
    beta=nothing,
    spacing=nothing,
    theme=nothing,
    figure_size=CURRENT_FIGURE_SIZE,
    title=nothing,
    show_axis_labels::Bool=CURRENT_SHOW_AXIS_LABELS)

    NX, NY, NZ, NT = size(field)
    1 <= slice <= NT || throw(ArgumentError("slice should be in 1:$NT"))
    setup = display_setup(style, field.data)
    scale = resolve_spacing(spacing, beta)
    camera_spec = camera_settings(setup.render_kind, camera)
    theme_settings = render_theme_settings(
        effective_render_theme(render_style_symbol(style), theme))
    effective_title = something(title, default_title(field, setup))
    scene = initialize_animation_scene(setup, theme_settings, camera_spec;
        a=scale.a,
        lattice_size=(NX, NY, NZ),
        movie_title=effective_title,
        figure_size=validate_figure_size(figure_size),
        show_axis_labels=show_axis_labels,
        length_unit=scale.length_unit)
    plot_animation_slice!(scene.ax, @view(setup.display_field[:, :, :, slice]), setup,
        setup.levels;
        a=scale.a,
        lattice_size=(NX, NY, NZ),
        x_physical=scene.x_physical,
        y_physical=scene.y_physical,
        z_physical=scene.z_physical)
    limits!(scene.ax, scene.axis_limits...)
    apply_camera_settings!(scene.ax, camera_spec, 1, 1)
    return scene.fig
end

function snapshot(path::AbstractString, field::LatticeField; kwargs...)
    fig = snapshot(field; kwargs...)
    save(path, fig)
    return path
end

export AbstractRenderStyle, Blob, SignedVolume, SignedContour, LogIsosurface, RawIsosurface
export AbstractCamera, StaticCamera, Orbit, AbstractFrames, SliceSweep, FixedSlice
export movie, snapshot
