function raw_high_color_range(raw_data; quantiles=CURRENT_RAW_HIGH_COLOR_QUANTILES)
    values = finite_level_values(raw_data)
    qs = collect(quantiles)
    range_values = quantile(values, qs)
    return Tuple(Float64.(range_values))
end

function contour_style_metadata(;
    render_style,
    colormap,
    alpha,
    transparency,
    color_quantity,
    color_method,
    color_quantiles=nothing,
    color_range=nothing,
)
    info = Dict(
        "render_style" => String(render_style),
        "colormap" => colormap_metadata_value(colormap),
        "alpha" => alpha,
        "transparency" => transparency,
        "color_quantity" => color_quantity,
        "color_method" => color_method,
    )
    if color_quantiles !== nothing
        info["color_quantiles"] = collect(color_quantiles)
    end
    if color_range !== nothing
        info["color_range"] = collect(color_range)
    end
    return info
end

colormap_metadata_value(colormap::Symbol) = String(colormap)
colormap_metadata_value(colormap) = [String(color) for color in colormap]

function legacy_contour_style()
    return (
        colormap=CURRENT_COLORMAP,
        colorrange=nothing,
        alpha=CURRENT_ALPHA,
        transparency=CURRENT_TRANSPARENCY,
        metadata=contour_style_metadata(
            render_style=RENDER_STYLE_CURRENT,
            colormap=CURRENT_COLORMAP,
            alpha=CURRENT_ALPHA,
            transparency=CURRENT_TRANSPARENCY,
            color_quantity="display_level",
            color_method="current_default",
        ),
    )
end

function raw_high_contour_style(raw_data;
    color_quantiles=CURRENT_RAW_HIGH_COLOR_QUANTILES,
    colormap=CURRENT_COLORMAP,
    alpha=CURRENT_RAW_HIGH_ALPHA,
    transparency=CURRENT_RAW_HIGH_TRANSPARENCY)
    color_range = raw_high_color_range(raw_data; quantiles=color_quantiles)
    return (
        colormap=colormap,
        colorrange=color_range,
        alpha=alpha,
        transparency=transparency,
        metadata=contour_style_metadata(
            render_style=RENDER_STYLE_CURRENT,
            colormap=colormap,
            alpha=alpha,
            transparency=transparency,
            color_quantity="raw_plaquette_deviation",
            color_method="quantile",
            color_quantiles=color_quantiles,
            color_range=color_range,
        ),
    )
end

function plaquette_thermal_contour_style(raw_data;
    color_quantiles=CURRENT_PLAQUETTE_THERMAL_COLOR_QUANTILES,
    colormap=CURRENT_PLAQUETTE_THERMAL_COLORMAP,
    alpha=CURRENT_PLAQUETTE_THERMAL_ALPHA,
    transparency=CURRENT_PLAQUETTE_THERMAL_TRANSPARENCY)
    color_range = raw_high_color_range(raw_data; quantiles=color_quantiles)
    return (
        colormap=collect(colormap),
        colorrange=color_range,
        alpha=alpha,
        transparency=transparency,
        metadata=contour_style_metadata(
            render_style=RENDER_STYLE_PLAQUETTE_THERMAL,
            colormap=colormap,
            alpha=alpha,
            transparency=transparency,
            color_quantity="raw_plaquette_deviation",
            color_method="quantile",
            color_quantiles=color_quantiles,
            color_range=color_range,
        ),
    )
end

function contour_plot_kwargs(style, levels)
    kwargs = Dict{Symbol,Any}(
        :levels => levels,
        :colormap => style.colormap,
        :transparency => style.transparency,
        :alpha => style.alpha,
    )
    if style.colorrange !== nothing
        kwargs[:colorrange] = style.colorrange
    end
    return kwargs
end

function default_raw_high_level_quantiles(render_style::Symbol)
    if render_style == RENDER_STYLE_CURRENT
        return CURRENT_RAW_HIGH_QUANTILES
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL
        return CURRENT_PLAQUETTE_THERMAL_LEVEL_QUANTILES
    else
        throw(ArgumentError("unsupported render_style: $render_style"))
    end
