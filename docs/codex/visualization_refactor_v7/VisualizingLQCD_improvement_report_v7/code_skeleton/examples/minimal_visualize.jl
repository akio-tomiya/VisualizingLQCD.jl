include("../src/VisualizingLQCD.jl")
using .VisualizingLQCD

raw = VisualizingLQCD.synthetic_scalar_field(16, 16, 16, 4)
transform = TransformSpec(:neglog, 1e-7, :fixed, (0.0, 1.0))
bundle = build_display_field(raw, transform)
levels = choose_levels(bundle.display.data,
                       LevelSpec(:quantile, [0.8, 0.9, 0.95], Float64[], :upper, true))
@show levels
@show [invert_display_level(L, transform, bundle.epsilon) for L in levels]
