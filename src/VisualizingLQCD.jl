module VisualizingLQCD
using Gaugefields
using QCDMeasurements
using Wilsonloop
using LinearAlgebra
using LaTeXStrings
using Printf
using Makie
using GLMakie
using Statistics
using StatsBase
using ProgressMeter

include("constants.jl")
include("input.jl")
include("transforms.jl")
include("levels.jl")
include("rendering.jl")
include("observables.jl")
include("instanton_fixtures.jl")
include("metadata.jl")
include("configuration_generation.jl")
include("visualization.jl")

function __init__()
    GLMakie.activate!()
end

end
