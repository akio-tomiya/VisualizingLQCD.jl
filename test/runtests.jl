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
    @test [VisualizingLQCD.slice4_for_frame(i, 4) for i in 1:4] == [1, 2, 3, 4]
    @test VisualizingLQCD.display_transform_neglog(0.0) ≈ -log(VisualizingLQCD.CURRENT_LOG_EPSILON)
    @test VisualizingLQCD.legacy_mean_std_levels(
        (level=1.0, isorange=0.5, min=0.0, max=2.0, mode=1.0);
        multiplier=1.0,
        step=0.5,
    ) == [1.5, 2.0]
    @test VisualizingLQCD.frame_slice_map(4; nloops=1) == [
        Dict("frame" => 1, "slice4" => 1),
        Dict("frame" => 2, "slice4" => 2),
        Dict("frame" => 3, "slice4" => 3),
        Dict("frame" => 4, "slice4" => 4),
    ]
    test()
end
