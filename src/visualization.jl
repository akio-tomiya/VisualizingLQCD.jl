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

function create_animation(NX, NY, NZ, NT, NC, videoname;
    beta=CURRENT_BETA_ANIMATION_DEFAULT,
    flow_steps_in=CURRENT_FLOW_STEPS_ANIMATION_DEFAULT,
    filename=CURRENT_FILENAME_DEFAULT,
    metadata_filename=default_metadata_filename(videoname),
    level_target=CURRENT_LEVEL_TARGET,
    raw_high_level_quantiles=nothing,
    raw_high_color_quantiles=nothing,
    render_style=nothing,
    render_alpha=nothing,
    render_transparency=nothing,
    render_theme=nothing,
    framerate=nothing,
    nloops=nothing,
    frame_mode=nothing,
    fixed_slice4=CURRENT_FIXED_SLICE4,
    camera_motion=CURRENT_CAMERA_MOTION,
    camera_azimuth=nothing,
    camera_elevation=nothing,
    camera_orbit_turns=CURRENT_CAMERA_ORBIT_TURNS,
    camera_orbit_seconds=CURRENT_CAMERA_ORBIT_SECONDS,
    camera_perspectiveness=nothing,
    camera_viewmode=nothing)

    #function create_animation(NX, NY, NZ, NT, NC; beta=6.1, filename="conf_00000100.ildg")
    Nwing = CURRENT_NWING
    a = calculate_a(beta)
    scale_factor = a

    U1 = Initialize_Gaugefields(
        NC, Nwing, NX, NY, NZ, NT, condition=CURRENT_GENERATION_INITIAL_CONDITION)
    ildg = ILDG(filename)
    load_gaugefield!(U1, 1, ildg, [NX, NY, NZ, NT], NC)
    effective_render_style = something(render_style,
        default_render_style_for_level_target(level_target))

    if level_target == LEVEL_TARGET_ACTION_DENSITY_HIGH
        effective_render_style == RENDER_STYLE_ACTION_DENSITY_BLOB ||
            throw(ArgumentError("level_target=$level_target requires render_style=$RENDER_STYLE_ACTION_DENSITY_BLOB"))
        action_density_t = local_action_density(U1, NX, NY, NZ, NT, NC)
        display_setup = action_density_blob_display_setup(action_density_t)
    else
        # Calculating field strength using plaquette.
        # In precise, we need 1/β.
        raw_plaqs_t = plaquette_plane_deviation(U1, NX, NY, NZ, NT, NC)
        display_setup = plaquette_display_level_setup(raw_plaqs_t;
            level_target=level_target,
            raw_high_level_quantiles=raw_high_level_quantiles,
            raw_high_color_quantiles=raw_high_color_quantiles,
            render_style=effective_render_style,
            render_alpha=render_alpha,
            render_transparency=render_transparency)
    end
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
    effective_framerate = framerate !== nothing ? framerate :
                          (camera.motion == CAMERA_MOTION_ORBIT ?
                           CURRENT_CAMERA_ORBIT_FRAMERATE : CURRENT_MOVIE_FRAMERATE)
    effective_framerate > 0 || throw(ArgumentError("framerate should be positive"))
    effective_nloops = nloops === nothing ? default_movie_nloops(NT, effective_framerate, camera) : nloops
    effective_nloops isa Integer || throw(ArgumentError("nloops should be an integer"))
    effective_nloops > 0 || throw(ArgumentError("nloops should be positive"))
    effective_frame_mode = frame_mode === nothing ? default_frame_mode(camera.motion) :
                           validate_frame_mode(frame_mode)
    slice4_for_frame(1, NT; frame_mode=effective_frame_mode, fixed_slice4=fixed_slice4)

    #= To check iso-level, please use here
    hist_p = histogram(vec(plaqs_t))
    vline!(hist_p, levels)
    display(hist_p)
    =#

    # Set coordinate
    x_physical = (a, a * NX)
    y_physical = (a, a * NY)
    z_physical = (a, a * NZ)

    fig = Figure(
        size=CURRENT_FIGURE_SIZE,
        backgroundcolor=theme_settings.figure_background)
    # label setting.
    x_positions = range(0, stop=a * NX, length=NX)
    x_labels = [string(round(x, digits=CURRENT_TICK_DIGITS)) for x in x_positions]

    y_positions = range(0, stop=a * NY, length=NY)
    y_labels = [string(round(y, digits=CURRENT_TICK_DIGITS)) for y in y_positions]

    z_positions = range(0, stop=a * NZ, length=NZ)
    z_labels = [string(round(z, digits=CURRENT_TICK_DIGITS)) for z in z_positions]

    for i in 1:CURRENT_TICK_STRIDE:length(x_labels)
        x_labels[i] = ""
    end
    for i in 1:CURRENT_TICK_STRIDE:length(y_labels)
        y_labels[i] = ""
    end
    for i in 1:CURRENT_TICK_STRIDE:length(z_labels)
        z_labels[i] = ""
    end

    axis_aspect = display_setup.render_kind == :mesh ? :data : CURRENT_ASPECT
    axis_kwargs = Dict{Symbol,Any}(
        :xlabel => myxlabel,
        :ylabel => myylabel,
        :zlabel => myzlabel,
        :title => movie_title,
        :xticks => (x_positions, x_labels),
        :yticks => (y_positions, y_labels),
        :zticks => (z_positions, z_labels),
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

    # Make Axis3
    ax = Axis3(fig[1, 1]; axis_kwargs...)
    limits!(ax, 0, a * NX, 0, a * NY, 0, a * NZ)

    plot_obj = Ref{Any}(nothing)
    if display_setup.render_kind == :contour
        dummy_data = zeros(Float64, NX, NY, NZ)
        dummy_kwargs = contour_plot_kwargs(display_setup.contour_style, [levels[1]])
        plot_obj[] = GLMakie.contour!(ax, x_physical, y_physical, z_physical, dummy_data;
            dummy_kwargs...)
    end

    function draw_slice!(slice4)
        if plot_obj[] !== nothing
            delete!(ax, plot_obj[])
        end

        plaqs = plaqs_t[:, :, :, slice4]
        ax.title = movie_title

        if display_setup.render_kind == :mesh
            plot_obj[], _ = action_density_blob_plot!(ax, plaqs, display_setup;
                a=a, lattice_size=(NX, NY, NZ))
        else
            contour_kwargs = contour_plot_kwargs(display_setup.contour_style, levels)
            plot_obj[] = GLMakie.contour!(ax, x_physical, y_physical, z_physical, plaqs;
                contour_kwargs...)
        end
        limits!(ax, 0, a * NX, 0, a * NY, 0, a * NZ)
        return nothing
    end

    t_end = NT * effective_nloops
    fixed_frame = effective_frame_mode == FRAME_MODE_FIXED
    fixed_frame && draw_slice!(fixed_slice4)
    record(fig, videoname, 1:t_end; framerate=effective_framerate) do i
        apply_camera_settings!(ax, camera, i, t_end)
        if !fixed_frame
            slice4 = slice4_for_frame(i, NT;
                frame_mode=effective_frame_mode, fixed_slice4=fixed_slice4)
            draw_slice!(slice4)
        end
    end

    metadata = animation_metadata(
        videoname=videoname,
        metadata_filename=metadata_filename,
        filename=filename,
        lattice_size=(NX, NY, NZ, NT),
        nc=NC,
        beta=beta,
        flow_steps=flow_steps_in,
        levels=levels,
        level_summary=level_summary,
        framerate=effective_framerate,
        nloops=effective_nloops,
        title=movie_title,
        frame_mode=effective_frame_mode,
        fixed_slice4=fixed_slice4,
        display_transform_info=display_setup.display_transform_info,
        level_selection_info=display_setup.level_selection_info,
        render_style_info=display_setup.render_style_info,
        render_theme_info=render_theme_metadata(effective_theme),
        camera_info=camera_motion_metadata(camera),
        observable_info=display_setup.observable_info,
    )
    write_animation_metadata(metadata_filename, metadata)
    return (video=videoname, metadata=metadata_filename)
end

export create_animation
