# Gauge-field observables used by the visualization pipeline.

plaquette_loop(mu::Integer, nu::Integer) = [(mu, +1), (nu, +1), (mu, -1), (nu, -1)]

# Site-local color algebra without slicing out matrices. The summation order
# matches LinearAlgebra's tr and its small-matrix multiplication, so the values
# agree with real(tr(A[:, :, site...])) and real(tr(A[:, :, site...] * B[:, :, site...])).
@inline function site_trace(A, NC, x, y, z, t)
    s = A[1, 1, x, y, z, t]
    for i in 2:NC
        s += A[i, i, x, y, z, t]
    end
    return s
end

@inline function site_trace_product(A, B, NC, x, y, z, t)
    s = zero(ComplexF64)
    for i in 1:NC
        d = A[i, 1, x, y, z, t] * B[1, i, x, y, z, t]
        for k in 2:NC
            d += A[i, k, x, y, z, t] * B[k, i, x, y, z, t]
        end
        s = i == 1 ? d : s + d
    end
    return s
end

function plaquette_plane_deviation(U, NX, NY, NZ, NT, NC;
    plane=(1, 2),
    loop=plaquette_loop(plane[1], plane[2]),
    temp_count=CURRENT_WILSONLINE_TEMP_COUNT)

    loops = [Wilsonline(loop; Dim=4)]
    Uloop = similar(U[1])
    temps = [similar(U[1]) for _ in 1:temp_count]
    evaluate_gaugelinks!(Uloop, loops, U, temps)

    raw = zeros(Float64, NX, NY, NZ, NT)
    Threads.@threads for t in 1:NT
        for z in 1:NZ, y in 1:NY, x in 1:NX
            raw[x, y, z, t] = 1 - real(site_trace(Uloop, NC, x, y, z, t)) / NC
        end
    end
    return raw
end

function local_action_density(U, NX, NY, NZ, NT, NC;
    planes=CURRENT_PLAQUETTE_PLANES_4D,
    temp_count=CURRENT_WILSONLINE_TEMP_COUNT)

    density = zeros(Float64, NX, NY, NZ, NT)
    for plane in planes
        density .+= plaquette_plane_deviation(U, NX, NY, NZ, NT, NC;
            plane=plane, temp_count=temp_count)
    end
    density ./= length(planes)
    return density
end

const TOPOLOGICAL_CHARGE_METHODS = (
    TOPOLOGICAL_CHARGE_METHOD_PLAQUETTE,
    TOPOLOGICAL_CHARGE_METHOD_CLOVER,
    TOPOLOGICAL_CHARGE_METHOD_IMPROVED,
    TOPOLOGICAL_CHARGE_METHOD_BILSON_THOMPSON,
)

function validate_topological_charge_method(method::Symbol)
    method in TOPOLOGICAL_CHARGE_METHODS ||
        throw(ArgumentError("unsupported topological charge method: $method"))
    return method
end

function topological_epsilon4(mu::Integer, nu::Integer, rho::Integer, sigma::Integer)
    values = (mu, nu, rho, sigma)
    all(1 <= value <= 4 for value in values) ||
        throw(ArgumentError("epsilon indices should be in 1:4"))
    length(unique(values)) == 4 || return 0

    inversions = 0
    for i in 1:3, j in (i + 1):4
        inversions += values[i] > values[j]
    end
    return iseven(inversions) ? 1 : -1
end

function topological_epsilon_terms()
    terms = Tuple{Int,Int,Int,Int,Int}[]
    for mu in 1:4, nu in 1:4
        mu == nu && continue
        for rho in 1:4, sigma in 1:4
            rho == sigma && continue
            epsilon = topological_epsilon4(mu, nu, rho, sigma)
            epsilon == 0 && continue
            push!(terms, (mu, nu, rho, sigma, epsilon))
        end
    end
    return terms
end

# Field strengths use the loop sets of QCDMeasurements.jl ("plaq", "clover",
# "rect"), so the definitions agree with Topological_charge_measurement.
# QCDMeasurements has no public per-site density yet; only the final
# epsilon contraction is done here.
function topological_field_strength_ta(U, loopset::AbstractString)
    temps = Temporalfields(U[1]; num=CURRENT_TOPOLOGICAL_CHARGE_TEMP_COUNT)
    field_strength = Matrix{typeof(U[1])}(undef, 4, 4)
    for mu in 1:4, nu in 1:4
        field_strength[mu, nu] = similar(U[1])
    end
    loop_count = QCDMeasurements.calc_UμνTA!(field_strength, loopset, U, temps)
    return field_strength, loop_count
