# Configuration generation using Gaugefields.jl
# Ref: https://github.com/akio-tomiya/Gaugefields.jl

# - A. Tomiya 2025/01/11

"""
    heatbathtest_4D(NX, NY, NZ, NT, β, NC, flow_steps_in, confname)

Compatibility wrapper kept for one release: generate a configuration with
[`generate_gauge`](@ref), save it to `confname` (format from the extension,
ILDG for `.ildg`), and return the normalized plaquette.
"""
function heatbathtest_4D(NX, NY, NZ, NT, β, NC, flow_steps_in, confname)
    U = generate_gauge((NX, NY, NZ, NT); beta=β, colors=NC, flow_steps=flow_steps_in)
    save_gauge(confname, U)
    plaquette = measure_plaquette(U)
    println("plaq_t = $plaquette")
    return plaquette
end
export heatbathtest_4D