end

function default_raw_high_color_quantiles(render_style::Symbol)
    if render_style == RENDER_STYLE_CURRENT
        return CURRENT_RAW_HIGH_COLOR_QUANTILES
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL
        return CURRENT_PLAQUETTE_THERMAL_COLOR_QUANTILES
    else
        throw(ArgumentError("unsupported render_style: $render_style"))
    end
end

function raw_high_contour_style_for_render(raw_data, render_style::Symbol;
    color_quantiles,
    alpha=nothing,
    transparency=nothing)
    if render_style == RENDER_STYLE_CURRENT
        return raw_high_contour_style(raw_data;
            color_quantiles=color_quantiles,
            alpha=something(alpha, CURRENT_RAW_HIGH_ALPHA),
            transparency=something(transparency, CURRENT_RAW_HIGH_TRANSPARENCY))
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL
        return plaquette_thermal_contour_style(raw_data;
            color_quantiles=color_quantiles,
            alpha=something(alpha, CURRENT_PLAQUETTE_THERMAL_ALPHA),
            transparency=something(transparency, CURRENT_PLAQUETTE_THERMAL_TRANSPARENCY))
    else
        throw(ArgumentError("unsupported render_style: $render_style"))
    end
end

function default_render_style_for_level_target(level_target::Symbol)
    if level_target == LEVEL_TARGET_ACTION_DENSITY_HIGH
        return RENDER_STYLE_ACTION_DENSITY_BLOB
    else
        return RENDER_STYLE_CURRENT
    end
end

function effective_render_theme(render_style::Symbol, render_theme)
    if render_theme !== nothing
        return render_theme
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL ||
           render_style == RENDER_STYLE_ACTION_DENSITY_BLOB
        return RENDER_THEME_DARK
    else
        return CURRENT_RENDER_THEME
    end
end

function render_theme_settings(render_theme::Symbol)
    if render_theme == RENDER_THEME_LIGHT
        return (
            theme=render_theme,
            figure_background=:white,
            axis_background=:white,
            text_color=:black,
            grid_color=:gray,
        )
    elseif render_theme == RENDER_THEME_DARK
        return (
            theme=render_theme,
            figure_background=:black,
            axis_background=:black,
            text_color=:white,
            grid_color=:gray,
        )
    else
        throw(ArgumentError("unsupported render_theme: $render_theme"))
    end
end

function render_theme_metadata(render_theme::Symbol)
    settings = render_theme_settings(render_theme)
    return Dict(
        "render_theme" => String(settings.theme),
        "figure_background" => String(settings.figure_background),
        "axis_background" => String(settings.axis_background),
        "text_color" => String(settings.text_color),
        "grid_color" => String(settings.grid_color),
    )
end

function validate_show_render_progress(show_render_progress)
    show_render_progress isa Bool ||
        throw(ArgumentError("show_render_progress should be Bool"))
    return show_render_progress
end

function render_progress_metadata(show_render_progress::Bool)
    return Dict(
        "show_render_progress" => show_render_progress,
        "progress_description" => show_render_progress ? CURRENT_RENDER_PROGRESS_DESCRIPTION :
                                  nothing,
    )
end

function validate_figure_size(figure_size)
    length(figure_size) == 2 || throw(ArgumentError("figure_size should have two entries"))
    width, height = figure_size
    width isa Integer || throw(ArgumentError("figure_size width should be an integer"))
    height isa Integer || throw(ArgumentError("figure_size height should be an integer"))
    width > 0 || throw(ArgumentError("figure_size width should be positive"))
    height > 0 || throw(ArgumentError("figure_size height should be positive"))
    return (width, height)
end

function validate_camera_motion(camera_motion::Symbol)
    if camera_motion == CAMERA_MOTION_STATIC || camera_motion == CAMERA_MOTION_ORBIT
        return camera_motion
    end
    throw(ArgumentError("unsupported camera_motion: $camera_motion"))
