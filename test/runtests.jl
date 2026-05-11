using VisualizingLQCD
using Gaugefields
using LinearAlgebra
using Test
using Wilsonloop

const SAMPLE_BASENAME =
    "topological_density_noaxis_halfspeed"

mutable struct DeleteRecorder
    deleted::Vector{Any}
end

Base.delete!(recorder::DeleteRecorder, item) = (push!(recorder.deleted, item); recorder)

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

function reference_clover_loops(mu, nu)
    return Wilsonloop.Wilsonline{4}[
        Wilsonloop.Wilsonline([(mu, +1), (nu, +1), (mu, -1), (nu, -1)]),
        Wilsonloop.Wilsonline([(nu, +1), (mu, -1), (nu, -1), (mu, +1)]),
        Wilsonloop.Wilsonline([(nu, -1), (mu, +1), (nu, +1), (mu, -1)]),
        Wilsonloop.Wilsonline([(mu, -1), (nu, -1), (mu, +1), (nu, +1)]),
    ]
end

function reference_clover_loopset()
    loops = Array{Vector{Wilsonloop.Wilsonline{4}},2}(undef, 4, 4)
    for mu in 1:4, nu in 1:4
        loops[mu, nu] = mu == nu ? Wilsonloop.Wilsonline{4}[] :
                        reference_clover_loops(mu, nu)
    end
    return loops, 4
end

function reference_epsilon4(mu, nu, rho, sigma)
    values = (mu, nu, rho, sigma)
    length(unique(values)) == 4 || return 0

    inversions = 0
    for i in 1:3, j in (i + 1):4
        inversions += values[i] > values[j]
    end
    return iseven(inversions) ? 1 : -1
end

function reference_clover_topological_charge(U)
    loops, loop_count = reference_clover_loopset()
    loop_out = similar(U[1])
    temps = [similar(U[1]) for _ in 1:4]
    field_strength = [similar(U[1]) for _ in 1:4, _ in 1:4]

    for mu in 1:4, nu in 1:4
        mu == nu && continue
        Gaugefields.evaluate_gaugelinks!(loop_out, loops[mu, nu], U, temps)
        Gaugefields.Traceless_antihermitian!(field_strength[mu, nu], loop_out)
    end

    charge = 0.0
    for mu in 1:4, nu in 1:4
        mu == nu && continue
        field_mu_nu = field_strength[mu, nu]
        for rho in 1:4, sigma in 1:4
            rho == sigma && continue
            epsilon = reference_epsilon4(mu, nu, rho, sigma)
            epsilon == 0 && continue
            field_rho_sigma = field_strength[rho, sigma]
            charge += epsilon * tr(field_mu_nu, field_rho_sigma) / loop_count^2
        end
    end
    return -real(charge) / (32 * pi^2)
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
    sequence_plan = VisualizingLQCD.animation_render_plan(
        4, (render_kind=:contour,), static_camera;
        framerate=8,
        nloops=2,
        frame_mode=VisualizingLQCD.FRAME_MODE_SEQUENCE,
        slice_hold_frames=2,
        cache_render_slices=true,
        figure_size=(320, 240),
        show_render_progress=false,
        show_axis_labels=false)
    @test sequence_plan.framerate == 8
    @test sequence_plan.total_frames == 16
    @test sequence_plan.cache_active == false
    @test sequence_plan.figure_size == (320, 240)
    @test sequence_plan.show_axis_labels == false
    mesh_fixed_plan = VisualizingLQCD.animation_render_plan(
        4, (render_kind=:mesh,), orbit_camera;
        nloops=2,
        frame_mode=VisualizingLQCD.FRAME_MODE_FIXED,
        fixed_slice4=2,
        cache_render_slices=true,
        show_render_progress=false)
    @test mesh_fixed_plan.framerate == VisualizingLQCD.CURRENT_CAMERA_ORBIT_FRAMERATE
    @test mesh_fixed_plan.total_frames == 8
    @test mesh_fixed_plan.cache_active
    @test mesh_fixed_plan.fixed_frame
    @test_throws ArgumentError VisualizingLQCD.animation_render_plan(
        4, (render_kind=:mesh,), static_camera; nloops=1.5)
    @test_throws ArgumentError VisualizingLQCD.animation_render_plan(
        4, (render_kind=:mesh,), static_camera; cache_render_slices=:yes)
    @test VisualizingLQCD.camera_motion_metadata(orbit_camera)["camera_motion"] == "orbit"
    @test VisualizingLQCD.camera_motion_metadata(orbit_camera)["orbit_seconds"] ≈ 640 / 14

    total_frames = VisualizingLQCD.total_movie_frames(64, 7; slice_hold_frames=2)
    azimuths = [VisualizingLQCD.camera_azimuth_for_frame(
                    orbit_camera, frame, total_frames) for frame in 1:total_frames]
    frame_step = 2pi / total_frames
    @test all(diff(azimuths) .≈ frame_step)
    @test azimuths[1] + 2pi - azimuths[end] ≈ frame_step
