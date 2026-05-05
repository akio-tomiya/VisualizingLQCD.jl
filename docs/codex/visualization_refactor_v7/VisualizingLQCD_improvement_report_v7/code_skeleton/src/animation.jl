function load_configuration(spec::ConfigSpec)
    # Production code should call ILDG(filename), Initialize_Gaugefields, and load_gaugefield!.
    return spec
end

function apply_gradient_flow!(_U, flow::FlowSpec)
    # Production code should call Gradientflow and flow! only when flow.steps > 0.
    return nothing
end

function visualize_lqcd(spec::ConfigSpec;
                        flow=FlowSpec(0, 0.01),
                        observable=PlaquettePlane((1, 2)),
                        transform=TransformSpec(:neglog, 1e-7, :fixed, (0.0, 1.0)),
                        levels=LevelSpec(:quantile, [0.8, 0.9, 0.95, 0.98],
                                         Float64[], :upper, true),
                        render=RenderSpec(:glmakie, "qcd_vacuum.mp4", 12,
                                          false, "Plaquette log iso-surface"),
                        metadata="qcd_vacuum.json")
    U = load_configuration(spec)
    apply_gradient_flow!(U, flow)
    raw = measure(U, observable)
    bundle = build_display_field(raw, transform)
    iso_levels = choose_levels(bundle.display.data, levels)
    axes = spatial_axes(spec)
    render_movie(bundle.display, axes, iso_levels, render)
    meta = metadata_dict(spec, flow, observable, transform, levels, render, iso_levels, bundle)
    return bundle, meta
end
