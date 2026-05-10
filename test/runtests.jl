using VisualizingLQCD
using Test

const SAMPLE_BASENAME =
    "plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn"

function run_render_smoke_test()
    NX, NY, NZ, NT = VisualizingLQCD.CURRENT_TEST_LATTICE
    β = VisualizingLQCD.CURRENT_TEST_BETA
    NC = VisualizingLQCD.CURRENT_TEST_NC
    flow_steps_in = VisualizingLQCD.CURRENT_TEST_FLOW_STEPS

    confname = "Conf$(NX)$(NY)$(NZ)$(NT)beta$(β).ildg"
    videoname = "plaquette_3D_contour_animation$(NX)$(NY)$(NZ)$(NT)beta$(β).mp4"

    @time heatbathtest_4D(NX, NY, NZ, NT, β, NC, flow_steps_in, confname)
    create_animation(NX, NY, NZ, NT, NC, videoname; beta=β, filename=confname)
end

function run_render_smoke_enabled()
    flag = lowercase(get(ENV, "VISUALIZING_LQCD_RUN_RENDER_SMOKE", "0"))
    return flag in ("1", "true", "yes")
end

@testset "Frame selection contracts" begin
    @test [VisualizingLQCD.slice4_for_frame(i, 4) for i in 1:4] == [1, 2, 3, 4]
    @test [VisualizingLQCD.slice4_for_frame(i, 4; slice_hold_frames=2) for i in 1:8] ==
          [1, 1, 2, 2, 3, 3, 4, 4]
    @test [VisualizingLQCD.slice4_for_frame(i, 4;
               frame_mode=VisualizingLQCD.FRAME_MODE_FIXED, fixed_slice4=3) for i in 1:4] ==
          [3, 3, 3, 3]
    @test_throws ArgumentError VisualizingLQCD.slice4_for_frame(0, 4)
    @test_throws ArgumentError VisualizingLQCD.slice4_for_frame(1, 0)
    @test_throws ArgumentError VisualizingLQCD.slice4_for_frame(1, 4; slice_hold_frames=0)
    @test_throws ArgumentError VisualizingLQCD.slice4_for_frame(1, 4;
        frame_mode=VisualizingLQCD.FRAME_MODE_FIXED, fixed_slice4=5)

    @test VisualizingLQCD.total_movie_frames(4, 2; slice_hold_frames=2) == 16
    @test VisualizingLQCD.movie_duration_seconds(4, 2, 8; slice_hold_frames=2) == 2.0
    @test_throws ArgumentError VisualizingLQCD.movie_duration_seconds(4, 2, 0)

    sequence_map = VisualizingLQCD.frame_slice_map(4; nloops=3, slice_hold_frames=2)
    @test length(sequence_map) == VisualizingLQCD.total_movie_frames(4, 3; slice_hold_frames=2)
    @test [entry["frame"] for entry in sequence_map] == collect(1:length(sequence_map))
    @test all(1 <= entry["slice4"] <= 4 for entry in sequence_map)
    @test [count(entry -> entry["slice4"] == slice4, sequence_map) for slice4 in 1:4] ==
          fill(6, 4)

    fixed_map = VisualizingLQCD.frame_slice_map(4; nloops=2,
        frame_mode=VisualizingLQCD.FRAME_MODE_FIXED, fixed_slice4=3)
    @test length(fixed_map) == VisualizingLQCD.total_movie_frames(4, 2;
        frame_mode=VisualizingLQCD.FRAME_MODE_FIXED)
    @test all(entry["slice4"] == 3 for entry in fixed_map)
end

