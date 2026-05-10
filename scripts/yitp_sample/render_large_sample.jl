#!/usr/bin/env julia

using VisualizingLQCD

function arg_value(args, name, default)
    flag = "--$name"
    index = findfirst(==(flag), args)
    index === nothing && return default
    index < length(args) || error("missing value after $flag")
    return args[index + 1]
end

function parse_bool(value)
    lowercase(value) in ("1", "true", "yes") && return true
    lowercase(value) in ("0", "false", "no") && return false
    error("expected boolean value, got: $value")
end

function main(args=ARGS)
    nx = parse(Int, arg_value(args, "nx", "32"))
    ny = parse(Int, arg_value(args, "ny", "32"))
    nz = parse(Int, arg_value(args, "nz", "32"))
    nt = parse(Int, arg_value(args, "nt", "64"))
    nc = parse(Int, arg_value(args, "nc", "3"))
    beta = parse(Float64, arg_value(args, "beta", "6.0"))
    input = arg_value(args, "input", "outputs/Conf$(nx)$(ny)$(nz)$(nt)beta$(beta).ildg")
    output = arg_value(
        args, "output", "outputs/plaquette_3D_contour_animation$(nx)$(ny)$(nz)$(nt)beta$(beta).mp4")
    orbit_turns = parse(Float64, arg_value(args, "camera-orbit-turns", "0.175"))
    nloops_arg = arg_value(args, "nloops", "")
    nloops = isempty(nloops_arg) ? nothing : parse(Int, nloops_arg)
    framerate_arg = arg_value(args, "framerate", "")
    framerate = isempty(framerate_arg) ? nothing : parse(Int, framerate_arg)
    slice_hold_frames = parse(Int, arg_value(args, "slice-hold-frames", "1"))
    figure_size = parse(Int, arg_value(args, "figure-size", "800"))
    show_axis_labels = parse_bool(arg_value(args, "show-axis-labels", "true"))

    mkpath(dirname(output))
    create_animation(nx, ny, nz, nt, nc, output;
        beta=beta,
        filename=input,
        camera_motion=VisualizingLQCD.CAMERA_MOTION_ORBIT,
        frame_mode=VisualizingLQCD.FRAME_MODE_SEQUENCE,
        camera_orbit_turns=orbit_turns,
        nloops=nloops,
        framerate=framerate,
        slice_hold_frames=slice_hold_frames,
        figure_size=(figure_size, figure_size),
        show_axis_labels=show_axis_labels,
        show_render_progress=true)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
