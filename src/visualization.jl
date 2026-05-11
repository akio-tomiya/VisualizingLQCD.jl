#include("header.jl")
#include("constants.jl")

# - A. Tomiya 2025/01/11

function automatic_level2(plaqs_t)
    summary = legacy_level_summary(plaqs_t)
    print_legacy_level_summary(summary)
    return summary.level, summary.isorange, summary.min, summary.max
end

GLMakie.activate!()
# set constants
const myxlabel = L"$x$ [fm]"
const myylabel = L"$y$ [fm]"
const myzlabel = L"$z$ [fm]"
const r_0 = CURRENT_R0_FM

# hep-lat/9806005
function ln_a(beta::Float64)::Float64
    beta_min, beta_max = CURRENT_BETA_RANGE
    if beta < beta_min || beta > beta_max
        throw(ArgumentError("Beta should be in the range [$beta_min, $beta_max]"))
    end
    delta_beta = beta - 6
    c0, c1, c2, c3 = CURRENT_LN_A_COEFFS
    return c0 + c1 * delta_beta + c2 * delta_beta^2 + c3 * delta_beta^3
end

function calculate_a(beta::Float64)::Float64
    return r_0 * exp(ln_a(beta))
end

function plaquette_display_level_setup(raw_plaqs_t;
    level_target::Symbol=LEVEL_TARGET_LEGACY_NEGLOG_HIGH,
    raw_high_level_quantiles=nothing,
    raw_high_color_quantiles=nothing,
    render_style=RENDER_STYLE_CURRENT,
    render_alpha=nothing,
    render_transparency=nothing)
    if level_target == LEVEL_TARGET_LEGACY_NEGLOG_HIGH
        render_style == RENDER_STYLE_CURRENT ||
            throw(ArgumentError("render_style=$render_style requires level_target raw_high"))
        display_field = transform_field_neglog(raw_plaqs_t)
        level_summary = legacy_level_summary(display_field)
        levels = legacy_mean_std_levels(level_summary)
        contour_style = legacy_contour_style()
        return (
            render_kind=:contour,
            display_field=display_field,
            level_summary=level_summary,
            levels=levels,
            display_transform_info=display_transform_metadata(),
            level_selection_info=level_selection_metadata(levels, level_summary),
            contour_style=contour_style,
            render_style_info=contour_style.metadata,
            observable_info=plaquette_plane_observable_metadata(),
            title=DEFAULT_MOVIE_TITLE,
        )
    elseif level_target == LEVEL_TARGET_RAW_HIGH
        level_quantiles = something(
            raw_high_level_quantiles, default_raw_high_level_quantiles(render_style))
        color_quantiles = something(
            raw_high_color_quantiles, default_raw_high_color_quantiles(render_style))
        display_field = copy(raw_plaqs_t)
        level_summary = legacy_level_summary(display_field)
        levels = raw_high_quantile_levels(display_field; quantiles=level_quantiles)
        contour_style = raw_high_contour_style_for_render(display_field, render_style;
            color_quantiles=color_quantiles,
            alpha=render_alpha,
            transparency=render_transparency)
        return (
            render_kind=:contour,
            display_field=display_field,
            level_summary=level_summary,
            levels=levels,
            display_transform_info=raw_display_transform_metadata(),
            level_selection_info=raw_high_level_selection_metadata(
                levels, level_summary; quantiles=level_quantiles),
            contour_style=contour_style,
            render_style_info=contour_style.metadata,
            observable_info=plaquette_plane_observable_metadata(),
            title=RAW_HIGH_MOVIE_TITLE,
        )
    else
        throw(ArgumentError("unsupported level_target: $level_target"))
    end
end

