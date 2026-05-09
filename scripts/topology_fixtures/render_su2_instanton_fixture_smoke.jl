#!/usr/bin/env julia

using VisualizingLQCD
using GLMakie
using Printf

const DEFAULT_OUTPUT_DIR = "/private/tmp/VisualizingLQCD-su2-instanton-fixtures"

function parse_args(args)
    output_dir = DEFAULT_OUTPUT_DIR
    frames = 36
    framerate = 12
    render_movies = true
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
        else
            throw(ArgumentError("unsupported argument: $arg"))
        end
        i += 1
    end
    frames > 0 || throw(ArgumentError("--frames should be positive"))
    framerate > 0 || throw(ArgumentError("--framerate should be positive"))
    return (output_dir=output_dir, frames=frames, framerate=framerate,
        render_movies=render_movies)
end

function fixture_cases()
    lattice = (24, 24, 24, 24)
    return [
        (
            name="single-plus-centered",
            slice4=12,
            density=VisualizingLQCD.su2_instanton_topological_density(lattice;
                rho=2.4, center=(12, 12, 12, 12), charge_sign=1),
        ),
        (
            name="single-minus-centered",
            slice4=12,
            density=VisualizingLQCD.su2_instanton_topological_density(lattice;
                rho=2.4, center=(12, 12, 12, 12), charge_sign=-1),
        ),
        (
            name="diga-plus-minus",
            slice4=12,
            density=VisualizingLQCD.su2_diga_topological_density(lattice, [
                (rho=1.8, center=(7, 7, 7, 7), charge_sign=1),
                (rho=2.2, center=(17, 17, 17, 17), charge_sign=-1),
            ]),
        ),
    ]
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

function render_case(case, output_dir; frames, framerate, render_movies)
    density = case.density
    nx, ny, nz, _ = size(density)
    setup = VisualizingLQCD.topological_charge_display_level_setup(density;
        level_quantiles=(0.80, 0.92, 0.98),
        color_quantile=0.999,
        render_alpha=0.70)
    diagnostics = VisualizingLQCD.topological_density_fixture_diagnostics(density)

    fig = Figure(size=(560, 560), backgroundcolor=:black)
    ax = Axis3(fig[1, 1]; axis_kwargs(case.name)...)
    limits!(ax, 1, nx, 1, ny, 1, nz)
    contour_kwargs = VisualizingLQCD.contour_plot_kwargs(setup.contour_style, setup.levels)
    GLMakie.contour!(ax, (1.0, Float64(nx)), (1.0, Float64(ny)), (1.0, Float64(nz)),
        @view(density[:, :, :, case.slice4]); contour_kwargs...)

    png_path = joinpath(output_dir, "$(case.name).png")
    save(png_path, fig)

    mp4_path = joinpath(output_dir, "$(case.name).mp4")
    if render_movies
        record(fig, mp4_path, 1:frames; framerate=framerate) do frame
            ax.azimuth[] = VisualizingLQCD.CURRENT_CAMERA_AZIMUTH +
                           2pi * (frame - 1) / frames
        end
    else
        mp4_path = nothing
    end

    return (
        name=case.name,
        png=png_path,
        mp4=mp4_path,
        levels=setup.levels,
        color_range=setup.render_style_info["color_range"],
        diagnostics=diagnostics,
    )
end

function html_path_for(path)
    return replace(basename(path), "\\" => "/")
end

function write_view_html(output_dir, results)
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
        for result in results
            write(io, "<section>\n<h2>$(result.name)</h2>\n")
            write(io, "<img src=\"$(html_path_for(result.png))\" alt=\"$(result.name) still\">\n")
            if result.mp4 !== nothing
                write(io, "<video src=\"$(html_path_for(result.mp4))\" controls loop muted></video>\n")
            end
            write(io, "<pre>")
            write(io, "levels = $(result.levels)\n")
            write(io, "color_range = $(result.color_range)\n")
            write(io, "diagnostics = $(result.diagnostics)\n")
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
        render_case(case, options.output_dir;
            frames=options.frames,
            framerate=options.framerate,
            render_movies=options.render_movies) for case in fixture_cases()
    ]
    view_html = write_view_html(options.output_dir, results)
    println("wrote $(view_html)")
    return view_html
end

main()
