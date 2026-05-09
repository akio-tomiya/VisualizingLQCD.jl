# Gauge-field observables used by the visualization pipeline.

plaquette_loop(mu::Integer, nu::Integer) = [(mu, +1), (nu, +1), (mu, -1), (nu, -1)]

function plaquette_plane_deviation(U, NX, NY, NZ, NT, NC;
    plane=(1, 2),
    loop=plaquette_loop(plane[1], plane[2]),
    temp_count=CURRENT_WILSONLINE_TEMP_COUNT)

    w = Wilsonline(loop)
    Uloop = similar(U[1])
    temps = [similar(U[1]) for _ in 1:temp_count]
    Gaugefields.evaluate_gaugelinks!(Uloop, w, U, temps)

    raw = zeros(Float64, NX, NY, NZ, NT)
    for z in 1:NZ, y in 1:NY, x in 1:NX, t in 1:NT
        raw[x, y, z, t] = 1 - real(tr(Uloop[:, :, x, y, z, t])) / NC
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

function validate_topological_charge_method(method::Symbol)
    method == TOPOLOGICAL_CHARGE_METHOD_CLOVER ||
        throw(ArgumentError("unsupported topological charge method: $method"))
    return method
end

function validate_topological_temp_count(temp_count::Integer)
    temp_count >= CURRENT_TOPOLOGICAL_CHARGE_TEMP_COUNT ||
        throw(ArgumentError("topological charge density requires at least $(CURRENT_TOPOLOGICAL_CHARGE_TEMP_COUNT) temporary gauge fields"))
    return temp_count
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

function topological_clover_loop(mu::Integer, nu::Integer)
    return Wilsonline{4}[
        Wilsonline([(mu, +1), (nu, +1), (mu, -1), (nu, -1)]; Dim=4),
        Wilsonline([(nu, +1), (mu, -1), (nu, -1), (mu, +1)]; Dim=4),
        Wilsonline([(nu, -1), (mu, +1), (nu, +1), (mu, -1)]; Dim=4),
        Wilsonline([(mu, -1), (nu, -1), (mu, +1), (nu, +1)]; Dim=4),
    ]
end

function topological_loopset(method::Symbol)
    validate_topological_charge_method(method)
    loops = Array{Vector{Wilsonline{4}},2}(undef, 4, 4)
    for mu in 1:4, nu in 1:4
        loops[mu, nu] = mu == nu ? Wilsonline{4}[] : topological_clover_loop(mu, nu)
    end
    return loops, 4
end

function topological_field_strength_ta(U;
    method=CURRENT_TOPOLOGICAL_CHARGE_METHOD,
    temp_count=CURRENT_TOPOLOGICAL_CHARGE_TEMP_COUNT)

    validated_method = validate_topological_charge_method(method)
    validated_temp_count = validate_topological_temp_count(temp_count)
    loops, loop_count = topological_loopset(validated_method)
    temps = [similar(U[1]) for _ in 1:validated_temp_count]
    field_strength = Array{eltype(U),2}(undef, 4, 4)
    for mu in 1:4, nu in 1:4
        field_strength[mu, nu] = similar(U[1])
        mu == nu && continue
        Gaugefields.evaluate_gaugelinks!(temps[1], loops[mu, nu], U, temps[2:end])
        Gaugefields.Traceless_antihermitian!(field_strength[mu, nu], temps[1])
    end
    return field_strength, loop_count
end

function topological_charge_density(U, NX, NY, NZ, NT, NC;
    method=CURRENT_TOPOLOGICAL_CHARGE_METHOD,
    temp_count=CURRENT_TOPOLOGICAL_CHARGE_TEMP_COUNT)

    field_strength, loop_count = topological_field_strength_ta(U;
        method=method, temp_count=temp_count)
    density = zeros(Float64, NX, NY, NZ, NT)
    factor = CURRENT_TOPOLOGICAL_CHARGE_NORMALIZATION / loop_count^2
    for mu in 1:4, nu in 1:4
        mu == nu && continue
        field_mu_nu = field_strength[mu, nu]
        for rho in 1:4, sigma in 1:4
            rho == sigma && continue
            epsilon = topological_epsilon4(mu, nu, rho, sigma)
            epsilon == 0 && continue
            field_rho_sigma = field_strength[rho, sigma]
            for t in 1:NT, z in 1:NZ, y in 1:NY, x in 1:NX
                density[x, y, z, t] += factor * epsilon *
                                       real(tr(field_mu_nu[:, :, x, y, z, t] *
                                               field_rho_sigma[:, :, x, y, z, t]))
            end
        end
    end
    return density
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
        "loop_count" => 4,
        "normalization" => "-1/(32*pi^2)",
        "signed" => true,
        "positive_negative_density" => true,
    )
end
