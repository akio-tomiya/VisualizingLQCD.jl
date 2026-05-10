#!/usr/bin/env julia

function arg_value(args, name, default=nothing)
    flag = "--$name"
    index = findfirst(==(flag), args)
    index === nothing && return default
    index < length(args) || error("missing value after $flag")
    return args[index + 1]
end

function ffmpeg_command()
    path = Sys.which("ffmpeg")
    path !== nothing && return path

    if Base.find_package("FFMPEG_jll") !== nothing
        @eval import FFMPEG_jll
        return FFMPEG_jll.ffmpeg()
    end

    error("""
    ffmpeg was not found on PATH, and FFMPEG_jll is not available in this Julia project.

    On YITP, add FFMPEG_jll on the login gate before submitting GIF conversion:

        ssh -F /Users/akio/repository/supercomputers_info/login_info.md yitp-mercury
        cd /sc/home/akio/VisualizingLQCD-yitp-sample
        julia --project=. --startup-file=no -e 'import Pkg; Pkg.add("FFMPEG_jll")'
    """)
end

function main(args=ARGS)
    input = arg_value(args, "input")
    output = arg_value(args, "output")
    width = parse(Int, arg_value(args, "width", "480"))
    fps = parse(Int, arg_value(args, "fps", "17"))

    input === nothing && error("missing --input INPUT.mp4")
    output === nothing && error("missing --output OUTPUT.gif")
    isfile(input) || error("input does not exist: $input")

    mkpath(dirname(output))
    palette = tempname() * ".png"
    ffmpeg = ffmpeg_command()
    palette_filter = "fps=$fps,scale=$width:-1:flags=lanczos,palettegen=stats_mode=diff"
    gif_filter = "fps=$fps,scale=$width:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle"

    try
        run(`$ffmpeg -y -i $input -vf $palette_filter $palette`)
        run(`$ffmpeg -y -i $input -i $palette -lavfi $gif_filter $output`)
    finally
        isfile(palette) && rm(palette)
    end

    @info "GIF conversion finished" input output width fps
    return output
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