function topological_charge_display_level_setup(density_t;
    style_preset=CURRENT_TOPOLOGICAL_CHARGE_STYLE_PRESET,
    level_quantiles=nothing,
    color_quantile=nothing,
    render_style=RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED,
    render_alpha=nothing,
    render_transparency=nothing)

    render_style in (RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED,
        RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME) ||
        throw(ArgumentError("topological charge density requires render_style=$RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED or $RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME"))
    preset_settings = topological_charge_style_preset_settings(style_preset)
    effective_level_quantiles = something(
        level_quantiles, default_topological_charge_level_quantiles(
            preset_settings, render_style))
    effective_color_quantile = something(
        color_quantile, default_topological_charge_color_quantile(
            preset_settings, render_style))
    display_field = copy(density_t)
    level_summary = legacy_level_summary(display_field)
    levels = signed_symmetric_levels(display_field; quantiles=effective_level_quantiles)
    level_selection_info = topological_charge_level_selection_metadata(
        levels, level_summary; quantiles=effective_level_quantiles)
    observable_info = topological_charge_density_observable_metadata()
    if render_style == RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME
        positive_body_level = smallest_positive_level(levels)
        negative_body_level = smallest_negative_magnitude_level(levels)
        color_abs_ceiling = maximum(abs.(signed_symmetric_color_range(
            display_field; quantile_level=effective_color_quantile)))
        positive_color_range =
            topological_charge_volume_color_range(positive_body_level, color_abs_ceiling)
        negative_color_range =
            topological_charge_volume_color_range(negative_body_level, color_abs_ceiling)
        alpha = something(render_alpha, CURRENT_TOPOLOGICAL_CHARGE_ALPHA)
        transparency = something(render_transparency, false)
        render_style_info = topological_charge_volume_style_metadata(
            style_preset=preset_settings.style_preset,
            positive_body_level=positive_body_level,
            negative_body_level=negative_body_level,
            level_quantiles=effective_level_quantiles,
            color_quantile=effective_color_quantile,
            positive_color_range=positive_color_range,
            negative_color_range=negative_color_range,
            alpha=alpha,
            transparency=transparency)
        return (
            render_kind=:mesh,
            mesh_renderer=:topological_charge_volume,
            display_field=display_field,
            level_summary=level_summary,
            levels=levels,
            positive_body_level=positive_body_level,
            negative_body_level=negative_body_level,
            positive_color_range=positive_color_range,
            negative_color_range=negative_color_range,
            positive_color_palette=CURRENT_TOPOLOGICAL_CHARGE_VOLUME_POSITIVE_PALETTE,
            negative_color_palette=CURRENT_TOPOLOGICAL_CHARGE_VOLUME_NEGATIVE_PALETTE,
            color_radius=CURRENT_TOPOLOGICAL_CHARGE_VOLUME_COLOR_RADIUS,
            color_stat=CURRENT_TOPOLOGICAL_CHARGE_VOLUME_COLOR_STAT,
            color_top_fraction=CURRENT_TOPOLOGICAL_CHARGE_VOLUME_COLOR_TOP_FRACTION,
            color_gamma=CURRENT_TOPOLOGICAL_CHARGE_VOLUME_COLOR_GAMMA,
            alpha=alpha,
            transparency=transparency,
            display_transform_info=topological_charge_display_transform_metadata(),
            level_selection_info=level_selection_info,
            render_style_info=render_style_info,
            observable_info=observable_info,
            title=TOPOLOGICAL_CHARGE_DENSITY_MOVIE_TITLE,
        )
    end

    contour_style = topological_charge_signed_contour_style(display_field;
        color_quantile=effective_color_quantile,
        colormap=preset_settings.colormap,
        alpha=something(render_alpha, preset_settings.alpha),
        transparency=something(render_transparency, preset_settings.transparency))
    render_style_info = copy(contour_style.metadata)
    render_style_info["style_preset"] = String(preset_settings.style_preset)
    return (
        render_kind=:contour,
        display_field=display_field,
        level_summary=level_summary,
        levels=levels,
        display_transform_info=topological_charge_display_transform_metadata(),
        level_selection_info=level_selection_info,
        contour_style=contour_style,
        render_style_info=render_style_info,
        observable_info=observable_info,
        title=TOPOLOGICAL_CHARGE_DENSITY_MOVIE_TITLE,
    )
end

