struct ConfigSpec
    lattice::NTuple{4,Int}
    nc::Int
    beta::Union{Nothing,Float64}
    filename::String
end

struct FlowSpec
    steps::Int
    step_size::Float64
end

struct TransformSpec
    kind::Symbol              # :identity, :log, :neglog
    epsilon::Float64
    epsilon_policy::Symbol    # :fixed or :auto_quantile
    clip_quantiles::Tuple{Float64,Float64}
end

struct LevelSpec
    method::Symbol            # :quantile, :fixed, :mean_std
    quantiles::Vector{Float64}
    values::Vector{Float64}
    tail::Symbol              # :upper, :lower, :explicit
    global_across_slices::Bool
end

struct RenderSpec
    backend::Symbol           # :glmakie, :cairomakie, :auto
    output::String
    framerate::Int
    show_frame_label::Bool
    title::String
end

abstract type AbstractObservable end

struct PlaquettePlane <: AbstractObservable
    plane::Tuple{Int,Int}
end

struct PlaquetteSum <: AbstractObservable end

struct ScalarField{T,N,A<:AbstractArray{T,N}}
    data::A
    name::String
    unit::String
    description::String
end

struct FieldBundle{R,D}
    raw::R
    display::D
    transform_name::String
    epsilon::Float64
    raw_focus::String
end
