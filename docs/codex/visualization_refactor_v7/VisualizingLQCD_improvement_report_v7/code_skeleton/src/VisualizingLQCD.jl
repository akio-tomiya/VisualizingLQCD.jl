module VisualizingLQCD

# Design skeleton only. This file is not a drop-in replacement for the current package.
# The goal is to show separable boundaries for future PRs.

include("types.jl")
include("current_defaults.jl")
include("contracts.jl")
include("transforms.jl")
include("levels.jl")
include("frames.jl")
include("metadata.jl")
include("observables.jl")
include("renderers.jl")
include("animation.jl")

export ConfigSpec, FlowSpec, TransformSpec, LevelSpec, RenderSpec
export LegacyVisualDefaults, legacy_transform_spec, legacy_level_spec, legacy_render_spec
export PlaquettePlane, PlaquetteSum, ScalarField, FieldBundle
export display_transform, invert_display_level, choose_levels, frame_map
export CURRENT_LOG_EPSILON, CURRENT_LEVEL_STD_MULTIPLIER, CURRENT_LEVEL_STEP
export visualize_lqcd
export AnimationResult, GenerationResult, make_frame_map, raw_equivalent_level_neglog

end