end

# factor * sum_{mu nu rho sigma} epsilon * real tr(A[mu, nu] B[rho, sigma]) at each site.
# Each site accumulates the terms in the same (mu, nu, rho, sigma) order as a
# term-by-term sweep over the lattice would.
function topological_contraction(A, B, NX, NY, NZ, NT, NC, factor)
    terms = topological_epsilon_terms()
    density = zeros(Float64, NX, NY, NZ, NT)
    Threads.@threads for t in 1:NT
        for z in 1:NZ, y in 1:NY, x in 1:NX
            acc = 0.0
            for (mu, nu, rho, sigma, epsilon) in terms
                acc += factor * epsilon * real(site_trace_product(
                    A[mu, nu], B[rho, sigma], NC, x, y, z, t))
            end
            density[x, y, z, t] = acc
        end
    end
    return density
end

function topological_charge_density(U, NX, NY, NZ, NT, NC;
    method=CURRENT_TOPOLOGICAL_CHARGE_METHOD)

    validated_method = validate_topological_charge_method(method)
    normalization = CURRENT_TOPOLOGICAL_CHARGE_NORMALIZATION
    if validated_method == TOPOLOGICAL_CHARGE_METHOD_PLAQUETTE
        plaq, n = topological_field_strength_ta(U, "plaq")
        return topological_contraction(plaq, plaq, NX, NY, NZ, NT, NC, normalization / n^2)
    end

    clover, n_clover = topological_field_strength_ta(U, "clover")
    q_clover = topological_contraction(clover, clover, NX, NY, NZ, NT, NC,
        normalization / n_clover^2)
    validated_method == TOPOLOGICAL_CHARGE_METHOD_CLOVER && return q_clover

    rect, n_rect = topological_field_strength_ta(U, "rect")
    q_rect = topological_contraction(rect, rect, NX, NY, NZ, NT, NC,
        normalization / n_rect^2)
    if validated_method == TOPOLOGICAL_CHARGE_METHOD_IMPROVED
        # Alexandrou, Athenodorou, and Jansen, Phys. Rev. D 92, 125014 (2015),
        # as in QCDMeasurements.calculate_topological_charge_improved.
        return @. (5 / 3) * q_clover - (1 / 12) * (2 * q_rect)
    end

    # Bilson-Thompson et al., Ann. Phys. 304, 1 (2003), as in
    # QCDMeasurements.calculate_topological_charge_bilson_thompson.
    cross = topological_contraction(rect, clover, NX, NY, NZ, NT, NC,
        normalization / n_clover^2)
    c, r = 5 / 3, -1 / 6
    return @. c^2 * q_clover + 2 * c * r * cross + 4 * r^2 * q_rect
end

topological_charge_from_density(density) = sum(density)

function transform_field_neglog(raw)
    display = similar(raw, Float64)
    for i in eachindex(raw)
        display[i] = display_transform_neglog(raw[i])
    end
    return display
end

function plaquette_plane_observable_metadata(; plane=(1, 2))
    return Dict(
        "kind" => "plaquette_plane",
        "plane" => collect(plane),
        "wilsonline_loop" => [collect(step) for step in plaquette_loop(plane[1], plane[2])],
    )
end

function local_action_density_observable_metadata(; planes=CURRENT_PLAQUETTE_PLANES_4D)
    return Dict(
        "kind" => "local_action_density",
        "definition" => "(1 / number_of_planes) * sum_mu_lt_nu(1 - real(tr(U_mu_nu)) / Nc)",
        "planes" => [collect(plane) for plane in planes],
        "plane_count" => length(planes),
    )
end

function topological_charge_density_observable_metadata(;
    method=CURRENT_TOPOLOGICAL_CHARGE_METHOD)
    validated_method = validate_topological_charge_method(method)
    return Dict(
        "kind" => "topological_charge_density",
        "definition" => "-1 / (32 * pi^2) * epsilon_mu_nu_rho_sigma * tr(F_mu_nu * F_rho_sigma)",
        "method" => String(validated_method),
        "loopsets" => validated_method == TOPOLOGICAL_CHARGE_METHOD_PLAQUETTE ? ["plaq"] :
                       validated_method == TOPOLOGICAL_CHARGE_METHOD_CLOVER ? ["clover"] :
                       ["clover", "rect"],
        "field_strength_source" => "QCDMeasurements.calc_UμνTA!",
        "normalization" => "-1/(32*pi^2)",
        "signed" => true,
        "positive_negative_density" => true,
    )
end