@testset "Camera orbit contracts" begin
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
    @test VisualizingLQCD.default_movie_nloops(32, 14, orbit_camera;
        slice_hold_frames=2) == 10
    @test VisualizingLQCD.default_frame_mode(static_camera.motion) ==
          VisualizingLQCD.FRAME_MODE_SEQUENCE
    @test VisualizingLQCD.default_frame_mode(orbit_camera.motion) ==
          VisualizingLQCD.FRAME_MODE_FIXED
    @test VisualizingLQCD.camera_motion_metadata(orbit_camera)["camera_motion"] == "orbit"
    @test VisualizingLQCD.camera_motion_metadata(orbit_camera)["orbit_seconds"] ≈ 640 / 14

    total_frames = VisualizingLQCD.total_movie_frames(64, 6; slice_hold_frames=2)
    azimuths = [VisualizingLQCD.camera_azimuth_for_frame(
                    orbit_camera, frame, total_frames) for frame in 1:total_frames]
    frame_step = 2pi / total_frames
    @test all(diff(azimuths) .≈ frame_step)
    @test azimuths[1] + 2pi - azimuths[end] ≈ frame_step
end

@testset "Metadata contracts" begin
    sample_lattice = (32, 32, 32, 64)
    sample_summary = (level=1.0, isorange=0.5, min=0.0, max=2.0, mode=1.0)
    sample_camera = VisualizingLQCD.camera_settings(:mesh;
        camera_motion=VisualizingLQCD.CAMERA_MOTION_ORBIT,
        camera_azimuth=0.0,
        camera_orbit_turns=1.0)
    metadata = VisualizingLQCD.animation_metadata(
        videoname="$(SAMPLE_BASENAME).mp4",
        metadata_filename="$(SAMPLE_BASENAME).mp4.metadata.json",
        filename="Conf32323264beta6.0-gf05hb40flow200.ildg",
        lattice_size=sample_lattice,
        nc=3,
        beta=6.0,
        flow_steps=200,
        levels=[1.0],
        level_summary=sample_summary,
        framerate=14,
        nloops=6,
        title="Action-density blob",
        figure_size=(480, 480),
        frame_mode=VisualizingLQCD.FRAME_MODE_SEQUENCE,
        slice_hold_frames=2,
        camera_info=VisualizingLQCD.camera_motion_metadata(sample_camera),
        observable_info=VisualizingLQCD.local_action_density_observable_metadata())

    @test metadata["interpretation"]["not_real_time_minkowski_evolution"] == true
    @test metadata["interpretation"]["screen_time_label"] == false
    @test metadata["configuration"]["lattice_size"] == collect(sample_lattice)
    @test metadata["frame_selection"]["frame_mode"] == "slice4_sequence"
    @test metadata["frame_selection"]["fixed_slice4"] === nothing
    @test metadata["frame_selection"]["slice_hold_frames"] == 2
    @test metadata["render"]["frame_count"] == 768
    @test metadata["render"]["duration_seconds"] ≈ 768 / 14
    @test metadata["render"]["figure_size"] == [480, 480]
    @test length(metadata["frame_map"]) == metadata["render"]["frame_count"]
    @test metadata["frame_map"][1] == Dict("frame" => 1, "slice4" => 1)
    @test metadata["frame_map"][end] == Dict("frame" => 768, "slice4" => 64)
end