end

function validate_camera_viewmode(camera_viewmode::Symbol)
    if camera_viewmode in (:fit, :fitzoom, :stretch, :free)
        return camera_viewmode
    end
    throw(ArgumentError("unsupported camera_viewmode: $camera_viewmode"))
end

function camera_settings(render_kind::Symbol; camera_motion=CURRENT_CAMERA_MOTION,
    camera_azimuth=nothing, camera_elevation=nothing,
    camera_orbit_turns=CURRENT_CAMERA_ORBIT_TURNS,
    camera_orbit_seconds=CURRENT_CAMERA_ORBIT_SECONDS,
    camera_perspectiveness=nothing,
    camera_viewmode=nothing)

    motion = validate_camera_motion(camera_motion)
    use_default_camera = render_kind == :mesh || motion != CAMERA_MOTION_STATIC
    azimuth = camera_azimuth !== nothing ? camera_azimuth :
              (use_default_camera ? CURRENT_CAMERA_AZIMUTH : nothing)
    elevation = camera_elevation !== nothing ? camera_elevation :
                (use_default_camera ? CURRENT_CAMERA_ELEVATION : nothing)
    perspectiveness = camera_perspectiveness !== nothing ? camera_perspectiveness :
                      (motion == CAMERA_MOTION_ORBIT ? CURRENT_CAMERA_ORBIT_PERSPECTIVENESS :
                       (render_kind == :mesh ? CURRENT_CAMERA_MESH_PERSPECTIVENESS : nothing))
    viewmode = camera_viewmode !== nothing ? validate_camera_viewmode(camera_viewmode) :
               (motion == CAMERA_MOTION_ORBIT ? CURRENT_CAMERA_ORBIT_VIEWMODE : nothing)
    camera_orbit_seconds > 0 ||
        throw(ArgumentError("camera_orbit_seconds should be positive"))
    if perspectiveness !== nothing
        0 <= perspectiveness <= 1 ||
            throw(ArgumentError("camera_perspectiveness should be between 0 and 1"))
    end
    return (
        motion=motion,
        azimuth=azimuth,
        elevation=elevation,
        perspectiveness=perspectiveness,
        viewmode=viewmode,
        orbit_turns=Float64(camera_orbit_turns),
        orbit_seconds=Float64(camera_orbit_seconds),
    )
end

function default_movie_nloops(NT::Integer, framerate::Real, settings;
    frame_mode=FRAME_MODE_SEQUENCE, slice_hold_frames=CURRENT_SLICE_HOLD_FRAMES)

    NT > 0 || throw(ArgumentError("NT should be positive"))
    framerate > 0 || throw(ArgumentError("framerate should be positive"))
    if settings.motion != CAMERA_MOTION_ORBIT
        return CURRENT_MOVIE_NLOOPS
    end
    target_frames = abs(settings.orbit_turns) * settings.orbit_seconds * framerate
    mode = validate_frame_mode(frame_mode)
    frames_per_loop = mode == FRAME_MODE_SEQUENCE ?
                      NT * validate_slice_hold_frames(slice_hold_frames) : NT
    return max(CURRENT_MOVIE_NLOOPS, ceil(Int, target_frames / frames_per_loop))
end

function camera_azimuth_for_frame(settings, frame::Integer, total_frames::Integer)
    if settings.azimuth === nothing
        return nothing
    elseif settings.motion == CAMERA_MOTION_STATIC
        return settings.azimuth
    elseif settings.motion == CAMERA_MOTION_ORBIT
        return settings.azimuth + 2pi * settings.orbit_turns * (frame - 1) / total_frames
    else
        throw(ArgumentError("unsupported camera_motion: $(settings.motion)"))
    end
end

function apply_camera_settings!(ax, settings, frame::Integer, total_frames::Integer)
    azimuth = camera_azimuth_for_frame(settings, frame, total_frames)
    azimuth === nothing || (ax.azimuth[] = azimuth)
    settings.elevation === nothing || (ax.elevation[] = settings.elevation)
    return nothing
end