function mesh_renderer_kind(setup)
    if hasproperty(setup, :mesh_renderer)
        return setup.mesh_renderer
    end
    return :action_density_blob
end

function mesh_geometry_for_slice(data, setup; a, lattice_size)
    renderer = mesh_renderer_kind(setup)
    if renderer == :topological_charge_volume
        return topological_charge_volume_geometry(data, setup; a=a, lattice_size=lattice_size)
    elseif renderer == :action_density_blob
        return action_density_blob_geometry(data, setup; a=a, lattice_size=lattice_size)
    end
    throw(ArgumentError("unsupported mesh renderer: $renderer"))
end

function mesh_geometry_for_render_slice(data, setup; a, lattice_size, mesh_cache=nothing,
    slice4=nothing)

    if mesh_cache === nothing
        return mesh_geometry_for_slice(data, setup; a=a, lattice_size=lattice_size)
    end
    slice4 === nothing &&
        throw(ArgumentError("slice4 is required when mesh_cache is provided"))
    return get!(mesh_cache, slice4) do
        mesh_geometry_for_slice(data, setup; a=a, lattice_size=lattice_size)
    end
end

function mesh_plot_geometry!(ax, geometry, setup)
    renderer = mesh_renderer_kind(setup)
    if renderer == :topological_charge_volume
        return topological_charge_volume_plot!(ax, geometry)
    elseif renderer == :action_density_blob
        return action_density_blob_plot!(ax, geometry)
    end
    throw(ArgumentError("unsupported mesh renderer: $renderer"))
end

function delete_plot_obj!(ax, obj)
    obj === nothing && return nothing
    if obj isa AbstractVector
        for item in obj
            delete!(ax, item)
        end
    else
        delete!(ax, obj)
    end
    return nothing
end

function contour_plot_group!(ax, data, group_levels, contour_style;
    x_physical, y_physical, z_physical)

    objects = Any[]
    for spec in contour_plot_specs(contour_style, group_levels)
        contour_kwargs = contour_plot_kwargs(spec.style, spec.levels)
        push!(objects, GLMakie.contour!(
            ax, x_physical, y_physical, z_physical, data; contour_kwargs...))
    end
    return objects
end

function plot_animation_slice!(ax, data, display_setup, levels; a, lattice_size,
    x_physical, y_physical, z_physical, mesh_cache=nothing, slice4=nothing)

    if display_setup.render_kind == :mesh
        geometry = mesh_geometry_for_render_slice(data, display_setup;
            a=a, lattice_size=lattice_size, mesh_cache=mesh_cache, slice4=slice4)
        plot_obj, _ = mesh_plot_geometry!(ax, geometry, display_setup)
        return plot_obj
    end
    return contour_plot_group!(ax, data, levels, display_setup.contour_style;
        x_physical=x_physical, y_physical=y_physical, z_physical=z_physical)
end