@testset "Display and render setup contracts" begin
    @test VisualizingLQCD.display_transform_neglog(0.0) ≈
          -log(VisualizingLQCD.CURRENT_LOG_EPSILON)
    @test VisualizingLQCD.invert_display_level_neglog(
        VisualizingLQCD.display_transform_neglog(0.25),
    ) ≈ 0.25
    @test VisualizingLQCD.raw_focus_for_upper_display_levels() == "low_raw_deviation"
    @test VisualizingLQCD.CURRENT_LEVEL_TARGET == VisualizingLQCD.LEVEL_TARGET_ACTION_DENSITY_HIGH
    @test VisualizingLQCD.CURRENT_RENDER_STYLE == VisualizingLQCD.RENDER_STYLE_ACTION_DENSITY_BLOB
    @test VisualizingLQCD.CURRENT_SHOW_RENDER_PROGRESS
    @test VisualizingLQCD.validate_show_render_progress(false) == false
    @test_throws ArgumentError VisualizingLQCD.validate_show_render_progress(:yes)
    @test VisualizingLQCD.validate_figure_size((480, 480)) == (480, 480)
    @test_throws ArgumentError VisualizingLQCD.validate_figure_size((480, 0))
    @test VisualizingLQCD.render_progress_metadata(true)["show_render_progress"] == true
    @test VisualizingLQCD.render_progress_metadata(false)["progress_description"] === nothing
    @test VisualizingLQCD.default_render_style_for_level_target(
        VisualizingLQCD.LEVEL_TARGET_ACTION_DENSITY_HIGH) ==
          VisualizingLQCD.RENDER_STYLE_ACTION_DENSITY_BLOB
    @test VisualizingLQCD.default_render_style_for_level_target(
        VisualizingLQCD.LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY) ==
          VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED
    @test VisualizingLQCD.default_render_style_for_level_target(
        VisualizingLQCD.LEVEL_TARGET_LEGACY_NEGLOG_HIGH) ==
          VisualizingLQCD.RENDER_STYLE_CURRENT

    @test VisualizingLQCD.plaquette_loop(1, 3) == [(1, 1), (3, 1), (1, -1), (3, -1)]
    @test VisualizingLQCD.legacy_mean_std_levels(
        (level=1.0, isorange=0.5, min=0.0, max=2.0, mode=1.0);
        multiplier=1.0,
        step=0.5,
    ) == [1.5, 2.0]
    @test VisualizingLQCD.raw_equivalent_levels_neglog([1.5, 2.0]) ≈
          [exp(-1.5) - VisualizingLQCD.CURRENT_LOG_EPSILON,
           exp(-2.0) - VisualizingLQCD.CURRENT_LOG_EPSILON]
    @test VisualizingLQCD.raw_high_quantile_levels([1.0, 4.0, 2.0, 3.0];
        quantiles=(0.0, 1.0)) == [1.0, 4.0]
    @test VisualizingLQCD.raw_high_color_range([1.0, 4.0, 2.0, 3.0];
        quantiles=(0.0, 1.0)) == (1.0, 4.0)
    @test VisualizingLQCD.signed_symmetric_levels([-4.0, -2.0, 0.0, 3.0];
        quantiles=(0.0, 1.0)) == [-4.0, -2.0, 2.0, 4.0]
    @test VisualizingLQCD.signed_symmetric_levels([0.0, 2.0, 4.0];
        quantiles=(0.0, 1.0)) == [2.0, 4.0]
    @test VisualizingLQCD.signed_symmetric_levels([-4.0, -2.0, 0.0];
        quantiles=(0.0, 1.0)) == [-4.0, -2.0]
    @test VisualizingLQCD.signed_symmetric_color_range([-4.0, -2.0, 0.0, 3.0];
        quantile_level=1.0) == (-4.0, 4.0)
    @test_throws ArgumentError VisualizingLQCD.signed_symmetric_levels([0.0, 0.0])

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
    @test VisualizingLQCD.effective_render_theme(
        VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_SIGNED, nothing) ==
          VisualizingLQCD.RENDER_THEME_DARK

    @test VisualizingLQCD.transform_field_neglog([0.0, 1.0]) ≈
          [VisualizingLQCD.display_transform_neglog(0.0),
           VisualizingLQCD.display_transform_neglog(1.0)]
    @test VisualizingLQCD.topological_charge_display_transform_metadata()["raw_focus_for_upper_levels"] ==
          "positive_and_negative_topological_charge_density"
    balanced_topological_style = VisualizingLQCD.topological_charge_style_preset_settings(
        VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_BALANCED)
    @test balanced_topological_style.level_quantiles ==
          VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_LEVEL_QUANTILES
    @test balanced_topological_style.color_quantile ==
          VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_COLOR_QUANTILE
    @test balanced_topological_style.alpha == VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_ALPHA
    @test balanced_topological_style.transparency ==
          VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_TRANSPARENCY
    wide_topological_style = VisualizingLQCD.topological_charge_style_preset_settings(
        VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_WIDE)
    @test length(wide_topological_style.level_quantiles) == 3
    @test wide_topological_style.alpha == VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_WIDE_ALPHA
    @test wide_topological_style.transparency == balanced_topological_style.transparency
    core_topological_style = VisualizingLQCD.topological_charge_style_preset_settings(
        VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_CORE)
    @test minimum(core_topological_style.level_quantiles) >
          minimum(balanced_topological_style.level_quantiles)
    @test_throws ArgumentError VisualizingLQCD.validate_topological_charge_style_preset(:unknown)
    action_setup = VisualizingLQCD.action_density_blob_display_setup(
        reshape(collect(1.0:16.0), 2, 2, 2, 2))
    @test action_setup.render_kind == :mesh
    @test action_setup.observable_info["kind"] == "local_action_density"
    @test action_setup.render_style_info["render_style"] == "action_density_blob"
    @test action_setup.render_style_info["color_quantiles"] ==
          collect(VisualizingLQCD.CURRENT_ACTION_DENSITY_COLOR_QUANTILES)
    @test VisualizingLQCD.action_density_blob_color(0.5; qmin=0.0, qmax=1.0) isa
          VisualizingLQCD.Vec3f
    @test VisualizingLQCD.local_color_value(ones(3, 3, 3), 2, 2, 2) == 1.0
    action_geometry = VisualizingLQCD.action_density_blob_geometry(
        fill(action_setup.body_level + 1, 2, 2, 2), action_setup;
        a=1.0, lattice_size=(2, 2, 2))
    @test action_geometry.info.vertices > 0
    @test action_geometry.info.faces > 0
    @test length(action_geometry.colors) == action_geometry.info.vertices

    topological_setup = VisualizingLQCD.topological_charge_display_level_setup(
        reshape([-4.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0], 2, 2, 2, 1);
        level_quantiles=(0.0, 1.0),
        color_quantile=1.0)
    @test topological_setup.render_kind == :contour
    @test topological_setup.levels == [-4.0, -1.0, 1.0, 4.0]
    @test topological_setup.display_transform_info["raw_focus_for_upper_levels"] ==
          "positive_and_negative_topological_charge_density"
    @test topological_setup.observable_info["kind"] == "topological_charge_density"
    @test topological_setup.level_selection_info["level_target"] ==
          String(VisualizingLQCD.LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY)
    @test topological_setup.render_style_info["render_style"] == "topological_charge_signed"
    @test topological_setup.render_style_info["style_preset"] == "balanced"
    @test topological_setup.render_style_info["color_range"] == [-4.0, 4.0]
    @test topological_setup.render_style_info["transparency"] == false
    signed_specs = VisualizingLQCD.contour_plot_specs(
        topological_setup.contour_style, topological_setup.levels)
    @test length(signed_specs) == 2
    @test all(<(0), signed_specs[1].levels)
    @test all(>(0), signed_specs[2].levels)
    @test signed_specs[1].style.colormap ==
          collect(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_NEGATIVE_COLORMAP)
    @test signed_specs[2].style.colormap ==
          collect(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_POSITIVE_COLORMAP)

    positive_only_setup = VisualizingLQCD.topological_charge_display_level_setup(
        reshape([0.0, 1.0, 2.0, 4.0, 0.0, 1.0, 2.0, 4.0], 2, 2, 2, 1);
        level_quantiles=(0.0, 1.0),
        color_quantile=1.0)
    positive_specs = VisualizingLQCD.contour_plot_specs(
        positive_only_setup.contour_style, positive_only_setup.levels)
    @test length(positive_specs) == 1
    @test all(>(0), positive_specs[1].levels)
    @test positive_specs[1].style.colormap ==
          collect(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_POSITIVE_COLORMAP)

    negative_only_setup = VisualizingLQCD.topological_charge_display_level_setup(
        reshape([0.0, -1.0, -2.0, -4.0, 0.0, -1.0, -2.0, -4.0], 2, 2, 2, 1);
        level_quantiles=(0.0, 1.0),
        color_quantile=1.0)
    negative_specs = VisualizingLQCD.contour_plot_specs(
        negative_only_setup.contour_style, negative_only_setup.levels)
    @test length(negative_specs) == 1
    @test all(<(0), negative_specs[1].levels)
    @test negative_specs[1].style.colormap ==
          collect(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_NEGATIVE_COLORMAP)
    wide_topological_setup = VisualizingLQCD.topological_charge_display_level_setup(
        reshape([-4.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0], 2, 2, 2, 1);
        style_preset=VisualizingLQCD.TOPOLOGICAL_CHARGE_STYLE_WIDE,
        color_quantile=1.0)
    @test wide_topological_setup.render_style_info["style_preset"] == "wide"
    @test wide_topological_setup.contour_style.alpha ==
          VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_WIDE_ALPHA