function camera_motion_metadata(settings)
    return Dict(
        "camera_motion" => String(settings.motion),
        "azimuth" => settings.azimuth,
        "elevation" => settings.elevation,
        "perspectiveness" => settings.perspectiveness,
        "viewmode" => settings.viewmode === nothing ? nothing : String(settings.viewmode),
        "orbit_turns" => settings.orbit_turns,
        "orbit_seconds" => settings.orbit_seconds,
    )
end

periodic_index(i, n) = mod1(i, n)

function smooth_periodic_3d(data; weight=CURRENT_ACTION_DENSITY_SMOOTH_WEIGHT,
    passes=CURRENT_ACTION_DENSITY_SMOOTH_PASSES)

    out = Float64.(data)
    for _ in 1:passes
        src = out
        dest = similar(src)
        nx, ny, nz = size(src)
        for z in 1:nz, y in 1:ny, x in 1:nx
            neighbor_sum =
                src[periodic_index(x - 1, nx), y, z] +
                src[periodic_index(x + 1, nx), y, z] +
                src[x, periodic_index(y - 1, ny), z] +
                src[x, periodic_index(y + 1, ny), z] +
                src[x, y, periodic_index(z - 1, nz)] +
                src[x, y, periodic_index(z + 1, nz)]
            dest[x, y, z] = weight * src[x, y, z] + (1 - weight) * neighbor_sum / 6
        end
        out = dest
    end
    return out
end

function smooth_clamped_3d(data; weight=CURRENT_ACTION_DENSITY_POST_SMOOTH_WEIGHT,
    passes=CURRENT_ACTION_DENSITY_POST_SMOOTH_PASSES)

    out = Float64.(data)
    tmp = similar(out)
    nx, ny, nz = size(out)
    side = (1 - weight) / 6
    for _ in 1:passes
        for z in 1:nz, y in 1:ny, x in 1:nx
            xm = max(x - 1, 1)
            xp = min(x + 1, nx)
            ym = max(y - 1, 1)
            yp = min(y + 1, ny)
            zm = max(z - 1, 1)
            zp = min(z + 1, nz)
            tmp[x, y, z] =
                weight * out[x, y, z] +
                side * (out[xm, y, z] + out[xp, y, z] +
                        out[x, ym, z] + out[x, yp, z] +
                        out[x, y, zm] + out[x, y, zp])
        end
        out, tmp = tmp, out
    end
    return out
end

function map_fourth_slices(data4, f)
    out = similar(data4, Float64)
    for t in axes(data4, 4)
        out[:, :, :, t] .= f(@view data4[:, :, :, t])
    end
    return out
end

function trilinear_clamped(data, x, y, z)
    sx, sy, sz = size(data)
    x = clamp(x, 1, sx)
    y = clamp(y, 1, sy)
    z = clamp(z, 1, sz)
    i0 = sx == 1 ? 1 : clamp(floor(Int, x), 1, sx - 1)
    j0 = sy == 1 ? 1 : clamp(floor(Int, y), 1, sy - 1)
    k0 = sz == 1 ? 1 : clamp(floor(Int, z), 1, sz - 1)
    i1 = sx == 1 ? 1 : i0 + 1
    j1 = sy == 1 ? 1 : j0 + 1
    k1 = sz == 1 ? 1 : k0 + 1
    tx = sx == 1 ? 0.0 : x - i0
    ty = sy == 1 ? 0.0 : y - j0
    tz = sz == 1 ? 0.0 : z - k0
    c000 = data[i0, j0, k0]
    c100 = data[i1, j0, k0]
    c010 = data[i0, j1, k0]
    c110 = data[i1, j1, k0]
    c001 = data[i0, j0, k1]
    c101 = data[i1, j0, k1]
    c011 = data[i0, j1, k1]
    c111 = data[i1, j1, k1]
    c00 = (1 - tx) * c000 + tx * c100
    c10 = (1 - tx) * c010 + tx * c110
    c01 = (1 - tx) * c001 + tx * c101
    c11 = (1 - tx) * c011 + tx * c111
    c0 = (1 - ty) * c00 + ty * c10
    c1 = (1 - ty) * c01 + ty * c11
    return (1 - tz) * c0 + tz * c1
