#!/usr/bin/env julia

using GLMakie

function main()
    output = get(ENV, "VLQCD_GLMAKIE_SMOKE_OUTPUT", "outputs/glmakie-smoke.png")
    mkpath(dirname(output))
    @info "GLMakie smoke" output display=get(ENV, "DISPLAY", "")
    GLMakie.activate!()
    fig = Figure(size=(320, 240), backgroundcolor=:black)
    ax = Axis(fig[1, 1], backgroundcolor=:black)
    lines!(ax, 1:20, sin.(range(0, 2pi, length=20)); color=:cyan, linewidth=3)
    save(output, fig)
    @info "GLMakie smoke finished" output
    return output
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
