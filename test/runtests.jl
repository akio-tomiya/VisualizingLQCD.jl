using VisualizingLQCD
using Test

function test()
    NX = 12
    NY = 12
    NZ = 12
    NT = 16 # Euclidean fourth direction
    β = 6.0
    NC = 3

    # the number of gradient flow steps in configuration generation
    flow_steps_in = 10#200

    confname = "Conf$(NX)$(NY)$(NZ)$(NT)beta$(β).ildg"
    videoname = "plaquette_3D_contour_animation$(NX)$(NY)$(NZ)$(NT)beta$(β).mp4"

    @time plaq_t = heatbathtest_4D(NX, NY, NZ, NT, β, NC, flow_steps_in, confname)
    # Default: local action-density blob visualization
    create_animation(NX, NY, NZ, NT, NC, videoname; beta=β, filename=confname)
end

@testset "VisualizingLQCD.jl" begin
    # Write your tests here.
    @test [VisualizingLQCD.slice4_for_frame(i, 4) for i in 1:4] == [1, 2, 3, 4]
    @test [VisualizingLQCD.slice4_for_frame(i, 4;
               frame_mode=VisualizingLQCD.FRAME_MODE_FIXED, fixed_slice4=3) for i in 1:4] ==
          [3, 3, 3, 3]
    @test VisualizingLQCD.display_transform_neglog(0.0) ≈ -log(VisualizingLQCD.CURRENT_LOG_EPSILON)
    @test VisualizingLQCD.invert_display_level_neglog(
        VisualizingLQCD.display_transform_neglog(0.25),
    ) ≈ 0.25
    @test VisualizingLQCD.raw_focus_for_upper_display_levels() == "low_raw_deviation"
    @test VisualizingLQCD.CURRENT_LEVEL_TARGET == VisualizingLQCD.LEVEL_TARGET_ACTION_DENSITY_HIGH
    @test VisualizingLQCD.CURRENT_RENDER_STYLE == VisualizingLQCD.RENDER_STYLE_ACTION_DENSITY_BLOB
    @test VisualizingLQCD.CURRENT_SHOW_RENDER_PROGRESS
    @test VisualizingLQCD.validate_show_render_progress(false) == false
    @test_throws ArgumentError VisualizingLQCD.validate_show_render_progress(:yes)
    @test VisualizingLQCD.render_progress_metadata(true)["show_render_progress"] == true
    @test VisualizingLQCD.render_progress_metadata(false)["progress_description"] === nothing
    @test VisualizingLQCD.default_render_style_for_level_target(
        VisualizingLQCD.LEVEL_TARGET_ACTION_DENSITY_HIGH) ==
          VisualizingLQCD.RENDER_STYLE_ACTION_DENSITY_BLOB
    @test VisualizingLQCD.default_render_style_for_level_target(
        VisualizingLQCD.LEVEL_TARGET_LEGACY_NEGLOG_HIGH) ==
          VisualizingLQCD.RENDER_STYLE_CURRENT
    static_camera = VisualizingLQCD.camera_settings(:contour)
    @test static_camera.motion == VisualizingLQCD.CAMERA_MOTION_STATIC
    @test static_camera.azimuth === nothing
    @test static_camera.perspectiveness === nothing
    mesh_camera = VisualizingLQCD.camera_settings(:mesh)
    @test mesh_camera.perspectiveness == VisualizingLQCD.CURRENT_CAMERA_MESH_PERSPECTIVENESS
    orbit_camera = VisualizingLQCD.camera_settings(:contour;
        camera_motion=VisualizingLQCD.CAMERA_MOTION_ORBIT,
        camera_azimuth=0.0,
        camera_orbit_turns=1.0)
    @test orbit_camera.perspectiveness == VisualizingLQCD.CURRENT_CAMERA_ORBIT_PERSPECTIVENESS
    @test orbit_camera.viewmode == VisualizingLQCD.CURRENT_CAMERA_ORBIT_VIEWMODE
    @test VisualizingLQCD.camera_azimuth_for_frame(orbit_camera, 1, 4) ≈ 0.0
    @test VisualizingLQCD.camera_azimuth_for_frame(orbit_camera, 3, 4) ≈ pi
    @test VisualizingLQCD.default_movie_nloops(32, 14, orbit_camera) == 20
    @test VisualizingLQCD.default_frame_mode(static_camera.motion) ==
          VisualizingLQCD.FRAME_MODE_SEQUENCE
    @test VisualizingLQCD.default_frame_mode(orbit_camera.motion) ==
          VisualizingLQCD.FRAME_MODE_FIXED
    @test VisualizingLQCD.frame_slice_map(4; nloops=2,
        frame_mode=VisualizingLQCD.FRAME_MODE_FIXED,
        fixed_slice4=3)[end]["slice4"] == 3
    @test VisualizingLQCD.camera_motion_metadata(orbit_camera)["camera_motion"] == "orbit"
    @test VisualizingLQCD.camera_motion_metadata(orbit_camera)["orbit_seconds"] ≈ 640 / 14
    @test VisualizingLQCD.plaquette_loop(1, 3) == [(1, 1), (3, 1), (1, -1), (3, -1)]
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
    legacy_setup = VisualizingLQCD.plaquette_display_level_setup([1.0, 4.0, 2.0, 3.0])
    @test legacy_setup.render_kind == :contour
    @test legacy_setup.display_transform_info["kind"] == "neglog"
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
    @test VisualizingLQCD.effective_render_theme(
        VisualizingLQCD.RENDER_STYLE_ACTION_DENSITY_BLOB, nothing) ==
          VisualizingLQCD.RENDER_THEME_DARK
    @test VisualizingLQCD.transform_field_neglog([0.0, 1.0]) ≈
          [VisualizingLQCD.display_transform_neglog(0.0),
           VisualizingLQCD.display_transform_neglog(1.0)]
    action_setup = VisualizingLQCD.action_density_blob_display_setup(reshape(collect(1.0:16.0), 2, 2, 2, 2))
    @test action_setup.render_kind == :mesh
    @test action_setup.observable_info["kind"] == "local_action_density"
    @test action_setup.render_style_info["render_style"] == "action_density_blob"
    @test action_setup.render_style_info["color_quantiles"] == collect(VisualizingLQCD.CURRENT_ACTION_DENSITY_COLOR_QUANTILES)
    @test VisualizingLQCD.action_density_blob_color(0.5; qmin=0.0, qmax=1.0) isa VisualizingLQCD.Vec3f
    @test VisualizingLQCD.local_color_value(ones(3, 3, 3), 2, 2, 2) == 1.0
    action_geometry = VisualizingLQCD.action_density_blob_geometry(
        fill(action_setup.body_level + 1, 2, 2, 2), action_setup;
        a=1.0, lattice_size=(2, 2, 2))
    @test action_geometry.info.vertices > 0
    @test action_geometry.info.faces > 0
    @test length(action_geometry.colors) == action_geometry.info.vertices
    @test VisualizingLQCD.frame_slice_map(4; nloops=1) == [
        Dict("frame" => 1, "slice4" => 1),
        Dict("frame" => 2, "slice4" => 2),
        Dict("frame" => 3, "slice4" => 3),
        Dict("frame" => 4, "slice4" => 4),
    ]
    test()
end