end

function upsample_clamped_3d(data, factor::Integer)
    factor > 0 || throw(ArgumentError("factor should be positive"))
    sx, sy, sz = size(data)
    out = Array{Float64}(undef, (sx - 1) * factor + 1,
        (sy - 1) * factor + 1, (sz - 1) * factor + 1)
    for k in axes(out, 3), j in axes(out, 2), i in axes(out, 1)
        out[i, j, k] = trilinear_clamped(
            data, 1 + (i - 1) / factor, 1 + (j - 1) / factor, 1 + (k - 1) / factor)
    end
    return out
end

function mix_rgb(c1, c2, t)
    s = clamp(t, 0, 1)
    return ntuple(i -> (1 - s) * c1[i] + s * c2[i], 3)
end

function classic_thermogram_stops()
    return (
        (0.00, (0.02, 0.08, 0.35)),
        (0.18, (0.00, 0.40, 0.85)),
        (0.36, (0.00, 0.75, 0.65)),
        (0.54, (0.55, 0.95, 0.15)),
        (0.72, (1.00, 0.84, 0.00)),
        (0.90, (1.00, 0.18, 0.00)),
        (1.00, (1.00, 0.95, 0.85)),
    )
end

function interp_color_stops(stops, t)
    x = clamp(t, 0, 1)
    for i in 1:(length(stops) - 1)
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        if x <= t1
            s = t1 == t0 ? 1.0 : (x - t0) / (t1 - t0)
            return mix_rgb(c0, c1, s)
        end
    end
    return stops[end][2]
end

function action_density_blob_color(value; qmin, qmax,
    palette=CURRENT_ACTION_DENSITY_COLOR_PALETTE,
    gamma=CURRENT_ACTION_DENSITY_COLOR_GAMMA)

    palette == :classic_thermo ||
        throw(ArgumentError("unsupported action-density color palette: $palette"))
    t = qmax == qmin ? 1.0 : clamp((value - qmin) / (qmax - qmin), 0, 1)
    c = interp_color_stops(classic_thermogram_stops(), t^gamma)
    return Vec3f(c[1], c[2], c[3])
end

function local_color_value(data, x, y, z;
    radius=CURRENT_ACTION_DENSITY_COLOR_RADIUS,
    stat=CURRENT_ACTION_DENSITY_COLOR_STAT,
    top_fraction=CURRENT_ACTION_DENSITY_COLOR_TOP_FRACTION)

    nx, ny, nz = size(data)
    values = Float64[]
    for zz in max(1, z - radius):min(nz, z + radius),
        yy in max(1, y - radius):min(ny, y + radius),
        xx in max(1, x - radius):min(nx, x + radius)
        push!(values, data[xx, yy, zz])
    end
    if stat == :max
        return maximum(values)
    elseif stat == :sample
        return data[x, y, z]
    elseif stat == :topmean
        sort!(values)
        n = max(1, round(Int, length(values) * top_fraction))
        return mean(@view values[(end - n + 1):end])
    else
        throw(ArgumentError("unsupported local color statistic: $stat"))
    end
end

function boundary_position(b, factor, a, nbase)
    spacing = a / factor
    return Float32(clamp(a + (b - 0.5) * spacing, a, a * nbase))
end

