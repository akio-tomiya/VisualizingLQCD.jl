# JSON3 is intentionally not imported here to keep this skeleton readable.
# In production, use JSON3.write or JSON.print with explicit schema_version.

function metadata_dict(spec::ConfigSpec, flow::FlowSpec, observable,
                       transform::TransformSpec, levels::LevelSpec,
                       render::RenderSpec, iso_levels, bundle::FieldBundle)
    raw_equiv = [invert_display_level(L, transform, bundle.epsilon) for L in iso_levels]
    nt = spec.lattice[4]
    return Dict(
        "schema_version" => 1,
        "interpretation" => Dict(
            "spacetime" => "Euclidean lattice configuration",
            "screen_time_label" => render.show_frame_label,
            "not_real_time_minkowski_evolution" => true,
        ),
        "configuration" => Dict(
            "filename" => spec.filename,
            "lattice" => collect(spec.lattice),
            "nc" => spec.nc,
            "beta" => spec.beta,
        ),
        "frame_map" => [Dict("frame" => fm.frame, "slice4" => fm.slice4) for fm in frame_map(nt)],
        "observable" => Dict("type" => string(typeof(observable)), "raw_name" => bundle.raw.name),
        "display_transform" => Dict(
            "kind" => string(transform.kind),
            "formula" => bundle.transform_name,
            "epsilon" => bundle.epsilon,
            "epsilon_policy" => string(transform.epsilon_policy),
            "raw_focus_for_upper_levels" => bundle.raw_focus,
        ),
        "level_selection" => Dict(
            "method" => string(levels.method),
            "global_across_slices" => levels.global_across_slices,
            "quantiles" => levels.quantiles,
            "display_values" => iso_levels,
            "raw_equivalent_values" => raw_equiv,
        ),
        "flow" => Dict("steps" => flow.steps, "step_size" => flow.step_size),
        "render" => Dict("backend" => string(render.backend), "output" => render.output,
                         "framerate" => render.framerate, "title" => render.title),
    )
end