end

@testset "Topological charge density contracts" begin
    @test VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_METHOD ==
          VisualizingLQCD.TOPOLOGICAL_CHARGE_METHOD_CLOVER
    @test VisualizingLQCD.validate_topological_charge_method(:clover) == :clover
    @test_throws ArgumentError VisualizingLQCD.validate_topological_charge_method(:plaquette)
    @test VisualizingLQCD.validate_topological_temp_count(5) == 5
    @test_throws ArgumentError VisualizingLQCD.validate_topological_temp_count(4)

    @test VisualizingLQCD.topological_epsilon4(1, 2, 3, 4) == 1
    @test VisualizingLQCD.topological_epsilon4(1, 2, 4, 3) == -1
    @test VisualizingLQCD.topological_epsilon4(1, 1, 2, 3) == 0
    @test_throws ArgumentError VisualizingLQCD.topological_epsilon4(0, 1, 2, 3)

    loops, loop_count = VisualizingLQCD.topological_loopset(:clover)
    @test loop_count == 4
    @test length(loops[1, 2]) == 4
    @test isempty(loops[1, 1])

    metadata = VisualizingLQCD.topological_charge_density_observable_metadata()
    @test metadata["kind"] == "topological_charge_density"
    @test metadata["method"] == "clover"
    @test metadata["signed"] == true
    @test metadata["positive_negative_density"] == true

    NX, NY, NZ, NT, NC = 2, 2, 2, 2, 3
    U = VisualizingLQCD.Initialize_Gaugefields(
        NC, 0, NX, NY, NZ, NT; condition=VisualizingLQCD.CURRENT_GENERATION_INITIAL_CONDITION)
    density = VisualizingLQCD.topological_charge_density(U, NX, NY, NZ, NT, NC)
    @test size(density) == (NX, NY, NZ, NT)
    @test maximum(abs.(density)) ≈ 0.0 atol = 1e-12
    @test VisualizingLQCD.topological_charge_from_density(density) ≈ 0.0 atol = 1e-12