function build_action_density_blob_mesh(data; base_level, color_range,
    factor=CURRENT_ACTION_DENSITY_UPSAMPLE_FACTOR,
    color_radius=CURRENT_ACTION_DENSITY_COLOR_RADIUS,
    color_stat=CURRENT_ACTION_DENSITY_COLOR_STAT,
    top_fraction=CURRENT_ACTION_DENSITY_COLOR_TOP_FRACTION,
    palette=CURRENT_ACTION_DENSITY_COLOR_PALETTE,
    gamma=CURRENT_ACTION_DENSITY_COLOR_GAMMA,
    a,
    lattice_size)

    mask = data .>= base_level
    sx, sy, sz = size(mask)
    nx, ny, nz = lattice_size
    vertices = Point3f[]
    color_sums = Vector{Vec3f}()
    color_counts = Int[]
    vertex_index = Dict{Tuple{Int,Int,Int},Int}()
    faces = Makie.GeometryBasics.TriangleFace{Int}[]
    qmin, qmax = color_range

    function owner_color(x, y, z)
        value = local_color_value(data, x, y, z;
            radius=color_radius, stat=color_stat, top_fraction=top_fraction)
        return action_density_blob_color(value;
            qmin=qmin, qmax=qmax, palette=palette, gamma=gamma)
    end

    function add_vertex!(key, color)
        if haskey(vertex_index, key)
            idx = vertex_index[key]
            color_sums[idx] += color
            color_counts[idx] += 1
            return idx
        end
        bx, by, bz = key
        p = Point3f(
            boundary_position(bx, factor, a, nx),
            boundary_position(by, factor, a, ny),
            boundary_position(bz, factor, a, nz))
        push!(vertices, p)
        push!(color_sums, color)
        push!(color_counts, 1)
        idx = length(vertices)
        vertex_index[key] = idx
        return idx
    end

    function add_quad!(keys, color)
        idx = map(key -> add_vertex!(key, color), keys)
        push!(faces, Makie.GeometryBasics.TriangleFace(idx[1], idx[2], idx[3]))
        push!(faces, Makie.GeometryBasics.TriangleFace(idx[1], idx[3], idx[4]))
    end

    function isfilled(x, y, z)
        1 <= x <= sx || return false
        1 <= y <= sy || return false
        1 <= z <= sz || return false
        return mask[x, y, z]
    end

    for z in 1:sz, y in 1:sy, x in 1:sx
        mask[x, y, z] || continue
        c = owner_color(x, y, z)
        x0, x1 = x - 1, x
        y0, y1 = y - 1, y
        z0, z1 = z - 1, z
        if !isfilled(x - 1, y, z)
            add_quad!(((x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)), c)
        end
        if !isfilled(x + 1, y, z)
            add_quad!(((x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)), c)
        end
        if !isfilled(x, y - 1, z)
            add_quad!(((x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)), c)
        end
        if !isfilled(x, y + 1, z)
            add_quad!(((x0, y1, z0), (x0, y1, z1), (x1, y1, z1), (x1, y1, z0)), c)
        end
        if !isfilled(x, y, z - 1)
            add_quad!(((x0, y0, z0), (x0, y1, z0), (x1, y1, z0), (x1, y0, z0)), c)
        end
        if !isfilled(x, y, z + 1)
            add_quad!(((x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)), c)
        end
    end

    colors = [RGBAf((color_sums[i] / color_counts[i])..., 1) for i in eachindex(color_sums)]
    info = (filled=count(mask), vertices=length(vertices), faces=length(faces))
    return vertices, faces, colors, info
end

function mesh_adjacency(nvertices, faces)
    adjacency = [Set{Int}() for _ in 1:nvertices]
    for face in faces
        i, j, k = Tuple(face)
        push!(adjacency[i], j)
        push!(adjacency[i], k)
        push!(adjacency[j], i)
        push!(adjacency[j], k)
        push!(adjacency[k], i)
        push!(adjacency[k], j)
    end
    return [collect(s) for s in adjacency]
end

function laplacian_step(points, adjacency, amount, pinned, minp, maxp)
    next = copy(points)
    for i in eachindex(points)
        pinned[i] && continue
        neigh = adjacency[i]
        isempty(neigh) && continue
        avg = Vec3f(0)
        for j in neigh
            avg += Vec3f(points[j])
        end
        avg /= length(neigh)
        p = (1 - amount) * Vec3f(points[i]) + amount * avg
        next[i] = Point3f(
            clamp(p[1], minp[1], maxp[1]),
            clamp(p[2], minp[2], maxp[2]),
            clamp(p[3], minp[3], maxp[3]))
    end
    return next