function animation_render_plan(NT::Integer, display_setup, camera;
    framerate=nothing,
    nloops=nothing,
    frame_mode=nothing,
    fixed_slice4=CURRENT_FIXED_SLICE4,
    slice_hold_frames=CURRENT_SLICE_HOLD_FRAMES,
    cache_render_slices=CURRENT_CACHE_RENDER_SLICES,
    figure_size=CURRENT_FIGURE_SIZE,
    show_render_progress=CURRENT_SHOW_RENDER_PROGRESS,
    show_axis_labels=CURRENT_SHOW_AXIS_LABELS)

    effective_framerate = framerate !== nothing ? framerate :
                          (camera.motion == CAMERA_MOTION_ORBIT ?
                           CURRENT_CAMERA_ORBIT_FRAMERATE : CURRENT_MOVIE_FRAMERATE)
    effective_framerate > 0 || throw(ArgumentError("framerate should be positive"))
    effective_frame_mode = frame_mode === nothing ? default_frame_mode(camera.motion) :
                           validate_frame_mode(frame_mode)
    effective_slice_hold_frames = validate_slice_hold_frames(slice_hold_frames)
    effective_nloops = nloops === nothing ?
                       default_movie_nloops(NT, effective_framerate, camera;
                           frame_mode=effective_frame_mode,
                           slice_hold_frames=effective_slice_hold_frames) : nloops
    effective_nloops isa Integer || throw(ArgumentError("nloops should be an integer"))
    effective_nloops > 0 || throw(ArgumentError("nloops should be positive"))
    slice4_for_frame(1, NT; frame_mode=effective_frame_mode, fixed_slice4=fixed_slice4,
        slice_hold_frames=effective_slice_hold_frames)
    cache_render_slices isa Bool || throw(ArgumentError("cache_render_slices should be Bool"))
    effective_figure_size = validate_figure_size(figure_size)
    effective_show_render_progress = validate_show_render_progress(show_render_progress)
    effective_show_axis_labels = validate_show_axis_labels(show_axis_labels)
    cache_active = cache_render_slices && display_setup.render_kind == :mesh
    total_frames = total_movie_frames(NT, effective_nloops;
        frame_mode=effective_frame_mode, slice_hold_frames=effective_slice_hold_frames)

    return (
        framerate=effective_framerate,
        nloops=effective_nloops,
        frame_mode=effective_frame_mode,
        fixed_slice4=fixed_slice4,
        slice_hold_frames=effective_slice_hold_frames,
        figure_size=effective_figure_size,
        show_render_progress=effective_show_render_progress,
        show_axis_labels=effective_show_axis_labels,
        cache_active=cache_active,
        total_frames=total_frames,
        fixed_frame=effective_frame_mode == FRAME_MODE_FIXED,
    )
end

function animation_axis_tick_spec(N::Integer, a::Real; show_axis_labels::Bool)
    positions = range(0, stop=a * N, length=N)
    labels = [string(round(x, digits=CURRENT_TICK_DIGITS)) for x in positions]
    for i in 1:CURRENT_TICK_STRIDE:length(labels)
        labels[i] = ""
    end
    show_axis_labels || fill!(labels, "")
    return (positions=positions, labels=labels)
end

