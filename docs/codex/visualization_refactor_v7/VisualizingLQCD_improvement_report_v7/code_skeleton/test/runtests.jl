using Test
include("../src/VisualizingLQCD.jl")
using .VisualizingLQCD

@testset "frame map" begin
    @test frame_map(4) == [(frame=1, slice4=1), (frame=2, slice4=2),
                           (frame=3, slice4=3), (frame=4, slice4=4)]
end

@testset "log transforms" begin
    raw = ScalarField(reshape([0.0, 1e-6, 1e-4, 1e-2], 2, 2),
                      "p", "dimensionless", "raw plaquette deviation")
    spec = TransformSpec(:neglog, 1e-7, :fixed, (0.0, 1.0))
    bundle = build_display_field(raw, spec)
    @test all(isfinite, bundle.display.data)
    L = bundle.display.data[2]
    @test isapprox(invert_display_level(L, spec, bundle.epsilon), raw.data[2]; atol=1e-14)
    @test bundle.raw_focus == "low_raw_deviation"
end

@testset "level selection" begin
    data = collect(reshape(1.0:100.0, 10, 10))
    levels = choose_levels(data, LevelSpec(:quantile, [0.8, 0.9], Float64[], :upper, true))
    @test length(levels) == 2
    @test levels[1] < levels[2]
end
