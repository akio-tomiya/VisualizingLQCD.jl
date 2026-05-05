# Gauge-field observables used by the visualization pipeline.

function plaquette_plane_deviation(U, NX, NY, NZ, NT, NC;
    loop=CURRENT_WILSONLINE_LOOP,
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

function transform_field_neglog(raw)
    display = similar(raw, Float64)
    for i in eachindex(raw)
        display[i] = display_transform_neglog(raw[i])
    end
    return display
end