end

function taubin_smooth_mesh(points, faces; iterations=CURRENT_ACTION_DENSITY_TAUBIN_ITERATIONS,
    lambda=CURRENT_ACTION_DENSITY_TAUBIN_LAMBDA,
    mu=CURRENT_ACTION_DENSITY_TAUBIN_MU,
    pin_domain=CURRENT_ACTION_DENSITY_TAUBIN_PIN_DOMAIN,
    a,
    lattice_size)

    nx, ny, nz = lattice_size
    minp = Vec3f(a, a, a)
    maxp = Vec3f(a * nx, a * ny, a * nz)
    eps = Float32(2e-5)
    pinned = falses(length(points))
    if pin_domain
        for i in eachindex(points)
            p = points[i]
            pinned[i] =
                abs(p[1] - minp[1]) < eps || abs(p[1] - maxp[1]) < eps ||
                abs(p[2] - minp[2]) < eps || abs(p[2] - maxp[2]) < eps ||
                abs(p[3] - minp[3]) < eps || abs(p[3] - maxp[3]) < eps
        end
    end
    adjacency = mesh_adjacency(length(points), faces)
    out = copy(points)
    for _ in 1:iterations
        out = laplacian_step(out, adjacency, lambda, pinned, minp, maxp)
        out = laplacian_step(out, adjacency, mu, pinned, minp, maxp)
    end
    return out
end

function action_density_blob_style_metadata(; body_level, color_range)
    return Dict(
        "render_style" => String(RENDER_STYLE_ACTION_DENSITY_BLOB),
        "geometry" => "filled_superlevel_solid_mesh",
        "body_quantile" => CURRENT_ACTION_DENSITY_BODY_QUANTILE,
        "body_level" => body_level,
        "pre_smooth" => Dict(
            "boundary" => "periodic",
            "weight" => CURRENT_ACTION_DENSITY_SMOOTH_WEIGHT,
            "passes" => CURRENT_ACTION_DENSITY_SMOOTH_PASSES,
        ),
        "interpolation" => Dict(
            "method" => "clamped_trilinear",
            "factor" => CURRENT_ACTION_DENSITY_UPSAMPLE_FACTOR,
        ),
        "post_smooth" => Dict(
            "boundary" => "clamped",
            "weight" => CURRENT_ACTION_DENSITY_POST_SMOOTH_WEIGHT,
            "passes" => CURRENT_ACTION_DENSITY_POST_SMOOTH_PASSES,
        ),
        "mesh_smoothing" => Dict(
            "method" => "taubin",
            "iterations" => CURRENT_ACTION_DENSITY_TAUBIN_ITERATIONS,
            "lambda" => CURRENT_ACTION_DENSITY_TAUBIN_LAMBDA,
            "mu" => CURRENT_ACTION_DENSITY_TAUBIN_MU,
            "pin_domain" => CURRENT_ACTION_DENSITY_TAUBIN_PIN_DOMAIN,
        ),
        "color_quantity" => "local_action_density",
        "color_method" => String(CURRENT_ACTION_DENSITY_COLOR_STAT),
        "color_radius" => CURRENT_ACTION_DENSITY_COLOR_RADIUS,
        "color_top_fraction" => CURRENT_ACTION_DENSITY_COLOR_TOP_FRACTION,
        "color_palette" => String(CURRENT_ACTION_DENSITY_COLOR_PALETTE),
        "color_gamma" => CURRENT_ACTION_DENSITY_COLOR_GAMMA,
        "color_quantiles" => collect(CURRENT_ACTION_DENSITY_COLOR_QUANTILES),
        "color_range" => collect(color_range),
        "reference_style" => "VisualQCD/Nobel QCD Lava Lamp inspired",
    )
end

