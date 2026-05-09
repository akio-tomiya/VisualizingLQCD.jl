#!/usr/bin/env julia

using Gaugefields

println("load_gaugefield! methods:")
show(methods(load_gaugefield!))
println()

println("Gaugefields save/load/ILDG names:")
for name in sort!(String.(names(Gaugefields; all=true)))
    lower = lowercase(name)
    if occursin("save", lower) || occursin("load", lower) || occursin("ildg", lower) ||
       occursin("binary", lower)
        println(name)
    end
end
