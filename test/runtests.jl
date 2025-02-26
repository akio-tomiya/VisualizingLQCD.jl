using VisualizingLQCD
using Test

function test()
    NX = 12
    NY = 12
    NZ = 12
    NT = 16 # Time direction
    β = 6.0
    NC = 3

    # the number of gradient flow steps in configuration generation
    flow_steps_in = 10#200

    confname = "Conf$(NX)$(NY)$(NZ)$(NT)beta$(β).ildg"
    videoname = "plaquette_3D_contour_animation$(NX)$(NY)$(NZ)$(NT)beta$(β).mp4"

    @time plaq_t = heatbathtest_4D(NX, NY, NZ, NT, β, NC, flow_steps_in, confname)
    # Execute
    create_animation(NX, NY, NZ, NT, NC, videoname; beta=β, filename=confname)
end

@testset "VisualizingLQCD.jl" begin
    # Write your tests here.
    test()
end
