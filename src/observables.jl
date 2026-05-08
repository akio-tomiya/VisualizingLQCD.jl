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
