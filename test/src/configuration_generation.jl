# Configuration generation using GaugeFields.jl 
# Ref: https://github.com/akio-tomiya/Gaugefields.jl

# - A. Tomiya 2025/01/11

#include("header.jl")
#include("constants.jl")

function heatbath_SU3!(U, NC, temps, β)
    Dim = 4
    V = temps[5]
    ITERATION_MAX = 10^5

    temps2 = Array{Matrix{ComplexF64},1}(undef, 5)
    temps3 = Array{Matrix{ComplexF64},1}(undef, 5)
    for i = 1:5
        temps2[i] = zeros(ComplexF64, 2, 2)
        temps3[i] = zeros(ComplexF64, NC, NC)
    end

    mapfunc!(A, B) = SU3update_matrix!(A, B, β, NC, temps2, temps3, ITERATION_MAX)

    for μ = 1:Dim
        loops = loops_staple[(Dim, μ)]
        iseven = true

        evaluate_gaugelinks_evenodd!(V, loops, U, temps[1:4], iseven)
        map_U!(U[μ], mapfunc!, V, iseven)

        iseven = false
        evaluate_gaugelinks_evenodd!(V, loops, U, temps[1:4], iseven)
        map_U!(U[μ], mapfunc!, V, iseven)
    end
end

function heatbathtest_4D(NX, NY, NZ, NT, β, NC, flow_steps_in, confname)
    Dim = 4
    Nwing = 0

    U = Initialize_Gaugefields(NC, Nwing, NX, NY, NZ, NT, condition="cold")

    temp1 = similar(U[1])
    temp2 = similar(U[1])

    # for heatbath update
    temp3 = similar(U[1])
    temp4 = similar(U[1])
    temp5 = similar(U[1])

    comb = 6
    factor = 1 / (comb * U[1].NV * U[1].NC)
    @time plaq_t = calculate_Plaquette(U, temp1, temp2) * factor
    println("plaq_t = $plaq_t")
    poly = calculate_Polyakov_loop(U, temp1, temp2)
    println("polyakov loop = $(real(poly)) $(imag(poly))")

    numhb = 20 # numhb-times, Heatbath is applied.
    for itrj = 1:numhb
        heatbath_SU3!(U, NC, [temp1, temp2, temp3, temp4, temp5], β)

        if itrj % 5 == 0
            @time plaq_t = calculate_Plaquette(U, temp1, temp2) * factor
            println("$itrj plaq_t = $plaq_t")
            poly = calculate_Polyakov_loop(U, temp1, temp2)
            println("$itrj polyakov loop = $(real(poly)) $(imag(poly))")
        end
    end

    # Smoothing a gauge field using a gradient flow
    # Otherwise, it looks not good.
    g = Gradientflow(U)
    flow_steps = flow_steps_in # flow_time*0.01 is flow time
    @showprogress "Flowing gauge fields..." for itrj = 1:flow_steps
        flow!(U, g)
    end

    # Save a configuration
    filename = confname
    save_binarydata(U, filename)
    return plaq_t
end
export heatbathtest_4D

