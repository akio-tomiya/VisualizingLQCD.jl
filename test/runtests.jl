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
    @test VisualizingLQCD.invert_display_level_neglog(
        VisualizingLQCD.display_transform_neglog(0.25),
    ) ≈ 0.25
    @test VisualizingLQCD.raw_focus_for_upper_display_levels() == "low_raw_deviation"
    @test VisualizingLQCD.legacy_mean_std_levels(
        (level=1.0, isorange=0.5, min=0.0, max=2.0, mode=1.0);
        multiplier=1.0,
        step=0.5,
    ) == [1.5, 2.0]
    @test VisualizingLQCD.raw_equivalent_levels_neglog([1.5, 2.0]) ≈
          [exp(-1.5) - VisualizingLQCD.CURRENT_LOG_EPSILON,
           exp(-2.0) - VisualizingLQCD.CURRENT_LOG_EPSILON]
    @test VisualizingLQCD.raw_high_quantile_levels([1.0, 4.0, 2.0, 3.0]; quantiles=(0.0, 1.0)) ==
          [1.0, 4.0]
    @test VisualizingLQCD.raw_high_color_range([1.0, 4.0, 2.0, 3.0]; quantiles=(0.0, 1.0)) ==
          (1.0, 4.0)
    raw_setup = VisualizingLQCD.plaquette_display_level_setup(
        [1.0, 4.0, 2.0, 3.0];
        level_target=VisualizingLQCD.LEVEL_TARGET_RAW_HIGH,
        raw_high_level_quantiles=(0.0, 1.0),
        raw_high_color_quantiles=(0.0, 1.0))
    @test raw_setup.display_transform_info["kind"] == "identity"
    @test raw_setup.level_selection_info["raw_focus_for_upper_levels"] == "high_raw_deviation"
    @test raw_setup.render_style_info["color_range"] == [1.0, 4.0]
    @test raw_setup.contour_style.alpha == VisualizingLQCD.CURRENT_RAW_HIGH_ALPHA
    @test VisualizingLQCD.render_theme_metadata(
        VisualizingLQCD.RENDER_THEME_DARK)["render_theme"] == "dark"
    thermal_setup = VisualizingLQCD.plaquette_display_level_setup(
        [1.0, 4.0, 2.0, 3.0];
        level_target=VisualizingLQCD.LEVEL_TARGET_RAW_HIGH,
        render_style=VisualizingLQCD.RENDER_STYLE_PLAQUETTE_THERMAL,
        raw_high_level_quantiles=(0.0, 1.0),
        raw_high_color_quantiles=(0.0, 1.0))
    @test thermal_setup.render_style_info["render_style"] == "plaquette_thermal"
    @test thermal_setup.render_style_info["colormap"] == ["cyan", "turquoise", "yellow", "red"]
    @test thermal_setup.contour_style.alpha == VisualizingLQCD.CURRENT_PLAQUETTE_THERMAL_ALPHA
    @test VisualizingLQCD.effective_render_theme(
        VisualizingLQCD.RENDER_STYLE_PLAQUETTE_THERMAL, nothing) ==
          VisualizingLQCD.RENDER_THEME_DARK
    @test VisualizingLQCD.transform_field_neglog([0.0, 1.0]) ≈
          [VisualizingLQCD.display_transform_neglog(0.0),
           VisualizingLQCD.display_transform_neglog(1.0)]
    @test VisualizingLQCD.frame_slice_map(4; nloops=1) == [
        Dict("frame" => 1, "slice4" => 1),
        Dict("frame" => 2, "slice4" => 2),
        Dict("frame" => 3, "slice4" => 3),
        Dict("frame" => 4, "slice4" => 4),
    ]
    test()
end