function action_density_level_selection_metadata(levels, summary; body_quantile)
    return Dict(
        "level_target" => String(LEVEL_TARGET_ACTION_DENSITY_HIGH),
        "method" => "global_quantile_filled_superlevel",
        "body_quantile" => body_quantile,
        "display_levels" => collect(levels),
        "raw_equivalent_levels" => collect(levels),
        "raw_focus_for_upper_levels" => "high_local_action_density",
        "summary" => Dict(
            "level" => summary.level,
            "isorange" => summary.isorange,
            "min" => summary.min,
            "max" => summary.max,
        ),
    )
end

function action_density_blob_display_setup(action_density)
    smoothed = map_fourth_slices(action_density, x -> smooth_periodic_3d(x;
        weight=CURRENT_ACTION_DENSITY_SMOOTH_WEIGHT,
        passes=CURRENT_ACTION_DENSITY_SMOOTH_PASSES))
    values = finite_level_values(smoothed)
    body_level = Float64(quantile(values, CURRENT_ACTION_DENSITY_BODY_QUANTILE))
    color_range = Tuple(Float64.(quantile(values, collect(CURRENT_ACTION_DENSITY_COLOR_QUANTILES))))
    level_summary = legacy_level_summary(smoothed)
    levels = [body_level]
    return (
        render_kind=:mesh,
        display_field=smoothed,
        level_summary=level_summary,
        levels=levels,
        body_level=body_level,
        color_range=color_range,
        display_transform_info=merge(
            raw_display_transform_metadata(),
            Dict("raw_focus_for_upper_levels" => "high_local_action_density")),
        level_selection_info=action_density_level_selection_metadata(
            levels, level_summary; body_quantile=CURRENT_ACTION_DENSITY_BODY_QUANTILE),
        render_style_info=action_density_blob_style_metadata(
            body_level=body_level, color_range=color_range),
        observable_info=local_action_density_observable_metadata(),
        title=ACTION_DENSITY_BLOB_MOVIE_TITLE,
    )
end

function action_density_blob_geometry(data, setup; a, lattice_size)
    upsampled = upsample_clamped_3d(data, CURRENT_ACTION_DENSITY_UPSAMPLE_FACTOR)
    render_field = smooth_clamped_3d(upsampled;
        weight=CURRENT_ACTION_DENSITY_POST_SMOOTH_WEIGHT,
        passes=CURRENT_ACTION_DENSITY_POST_SMOOTH_PASSES)
    vertices, faces, colors, info = build_action_density_blob_mesh(render_field;
        base_level=setup.body_level,
        color_range=setup.color_range,
        factor=CURRENT_ACTION_DENSITY_UPSAMPLE_FACTOR,
        color_radius=CURRENT_ACTION_DENSITY_COLOR_RADIUS,
        color_stat=CURRENT_ACTION_DENSITY_COLOR_STAT,
        top_fraction=CURRENT_ACTION_DENSITY_COLOR_TOP_FRACTION,
        palette=CURRENT_ACTION_DENSITY_COLOR_PALETTE,
        gamma=CURRENT_ACTION_DENSITY_COLOR_GAMMA,
        a=a,
        lattice_size=lattice_size)
    smooth_vertices = taubin_smooth_mesh(vertices, faces;
        iterations=CURRENT_ACTION_DENSITY_TAUBIN_ITERATIONS,
        lambda=CURRENT_ACTION_DENSITY_TAUBIN_LAMBDA,
        mu=CURRENT_ACTION_DENSITY_TAUBIN_MU,
        pin_domain=CURRENT_ACTION_DENSITY_TAUBIN_PIN_DOMAIN,
        a=a,
        lattice_size=lattice_size)
    mesh_obj = Makie.GeometryBasics.Mesh(smooth_vertices, faces)
    return (mesh=mesh_obj, colors=colors, info=info)
end

function action_density_blob_plot!(ax, geometry)
    return mesh!(ax, geometry.mesh; color=geometry.colors,
        shading=FastShading, transparency=false), geometry.info
end

function action_density_blob_plot!(ax, data, setup; a, lattice_size)
    geometry = action_density_blob_geometry(data, setup; a=a, lattice_size=lattice_size)
    return action_density_blob_plot!(ax, geometry)
end