end

@testset "Metadata contracts" begin
    sample_lattice = (24, 24, 24, 32)
    sample_summary = (
        level=5.2156190850267185e-8,
        isorange=0.00010747313686192862,
        min=-0.0014794934375611478,
        max=0.0017322657400366298,
        mode=5.2156190850267185e-8)
    sample_camera = VisualizingLQCD.camera_settings(:mesh;
        camera_motion=VisualizingLQCD.CAMERA_MOTION_ORBIT,
        camera_azimuth=0.0,
        camera_orbit_turns=1.0)
    metadata = VisualizingLQCD.animation_metadata(
        videoname="$(SAMPLE_BASENAME).mp4",
        metadata_filename="$(SAMPLE_BASENAME).mp4.metadata.json",
        filename="Conf24242432beta6.0.ildg",
        lattice_size=sample_lattice,
        nc=3,
        beta=6.0,
        flow_steps=200,
        levels=[
            -0.0006161936800660506,
            -0.00020275648206484858,
            0.00020275648206484858,
            0.0006161936800660506,
        ],
        level_summary=sample_summary,
        framerate=8,
        nloops=4,
        title="Topological charge density",
        figure_size=(480, 480),
        frame_mode=VisualizingLQCD.FRAME_MODE_SEQUENCE,
        slice_hold_frames=1,
        render_axis_info=VisualizingLQCD.render_axis_metadata(false),
        camera_info=VisualizingLQCD.camera_motion_metadata(sample_camera),
        observable_info=VisualizingLQCD.topological_charge_density_observable_metadata())

    @test metadata["interpretation"]["not_real_time_minkowski_evolution"] == true
    @test metadata["interpretation"]["screen_time_label"] == false
    @test metadata["configuration"]["lattice_size"] == collect(sample_lattice)
    @test metadata["frame_selection"]["frame_mode"] == "slice4_sequence"
    @test metadata["frame_selection"]["fixed_slice4"] === nothing
    @test metadata["frame_selection"]["slice_hold_frames"] == 1
    @test metadata["render"]["frame_count"] == 128
    @test metadata["render"]["duration_seconds"] ≈ 16.0
    @test metadata["render"]["figure_size"] == [480, 480]
    @test metadata["render"]["show_axis_labels"] == false
    @test metadata["observable"]["kind"] == "topological_charge_density"
    @test length(metadata["frame_map"]) == metadata["render"]["frame_count"]
    @test metadata["frame_map"][1] == Dict("frame" => 1, "slice4" => 1)
    @test metadata["frame_map"][end] == Dict("frame" => 128, "slice4" => 32)
    sample_display_setup = (
        levels=[
            -0.0006161936800660506,
            -0.00020275648206484858,
            0.00020275648206484858,
            0.0006161936800660506,
        ],
        level_summary=sample_summary,
        title="Topological charge density",
        display_transform_info=VisualizingLQCD.topological_charge_display_transform_metadata(),
        level_selection_info=Dict("level_target" => "topological_charge_density"),
        render_style_info=Dict("render_style" => "topological_charge_volume"),
        observable_info=VisualizingLQCD.topological_charge_density_observable_metadata(),
    )
    sample_render_plan = (
        framerate=8,
        nloops=4,
        figure_size=(480, 480),
        frame_mode=VisualizingLQCD.FRAME_MODE_SEQUENCE,
        fixed_slice4=nothing,
        slice_hold_frames=1,
        show_render_progress=false,
        show_axis_labels=false,
        cache_active=true,
    )
    assembled_metadata = VisualizingLQCD.animation_metadata_for_render(
        videoname="$(SAMPLE_BASENAME).mp4",
        metadata_filename="$(SAMPLE_BASENAME).mp4.metadata.json",
        filename="Conf24242432beta6.0.ildg",
        lattice_size=sample_lattice,
        nc=3,
        beta=6.0,
        flow_steps=200,
        display_setup=sample_display_setup,
        render_theme=VisualizingLQCD.RENDER_THEME_DARK,
        render_plan=sample_render_plan,
        camera=sample_camera,
        mesh_cache=Dict(1 => :slice1, 2 => :slice2))
    @test assembled_metadata["render"]["frame_count"] == 128
    @test assembled_metadata["render"]["cached_slice_count"] == 2
    @test assembled_metadata["render"]["cache_render_slices"] == true
    @test assembled_metadata["render"]["render_theme"] == "dark"
    @test assembled_metadata["render"]["show_render_progress"] == false
    @test assembled_metadata["render"]["show_axis_labels"] == false
    @test assembled_metadata["observable"]["kind"] == "topological_charge_density"
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
    @test VisualizingLQCD.validate_show_axis_labels(false) == false
    @test VisualizingLQCD.render_axis_metadata(false)["show_axis_labels"] == false
    @test_throws ArgumentError VisualizingLQCD.validate_show_axis_labels(:yes)
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
    initialized_u = VisualizingLQCD.initialize_animation_gaugefield(2, 2, 2, 2, 3)
    @test length(initialized_u) == 4
    @test initialized_u[1].NC == 3
    @test initialized_u[1].NV == 16
    setup_u = VisualizingLQCD.Initialize_Gaugefields(
        3, 0, 2, 2, 2, 2; condition=VisualizingLQCD.CURRENT_GENERATION_INITIAL_CONDITION)
    action_display_result = VisualizingLQCD.animation_display_setup_for_gaugefield(
        setup_u, 2, 2, 2, 2, 3;
        level_target=VisualizingLQCD.LEVEL_TARGET_ACTION_DENSITY_HIGH)
    @test action_display_result.render_style == VisualizingLQCD.RENDER_STYLE_ACTION_DENSITY_BLOB
    @test action_display_result.display_setup.render_kind == :mesh
    @test action_display_result.display_setup.observable_info["kind"] == "local_action_density"
    legacy_display_result = VisualizingLQCD.animation_display_setup_for_gaugefield(
        setup_u, 2, 2, 2, 2, 3;
        level_target=VisualizingLQCD.LEVEL_TARGET_LEGACY_NEGLOG_HIGH,
        render_style=VisualizingLQCD.RENDER_STYLE_CURRENT)
    @test legacy_display_result.render_style == VisualizingLQCD.RENDER_STYLE_CURRENT
    @test legacy_display_result.display_setup.render_kind == :contour
    @test legacy_display_result.display_setup.display_transform_info["kind"] == "neglog"
    @test_throws ArgumentError VisualizingLQCD.animation_display_setup_for_gaugefield(
        setup_u, 2, 2, 2, 2, 3;
        level_target=VisualizingLQCD.LEVEL_TARGET_ACTION_DENSITY_HIGH,
        render_style=VisualizingLQCD.RENDER_STYLE_CURRENT)

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
    @test VisualizingLQCD.effective_render_theme(
        VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME, nothing) ==
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
    visible_ticks = VisualizingLQCD.animation_axis_tick_spec(4, 0.1;
        show_axis_labels=true)
    @test collect(visible_ticks.positions) ≈ collect(range(0, stop=0.4, length=4))
    @test visible_ticks.labels[1] == ""
    @test visible_ticks.labels[2] != ""
    hidden_ticks = VisualizingLQCD.animation_axis_tick_spec(4, 0.1;
        show_axis_labels=false)
    @test all(==(""), hidden_ticks.labels)
    axis_camera = VisualizingLQCD.camera_settings(:mesh;
        camera_azimuth=0.0,
        camera_elevation=0.5)
    axis_kwargs = VisualizingLQCD.animation_axis_kwargs(
        action_setup,
        VisualizingLQCD.render_theme_settings(VisualizingLQCD.RENDER_THEME_DARK),
        axis_camera;
        a=0.1,
        lattice_size=(4, 4, 4),
        movie_title="test title",
        show_axis_labels=false)
    @test axis_kwargs[:aspect] == :data
    @test axis_kwargs[:xlabel] == ""
    @test all(==(""), axis_kwargs[:xticks][2])
    @test axis_kwargs[:azimuth] == 0.0
    @test axis_kwargs[:elevation] == 0.5
    @test VisualizingLQCD.action_density_blob_color(0.5; qmin=0.0, qmax=1.0) isa
          VisualizingLQCD.Vec3f
    positive_low_color = VisualizingLQCD.topological_charge_volume_magnitude_color(
        1.0; qmin=1.0, qmax=4.0,
        palette=VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_POSITIVE_PALETTE)
    positive_high_color = VisualizingLQCD.topological_charge_volume_magnitude_color(
        4.0; qmin=1.0, qmax=4.0,
        palette=VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_POSITIVE_PALETTE)
    negative_low_color = VisualizingLQCD.topological_charge_volume_magnitude_color(
        1.0; qmin=1.0, qmax=4.0,
        palette=VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_NEGATIVE_PALETTE)
    negative_high_color = VisualizingLQCD.topological_charge_volume_magnitude_color(
        4.0; qmin=1.0, qmax=4.0,
        palette=VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_NEGATIVE_PALETTE)
    @test positive_low_color != positive_high_color
    @test negative_low_color != negative_high_color
    @test VisualizingLQCD.local_color_value(ones(3, 3, 3), 2, 2, 2) == 1.0
    action_geometry = VisualizingLQCD.action_density_blob_geometry(
        fill(action_setup.body_level + 1, 2, 2, 2), action_setup;
        a=1.0, lattice_size=(2, 2, 2))
    @test action_geometry.info.vertices > 0
    @test action_geometry.info.faces > 0
    @test length(action_geometry.colors) == action_geometry.info.vertices
    helper_action_geometry = VisualizingLQCD.mesh_geometry_for_slice(
        fill(action_setup.body_level + 1, 2, 2, 2), action_setup;
        a=1.0, lattice_size=(2, 2, 2))
    @test VisualizingLQCD.mesh_renderer_kind(action_setup) == :action_density_blob
    @test helper_action_geometry.info.vertices == action_geometry.info.vertices
    @test helper_action_geometry.info.faces == action_geometry.info.faces
    unsupported_mesh_setup = merge(action_setup, (mesh_renderer=:unsupported,))
    @test_throws ArgumentError VisualizingLQCD.mesh_geometry_for_slice(
        fill(action_setup.body_level + 1, 2, 2, 2), unsupported_mesh_setup;
        a=1.0, lattice_size=(2, 2, 2))
    render_cache = Dict{Int,Any}()
    cached_action_geometry = VisualizingLQCD.mesh_geometry_for_render_slice(
        fill(action_setup.body_level + 1, 2, 2, 2), action_setup;
        a=1.0, lattice_size=(2, 2, 2), mesh_cache=render_cache, slice4=1)
    cached_action_geometry_again = VisualizingLQCD.mesh_geometry_for_render_slice(
        fill(0.0, 2, 2, 2), action_setup;
        a=1.0, lattice_size=(2, 2, 2), mesh_cache=render_cache, slice4=1)
    @test length(render_cache) == 1
    @test cached_action_geometry_again.info.vertices ==
          cached_action_geometry.info.vertices
    @test_throws ArgumentError VisualizingLQCD.mesh_geometry_for_render_slice(
        fill(action_setup.body_level + 1, 2, 2, 2), action_setup;
        a=1.0, lattice_size=(2, 2, 2), mesh_cache=Dict{Int,Any}())
    delete_recorder = DeleteRecorder(Any[])
    @test VisualizingLQCD.delete_plot_obj!(delete_recorder, nothing) === nothing
    @test isempty(delete_recorder.deleted)
    @test VisualizingLQCD.delete_plot_obj!(delete_recorder, :single) === nothing
    @test delete_recorder.deleted == Any[:single]
    @test VisualizingLQCD.delete_plot_obj!(delete_recorder, [:a, :b]) === nothing
    @test delete_recorder.deleted == Any[:single, :a, :b]

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

    default_topological_volume_setup = VisualizingLQCD.topological_charge_display_level_setup(
        reshape([-4.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0], 2, 2, 2, 1);
        render_style=VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME)
    @test default_topological_volume_setup.level_selection_info["quantiles"] ==
          collect(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_LEVEL_QUANTILES)
    @test default_topological_volume_setup.render_style_info["color_quantile"] ==
          VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_COLOR_QUANTILE

    topological_volume_setup = VisualizingLQCD.topological_charge_display_level_setup(
        reshape([-4.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0], 2, 2, 2, 1);
        render_style=VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME,
        level_quantiles=(0.0, 1.0),
        color_quantile=1.0)
    @test topological_volume_setup.render_kind == :mesh
    @test topological_volume_setup.mesh_renderer == :topological_charge_volume
    @test topological_volume_setup.positive_body_level == 1.0
    @test topological_volume_setup.negative_body_level == 1.0
    @test topological_volume_setup.render_style_info["render_style"] ==
          "topological_charge_volume"
    @test topological_volume_setup.render_style_info["geometry"] ==
          "signed_positive_negative_filled_superlevel_solid_mesh"
    @test topological_volume_setup.render_style_info["mesh_source"] ==
          "topological_charge_volume_geometry"
    @test topological_volume_setup.render_style_info["positive_color"] ==
          collect(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_POSITIVE_COLOR)
    @test topological_volume_setup.render_style_info["color_method"] ==
          "local_absolute_topological_charge_density_quantile"
    @test topological_volume_setup.render_style_info["positive_color_palette"] ==
          String(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_POSITIVE_PALETTE)
    @test topological_volume_setup.render_style_info["negative_color_palette"] ==
          String(VisualizingLQCD.CURRENT_TOPOLOGICAL_CHARGE_VOLUME_NEGATIVE_PALETTE)
    @test topological_volume_setup.positive_color_range == (1.0, 4.0)
    @test topological_volume_setup.negative_color_range == (1.0, 4.0)
    volume_slice = fill(2.0, 3, 3, 3)
    volume_slice[1, :, :] .= -2.0
    topological_volume_geometry = VisualizingLQCD.topological_charge_volume_geometry(
        volume_slice, topological_volume_setup; a=1.0, lattice_size=(3, 3, 3))
    @test topological_volume_geometry.positive !== nothing
    @test topological_volume_geometry.negative !== nothing
    @test topological_volume_geometry.info["positive_info"].vertices > 0
    @test topological_volume_geometry.info["negative_info"].vertices > 0
    helper_topological_volume_geometry = VisualizingLQCD.mesh_geometry_for_slice(
        volume_slice, topological_volume_setup; a=1.0, lattice_size=(3, 3, 3))
    @test VisualizingLQCD.mesh_renderer_kind(topological_volume_setup) ==
          :topological_charge_volume
    @test helper_topological_volume_geometry.info["positive_info"].vertices ==
          topological_volume_geometry.info["positive_info"].vertices
    @test helper_topological_volume_geometry.info["negative_info"].vertices ==
          topological_volume_geometry.info["negative_info"].vertices
    gradient_slice = zeros(6, 3, 3)
    gradient_slice[2, :, :] .= 1.2
    gradient_slice[3, :, :] .= 2.0
    gradient_slice[4, :, :] .= 3.0
    gradient_slice[5, :, :] .= 4.0
    gradient_setup = merge(topological_volume_setup, (
        positive_body_level=1.0,
        negative_body_level=nothing,
        positive_color_range=(1.0, 4.0),
        negative_color_range=nothing,
        color_radius=0,
        color_stat=:sample,
        color_top_fraction=1.0,
    ))
    gradient_geometry = VisualizingLQCD.topological_charge_volume_geometry(
        gradient_slice, gradient_setup; a=1.0, lattice_size=(6, 3, 3))
    @test gradient_geometry.positive !== nothing
    @test length(unique(gradient_geometry.positive.colors)) > 1
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

    instanton_lattice = 8
    instanton_nc = 2
    instanton_wing = 1
    instanton_u = Gaugefields.Oneinstanton(
        instanton_nc,
        instanton_wing,
        instanton_lattice,
        instanton_lattice,
        instanton_lattice,
        instanton_lattice)
    instanton_density = VisualizingLQCD.topological_charge_density(
        instanton_u,
        instanton_lattice,
        instanton_lattice,
        instanton_lattice,
        instanton_lattice,
        instanton_nc)
    density_charge = VisualizingLQCD.topological_charge_from_density(instanton_density)
    reference_charge = reference_clover_topological_charge(instanton_u)
    @test density_charge ≈ reference_charge atol = 1e-10
    @test abs(density_charge) > 0.5
    topological_display_result = VisualizingLQCD.animation_display_setup_for_gaugefield(
        instanton_u,
        instanton_lattice,
        instanton_lattice,
        instanton_lattice,
        instanton_lattice,
        instanton_nc;
        level_target=VisualizingLQCD.LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY,
        render_style=VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME)
    @test topological_display_result.render_style ==
          VisualizingLQCD.RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME
    @test topological_display_result.display_setup.render_kind == :mesh
    @test topological_display_result.display_setup.mesh_renderer ==
          :topological_charge_volume
    @test size(topological_display_result.display_setup.display_field) ==
          size(instanton_density)
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
    topology_readme_text = read(joinpath(root, "scripts", "topology_fixtures", "README.md"),
        String)
    sample_metadata_text = read(joinpath(root, "$(SAMPLE_BASENAME).mp4.metadata.json"),
        String)
    @test occursin("$(SAMPLE_BASENAME).gif", readme_text)
    @test occursin("width=\"300\"", readme_text)
    @test occursin("`128` frames", readme_text)
    @test occursin("show_axis_labels=false", readme_text)
    @test occursin("LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY", readme_text)
    @test occursin("RENDER_STYLE_TOPOLOGICAL_CHARGE_VOLUME", readme_text)
    @test occursin("`abs(q)`", readme_text)
    @test occursin("$(SAMPLE_BASENAME).mp4.metadata.json", readme_text)
    @test !occursin("plaquette_3D_contour_animation32323264beta6.0-gf05hb40flow200-fullturn",
        readme_text)
    @test occursin("q0.940", topology_readme_text)
    @test occursin("--show-render-progress true", topology_readme_text)
    @test isfile(joinpath(root, "$(SAMPLE_BASENAME).mp4"))
    @test isfile(joinpath(root, "$(SAMPLE_BASENAME).mp4.metadata.json"))
    @test isfile(joinpath(root, "$(SAMPLE_BASENAME).gif"))
    @test isfile(joinpath(root, "test", "$(SAMPLE_BASENAME).gif"))

    @test occursin("\"lattice_size\": [24, 24, 24, 32]", sample_metadata_text)
    @test occursin("\"level_target\": \"topological_charge_density\"",
        sample_metadata_text)
    @test occursin("\"render_style\": \"topological_charge_volume\"",
        sample_metadata_text)
    @test occursin("\"frame_count\": 128", sample_metadata_text)
    @test occursin("\"duration_seconds\": 16.0", sample_metadata_text)
    @test occursin("\"show_axis_labels\": false", sample_metadata_text)
    @test occursin("\"not_real_time_minkowski_evolution\": true", sample_metadata_text)
    @test occursin("{\"frame\": 128, \"slice4\": 32}", sample_metadata_text)
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
