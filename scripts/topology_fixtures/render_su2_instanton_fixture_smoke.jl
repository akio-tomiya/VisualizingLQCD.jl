#!/usr/bin/env julia

using VisualizingLQCD
using GLMakie
using Printf

const DEFAULT_OUTPUT_DIR = "/private/tmp/VisualizingLQCD-su2-instanton-fixtures"
const DEFAULT_FIXTURE_CASE_SET = "basic"
const DEFAULT_FIXTURE_LATTICE = (24, 24, 24, 24)
const DEFAULT_STYLE_PRESET = VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_WIDE

function parse_style_preset(raw)
    return VisualizingLQCD.validate_topological_charge_style_preset(Symbol(raw))
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

function parse_args(args)
    output_dir = DEFAULT_OUTPUT_DIR
    frames = 36
    framerate = 12
    render_movies = true
    case_set = DEFAULT_FIXTURE_CASE_SET
    style_preset = DEFAULT_STYLE_PRESET
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
    preset_settings = VisualizingLQCD.topological_charge_style_preset_settings(style_preset)
    return (output_dir=output_dir, frames=frames, framerate=framerate,
        render_movies=render_movies, case_set=case_set, style_preset=style_preset,
        level_quantiles=something(level_quantiles, preset_settings.level_quantiles),
        color_quantile=something(color_quantile, preset_settings.color_quantile),
        render_alpha=something(render_alpha, preset_settings.alpha))
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
        "level_quantiles" => collect(options.level_quantiles),
        "color_quantile" => options.color_quantile,
        "render_alpha" => options.render_alpha,
        "lattice_size" => collect(DEFAULT_FIXTURE_LATTICE),
    )
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

function render_case(case, output_dir, options)
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
    contour_kwargs = VisualizingLQCD.contour_plot_kwargs(setup.contour_style, setup.levels)
    GLMakie.contour!(ax, (1.0, Float64(nx)), (1.0, Float64(ny)), (1.0, Float64(nz)),
        @view(density[:, :, :, case.slice4]); contour_kwargs...)

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

function html_path_for(path)
    return replace(basename(path), "\\" => "/")
end

function write_view_html(output_dir, results, options)
    path = joinpath(output_dir, "view.html")
    open(path, "w") do io
        write(io, """
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>SU2 instanton topology fixture smoke</title>
<style>
body { margin: 0; background: #101010; color: #f4f4f4; font-family: sans-serif; }
main { padding: 24px; display: grid; gap: 24px; }
section { border-top: 1px solid #444; padding-top: 18px; }
img, video { width: 420px; max-width: 100%; background: #000; margin-right: 16px; }
pre { white-space: pre-wrap; color: #ddd; }
</style>
</head>
<body>
<main>
<h1>SU2 instanton topology fixture smoke</h1>
""")
        write(io, "<pre>")
        write(io, "display_options = $(display_options_metadata(options))\n")
        write(io, "</pre>\n")
        for result in results
            write(io, "<section>\n<h2>$(result.name)</h2>\n")
            write(io, "<p>$(result.description)</p>\n")
            write(io, "<img src=\"$(html_path_for(result.png))\" alt=\"$(result.name) still\">\n")
            if result.mp4 !== nothing
                write(io, "<video src=\"$(html_path_for(result.mp4))\" controls loop muted></video>\n")
            end
            write(io, "<pre>")
            write(io, "slice4 = $(result.slice4)\n")
            write(io, "levels = $(result.levels)\n")
            write(io, "color_range = $(result.color_range)\n")
            write(io, "diagnostics = $(result.diagnostics)\n")
            write(io, "fixture_metadata = $(result.fixture_metadata)\n")
            write(io, "</pre>\n</section>\n")
        end
        write(io, """
</main>
</body>
</html>
""")
    end
    return path
end

function main(args=ARGS)
    options = parse_args(args)
    mkpath(options.output_dir)
    GLMakie.activate!()
    results = [
        render_case(case, options.output_dir, options) for case in fixture_cases(options.case_set)
    ]
    view_html = write_view_html(options.output_dir, results, options)
    println("wrote $(view_html)")
    return view_html
end

main()
