# Proposed result contracts for VisualizingLQCD.jl refactor.
# These types are intentionally lightweight. They can be introduced before the
# full pipeline split because they do not depend on Gaugefields or Makie.

Base.@kwdef struct AnimationResult
    video_path::String
    metadata_path::String
    lattice::NTuple{4,Int}
    nc::Int
    beta::Union{Nothing,Float64} = nothing
    observable_name::String
    transform_name::String
    epsilon::Float64
    display_levels::Vector{Float64}
    raw_equivalent_levels::Vector{Float64}
    frame_map::Vector{NamedTuple}
end

Base.@kwdef struct GenerationResult
    configuration_path::String
    lattice::NTuple{4,Int}
    nc::Int
    beta::Float64
    heatbath_sweeps::Int
    flow_steps::Int
    final_plaquette::Float64
    final_polyakov::ComplexF64
end

make_frame_map(NT::Integer; loops::Integer=1) = [
    (frame=i, slice4=((i - 1) % NT) + 1) for i in 1:(NT * loops)
]

raw_equivalent_level_neglog(L::Real; epsilon::Real=1e-7) =
    max(exp(-Float64(L)) - Float64(epsilon), 0.0)