end

@testset "SU(2) instanton density fixture contracts" begin
    lattice = (16, 16, 16, 16)
    center = (8, 8, 8, 8)
    density = VisualizingLQCD.su2_instanton_topological_density(lattice;
        rho=2.0, center=center, charge_sign=1)
    diagnostics = VisualizingLQCD.topological_density_fixture_diagnostics(density)
    @test size(density) == lattice
    @test diagnostics["total_charge"] ≈ 1.0
    @test diagnostics["max"]["index"] == collect(center)
    @test diagnostics["min"]["value"] >= 0.0

    anti_density = VisualizingLQCD.su2_instanton_topological_density(lattice;
        rho=2.0, center=center, charge_sign=-1)
    anti_diagnostics = VisualizingLQCD.topological_density_fixture_diagnostics(anti_density)
    @test anti_diagnostics["total_charge"] ≈ -1.0
    @test anti_diagnostics["min"]["index"] == collect(center)
    @test anti_diagnostics["max"]["value"] <= 0.0

    boundary_density = VisualizingLQCD.su2_instanton_topological_density(lattice;
        rho=1.5, center=(1, 1, 1, 1), charge_sign=1)
    boundary_diagnostics =
        VisualizingLQCD.topological_density_fixture_diagnostics(boundary_density)
    @test boundary_diagnostics["total_charge"] ≈ 1.0
    @test boundary_diagnostics["max"]["index"] == [1, 1, 1, 1]

    small_rho_density = VisualizingLQCD.su2_instanton_topological_density(lattice;
        rho=1.2, center=center, charge_sign=1)
    large_rho_density = VisualizingLQCD.su2_instanton_topological_density(lattice;
        rho=3.0, center=center, charge_sign=1)
    @test maximum(small_rho_density) > maximum(large_rho_density)
    @test sum(small_rho_density) ≈ 1.0
    @test sum(large_rho_density) ≈ 1.0

    off_center_density = VisualizingLQCD.su2_instanton_topological_density(lattice;
        rho=2.0, center=(8.5, 8.0, 8.0, 8.0), charge_sign=1)
    @test sum(off_center_density) ≈ 1.0
    @test VisualizingLQCD.topological_density_fixture_diagnostics(
        off_center_density)["max"]["index"][1] in (8, 9)

    diga_pp = VisualizingLQCD.su2_diga_topological_density(lattice, [
        (rho=1.5, center=(5, 5, 5, 5), charge_sign=1),
        (rho=1.5, center=(12, 12, 12, 12), charge_sign=1),
    ])
    @test sum(diga_pp) ≈ 2.0
    @test VisualizingLQCD.topological_density_fixture_diagnostics(
        diga_pp)["positive_charge"] ≈ 2.0

    diga_pm = VisualizingLQCD.su2_diga_topological_density(lattice, [
        (rho=1.5, center=(5, 5, 5, 5), charge_sign=1),
        (rho=1.5, center=(12, 12, 12, 12), charge_sign=-1),
    ])
    diga_pm_diagnostics = VisualizingLQCD.topological_density_fixture_diagnostics(diga_pm)
    @test diga_pm_diagnostics["total_charge"] ≈ 0.0 atol = 1e-12
    @test diga_pm_diagnostics["max"]["value"] > 0.0
    @test diga_pm_diagnostics["min"]["value"] < 0.0

    diga_three = VisualizingLQCD.su2_diga_topological_density(lattice, [
        (rho=1.5, center=(5, 5, 5, 5), charge_sign=1),
        (rho=2.0, center=(12, 5, 12, 8), charge_sign=1),
        (rho=1.8, center=(12, 12, 12, 12), charge_sign=-1),
    ])
    diga_three_diagnostics =
        VisualizingLQCD.topological_density_fixture_diagnostics(diga_three)
    @test diga_three_diagnostics["total_charge"] ≈ 1.0
    @test diga_three_diagnostics["positive_charge"] > 1.0
    @test diga_three_diagnostics["negative_charge"] < 0.0

    setup = VisualizingLQCD.topological_charge_display_level_setup(diga_pm;
        level_quantiles=(0.90, 0.99),
        color_quantile=0.995)
    @test setup.render_kind == :contour
    @test minimum(setup.levels) < 0.0
    @test maximum(setup.levels) > 0.0

    metadata = VisualizingLQCD.su2_instanton_fixture_metadata(lattice;
        rho=2.0, center=center, charge_sign=1)
    @test metadata["kind"] == "continuum_su2_instanton_density"
    @test metadata["is_gauge_field_solution"] == false
    @test metadata["normalize_charge"] == true
end

@testset "Sample artifact contracts" begin
    root = dirname(@__DIR__)
    readme_text = read(joinpath(root, "README.md"), String)
    @test occursin("$(SAMPLE_BASENAME).gif", readme_text)
    @test occursin("width=\"200\"", readme_text)
    @test occursin("`768` frames", readme_text)
    @test isfile(joinpath(root, "$(SAMPLE_BASENAME).mp4"))
    @test isfile(joinpath(root, "$(SAMPLE_BASENAME).gif"))
    @test isfile(joinpath(root, "test", "$(SAMPLE_BASENAME).gif"))
end

@testset "Optional render smoke" begin
    if run_render_smoke_enabled()
        run_render_smoke_test()
        @test true
    else
        @info "Skipping render smoke test. Set VISUALIZING_LQCD_RUN_RENDER_SMOKE=1 to run it."
        @test true
    end
end