function animation_axis_kwargs(display_setup, theme_settings, camera;
    a, lattice_size, movie_title, show_axis_labels::Bool)

    NX, NY, NZ = lattice_size
    x_ticks = animation_axis_tick_spec(NX, a; show_axis_labels=show_axis_labels)
    y_ticks = animation_axis_tick_spec(NY, a; show_axis_labels=show_axis_labels)
    z_ticks = animation_axis_tick_spec(NZ, a; show_axis_labels=show_axis_labels)
    axis_aspect = display_setup.render_kind == :mesh ? :data : CURRENT_ASPECT
    axis_kwargs = Dict{Symbol,Any}(
        :xlabel => show_axis_labels ? myxlabel : "",
        :ylabel => show_axis_labels ? myylabel : "",
        :zlabel => show_axis_labels ? myzlabel : "",
        :title => movie_title,
        :xticks => (x_ticks.positions, x_ticks.labels),
        :yticks => (y_ticks.positions, y_ticks.labels),
        :zticks => (z_ticks.positions, z_ticks.labels),
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
    camera.azimuth === nothing || (axis_kwargs[:azimuth] = camera.azimuth)
    camera.elevation === nothing || (axis_kwargs[:elevation] = camera.elevation)
    camera.perspectiveness === nothing ||
        (axis_kwargs[:perspectiveness] = camera.perspectiveness)
    camera.viewmode === nothing || (axis_kwargs[:viewmode] = camera.viewmode)
    return axis_kwargs
end

function animation_spatial_coordinates(a::Real, lattice_size)
    NX, NY, NZ = lattice_size
    return (
        x_physical=(a, a * NX),
        y_physical=(a, a * NY),
        z_physical=(a, a * NZ),
        axis_limits=(0, a * NX, 0, a * NY, 0, a * NZ),
    )
end

function initialize_animation_scene(display_setup, theme_settings, camera;
    a, lattice_size, movie_title, figure_size, show_axis_labels::Bool)

    coordinates = animation_spatial_coordinates(a, lattice_size)
    fig = Figure(size=figure_size, backgroundcolor=theme_settings.figure_background)
    axis_kwargs = animation_axis_kwargs(display_setup, theme_settings, camera;
        a=a,
        lattice_size=lattice_size,
        movie_title=movie_title,
        show_axis_labels=show_axis_labels)
    ax = Axis3(fig[1, 1]; axis_kwargs...)
    limits!(ax, coordinates.axis_limits...)
    return (
        fig=fig,
        ax=ax,
        x_physical=coordinates.x_physical,
        y_physical=coordinates.y_physical,
        z_physical=coordinates.z_physical,
        axis_limits=coordinates.axis_limits,
    )
end

function animation_draw_context()
    return (
        plot_obj=Ref{Any}(nothing),
        current_slice4=Ref{Union{Nothing,Int}}(nothing),
        mesh_cache=Dict{Int,Any}(),
    )
end

function record_animation_frames!(fig, ax, videoname, NT, camera, draw_slice!,
    current_slice4, render_plan)

    render_plan.fixed_frame && draw_slice!(render_plan.fixed_slice4)
    render_progress = render_plan.show_render_progress ?
                      Progress(render_plan.total_frames;
                          desc=CURRENT_RENDER_PROGRESS_DESCRIPTION,
                          showspeed=CURRENT_RENDER_PROGRESS_SHOWSPEED) :
                      nothing
    record(fig, videoname, 1:render_plan.total_frames;
        framerate=render_plan.framerate) do i
        apply_camera_settings!(ax, camera, i, render_plan.total_frames)
        if !render_plan.fixed_frame
            slice4 = slice4_for_frame(i, NT;
                frame_mode=render_plan.frame_mode,
                fixed_slice4=render_plan.fixed_slice4,
                slice_hold_frames=render_plan.slice_hold_frames)
            current_slice4[] == slice4 || draw_slice!(slice4)
        end
        render_progress === nothing || next!(render_progress)
    end
    return nothing
end

function animation_display_setup_for_gaugefield(U, NX, NY, NZ, NT, NC;
    level_target=CURRENT_LEVEL_TARGET,
    render_style=nothing,
    raw_high_level_quantiles=nothing,
    raw_high_color_quantiles=nothing,
    topological_level_quantiles=nothing,
    topological_color_quantile=nothing,
    topological_style_preset=CURRENT_TOPOLOGICAL_CHARGE_STYLE_PRESET,
    render_alpha=nothing,
    render_transparency=nothing)

    effective_render_style = something(render_style,
        default_render_style_for_level_target(level_target))

    if level_target == LEVEL_TARGET_ACTION_DENSITY_HIGH
        effective_render_style == RENDER_STYLE_ACTION_DENSITY_BLOB ||
            throw(ArgumentError("level_target=$level_target requires render_style=$RENDER_STYLE_ACTION_DENSITY_BLOB"))
        action_density_t = local_action_density(U, NX, NY, NZ, NT, NC)
        return (
            display_setup=action_density_blob_display_setup(action_density_t),
            render_style=effective_render_style,
        )
    elseif level_target == LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY
        effective_render_style in (RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED,
            RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME) ||
            throw(ArgumentError("level_target=$level_target requires render_style=$RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED or $RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME"))
        density_t = topological_charge_density(U, NX, NY, NZ, NT, NC)
        return (
            display_setup=topological_charge_display_level_setup(density_t;
                style_preset=topological_style_preset,
                level_quantiles=topological_level_quantiles,
                color_quantile=topological_color_quantile,
                render_style=effective_render_style,
                render_alpha=render_alpha,
                render_transparency=render_transparency),
            render_style=effective_render_style,
        )
    end

    raw_plaqs_t = plaquette_plane_deviation(U, NX, NY, NZ, NT, NC)
    return (
        display_setup=plaquette_display_level_setup(raw_plaqs_t;
            level_target=level_target,
            raw_high_level_quantiles=raw_high_level_quantiles,
            raw_high_color_quantiles=raw_high_color_quantiles,
            render_style=effective_render_style,
            render_alpha=render_alpha,
            render_transparency=render_transparency),
        render_style=effective_render_style,
    )
end

function initialize_animation_gaugefield(NX, NY, NZ, NT, NC;
    nwing=CURRENT_NWING,
    condition=CURRENT_GENERATION_INITIAL_CONDITION)

    return Initialize_Gaugefields(NC, nwing, NX, NY, NZ, NT; condition=condition)
end

function load_animation_gaugefield(filename, NX, NY, NZ, NT, NC;
    nwing=CURRENT_NWING,
    condition=CURRENT_GENERATION_INITIAL_CONDITION)

    U = initialize_animation_gaugefield(NX, NY, NZ, NT, NC;
        nwing=nwing, condition=condition)
    ildg = ILDG(filename)
    load_gaugefield!(U, 1, ildg, [NX, NY, NZ, NT], NC)
    return U
end

function animation_metadata_for_render(; videoname, metadata_filename, filename,
    lattice_size, nc, beta, flow_steps, display_setup, render_theme, render_plan,
    camera, mesh_cache)

    return animation_metadata(
        videoname=videoname,
        metadata_filename=metadata_filename,
        filename=filename,
        lattice_size=lattice_size,
        nc=nc,
        beta=beta,
        flow_steps=flow_steps,
        levels=display_setup.levels,
        level_summary=display_setup.level_summary,
        framerate=render_plan.framerate,
        nloops=render_plan.nloops,
        title=display_setup.title,
        figure_size=render_plan.figure_size,
        frame_mode=render_plan.frame_mode,
        fixed_slice4=render_plan.fixed_slice4,
        slice_hold_frames=render_plan.slice_hold_frames,
        display_transform_info=display_setup.display_transform_info,
        level_selection_info=display_setup.level_selection_info,
        render_style_info=display_setup.render_style_info,
        render_theme_info=render_theme_metadata(render_theme),
        render_progress_info=render_progress_metadata(render_plan.show_render_progress),
        render_axis_info=render_axis_metadata(render_plan.show_axis_labels),
        camera_info=camera_motion_metadata(camera),
        render_cache_info=Dict(
            "cache_render_slices" => render_plan.cache_active,
            "cached_slice_count" => length(mesh_cache),
            "cache_key" => "slice4",
        ),
        observable_info=display_setup.observable_info,
    )
end

function finalize_animation_output(videoname, metadata_filename, metadata)
    write_animation_metadata(metadata_filename, metadata)
    return (video=videoname, metadata=metadata_filename)
end

function create_animation(NX, NY, NZ, NT, NC, videoname;
    beta=CURRENT_BETA_ANIMATION_DEFAULT,
    flow_steps_in=CURRENT_FLOW_STEPS_ANIMATION_DEFAULT,
    filename=CURRENT_FILENAME_DEFAULT,
    metadata_filename=default_metadata_filename(videoname),
    level_target=CURRENT_LEVEL_TARGET,
    raw_high_level_quantiles=nothing,
    raw_high_color_quantiles=nothing,
    topological_level_quantiles=nothing,
    topological_color_quantile=nothing,
    topological_style_preset=CURRENT_TOPOLOGICAL_CHARGE_STYLE_PRESET,
    render_style=nothing,
    render_alpha=nothing,
    render_transparency=nothing,
    render_theme=nothing,
    cache_render_slices=CURRENT_CACHE_RENDER_SLICES,
    figure_size=CURRENT_FIGURE_SIZE,
    framerate=nothing,
    nloops=nothing,
    frame_mode=nothing,
    fixed_slice4=CURRENT_FIXED_SLICE4,
    slice_hold_frames=CURRENT_SLICE_HOLD_FRAMES,
    camera_motion=CURRENT_CAMERA_MOTION,
    camera_azimuth=nothing,
    camera_elevation=nothing,
    camera_orbit_turns=CURRENT_CAMERA_ORBIT_TURNS,
    camera_orbit_seconds=CURRENT_CAMERA_ORBIT_SECONDS,
    camera_perspectiveness=nothing,
    camera_viewmode=nothing,
    show_render_progress=CURRENT_SHOW_RENDER_PROGRESS,
    show_axis_labels=CURRENT_SHOW_AXIS_LABELS)

    #function create_animation(NX, NY, NZ, NT, NC; beta=6.1, filename="conf_00000100.ildg")
    a = calculate_a(beta)
    scale_factor = a

    U1 = load_animation_gaugefield(filename, NX, NY, NZ, NT, NC)
    display_result = animation_display_setup_for_gaugefield(U1, NX, NY, NZ, NT, NC;
        level_target=level_target,
        render_style=render_style,
        raw_high_level_quantiles=raw_high_level_quantiles,
        raw_high_color_quantiles=raw_high_color_quantiles,
        topological_level_quantiles=topological_level_quantiles,
        topological_color_quantile=topological_color_quantile,
        topological_style_preset=topological_style_preset,
        render_alpha=render_alpha,
        render_transparency=render_transparency)
    display_setup = display_result.display_setup
    effective_render_style = display_result.render_style
    plaqs_t = display_setup.display_field
    effective_theme = effective_render_theme(effective_render_style, render_theme)
    theme_settings = render_theme_settings(effective_theme)

    # show logarithm of histogram for plaquettes
    level_summary = display_setup.level_summary
    print_legacy_level_summary(level_summary)
    levels = display_setup.levels
    movie_title = display_setup.title
    camera = camera_settings(display_setup.render_kind;
        camera_motion=camera_motion,
        camera_azimuth=camera_azimuth,
        camera_elevation=camera_elevation,
        camera_orbit_turns=camera_orbit_turns,
        camera_orbit_seconds=camera_orbit_seconds,
        camera_perspectiveness=camera_perspectiveness,
        camera_viewmode=camera_viewmode)
    render_plan = animation_render_plan(NT, display_setup, camera;
        framerate=framerate,
        nloops=nloops,
        frame_mode=frame_mode,
        fixed_slice4=fixed_slice4,
        slice_hold_frames=slice_hold_frames,
        cache_render_slices=cache_render_slices,
        figure_size=figure_size,
        show_render_progress=show_render_progress,
        show_axis_labels=show_axis_labels)
    effective_figure_size = render_plan.figure_size
    effective_show_axis_labels = render_plan.show_axis_labels
    cache_active = render_plan.cache_active

    #= To check iso-level, please use here
    hist_p = histogram(vec(plaqs_t))
    vline!(hist_p, levels)
    display(hist_p)
    =#

    scene = initialize_animation_scene(display_setup, theme_settings, camera;
        a=a,
        lattice_size=(NX, NY, NZ),
        movie_title=movie_title,
        figure_size=effective_figure_size,
        show_axis_labels=effective_show_axis_labels)
    fig = scene.fig
    ax = scene.ax

    draw_context = animation_draw_context()
    plot_obj = draw_context.plot_obj
    current_slice4 = draw_context.current_slice4
    mesh_cache = draw_context.mesh_cache

    if display_setup.render_kind == :contour
        dummy_data = zeros(Float64, NX, NY, NZ)
        plot_obj[] = contour_plot_group!(ax, dummy_data, [levels[1]],
            display_setup.contour_style;
            x_physical=scene.x_physical,
            y_physical=scene.y_physical,
            z_physical=scene.z_physical)
    end

    function draw_slice!(slice4)
        delete_plot_obj!(ax, plot_obj[])

        plaqs = @view plaqs_t[:, :, :, slice4]
        ax.title = movie_title
        plot_obj[] = plot_animation_slice!(ax, plaqs, display_setup, levels;
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

    metadata = animation_metadata_for_render(
        videoname=videoname,
        metadata_filename=metadata_filename,
        filename=filename,
        lattice_size=(NX, NY, NZ, NT),
        nc=NC,
        beta=beta,
        flow_steps=flow_steps_in,
        display_setup=display_setup,
        render_theme=effective_theme,
        render_plan=render_plan,
        camera=camera,
        mesh_cache=mesh_cache)
    return finalize_animation_output(videoname, metadata_filename, metadata)
end

export create_animation
