# Scalar instanton-density fixtures for visualization diagnostics.

function validate_lattice_size4(lattice_size)
    length(lattice_size) == 4 ||
        throw(ArgumentError("lattice_size should have four entries"))
    dims = Tuple(Int.(lattice_size))
    all(dim -> dim > 0, dims) || throw(ArgumentError("lattice extents should be positive"))
    return dims
end

function validate_fixture_center(center, lattice_size)
    length(center) == 4 || throw(ArgumentError("center should have four entries"))
    dims = validate_lattice_size4(lattice_size)
    values = Tuple(Float64.(center))
    all(i -> isfinite(values[i]), 1:4) ||
        throw(ArgumentError("center entries should be finite"))
    return values, dims
end

function validate_fixture_rho(rho::Real)
    value = Float64(rho)
    isfinite(value) && value > 0 || throw(ArgumentError("rho should be positive"))
    return value
end

function validate_fixture_charge_sign(charge_sign::Integer)
    charge_sign == 1 || charge_sign == -1 ||
        throw(ArgumentError("charge_sign should be +1 or -1"))
    return charge_sign
end

function periodic_displacement(site::Real, center::Real, extent::Integer)
    delta = Float64(site) - Float64(center)
    return delta - round(delta / extent) * extent
end

function continuum_su2_instanton_density_value(r2::Real, rho::Real, charge_sign::Integer)
    validated_rho = validate_fixture_rho(rho)
    validated_sign = validate_fixture_charge_sign(charge_sign)
    return validated_sign * 6 / pi^2 * validated_rho^4 / (r2 + validated_rho^2)^4
end

function su2_instanton_topological_density(lattice_size;
    rho,
    center,
    charge_sign=1,
    normalize_charge=CURRENT_INSTANTON_FIXTURE_NORMALIZE_CHARGE)

    center_values, dims = validate_fixture_center(center, lattice_size)
    validated_rho = validate_fixture_rho(rho)
    validated_sign = validate_fixture_charge_sign(charge_sign)
    density = zeros(Float64, dims)
    for index in CartesianIndices(density)
        r2 = 0.0
        for axis in 1:4
            delta = periodic_displacement(index[axis], center_values[axis], dims[axis])
            r2 += delta^2
        end
        density[index] = continuum_su2_instanton_density_value(
            r2, validated_rho, validated_sign)
    end
    if normalize_charge
        current_charge = sum(density)
        abs(current_charge) > eps(Float64) ||
            throw(ArgumentError("cannot normalize zero instanton density"))
        density .*= validated_sign / current_charge
    end
    return density
end

function su2_diga_topological_density(lattice_size, lumps;
    normalize_charge=CURRENT_INSTANTON_FIXTURE_NORMALIZE_CHARGE)

    dims = validate_lattice_size4(lattice_size)
    density = zeros(Float64, dims)
    for lump in lumps
        density .+= su2_instanton_topological_density(dims;
            rho=lump.rho,
            center=lump.center,
            charge_sign=lump.charge_sign,
            normalize_charge=normalize_charge)
    end
    return density
end

function density_peak_info(density, selector)
    index = selector(density)
    return Dict(
        "value" => density[index],
        "index" => collect(Tuple(index)),
    )
end

function topological_density_fixture_diagnostics(density)
    return Dict(
        "shape" => collect(size(density)),
        "total_charge" => sum(density),
        "positive_charge" => sum(max(x, 0.0) for x in density),
        "negative_charge" => sum(min(x, 0.0) for x in density),
        "max" => density_peak_info(density, argmax),
        "min" => density_peak_info(density, argmin),
        "abs_max" => density_peak_info(abs.(density), argmax),
    )
end

function su2_instanton_fixture_metadata(lattice_size;
    rho,
    center,
    charge_sign=1,
    normalize_charge=CURRENT_INSTANTON_FIXTURE_NORMALIZE_CHARGE)

    center_values, dims = validate_fixture_center(center, lattice_size)
    return Dict(
        "kind" => String(INSTANTON_FIXTURE_CONTINUUM_SU2),
        "lattice_size" => collect(dims),
        "rho" => validate_fixture_rho(rho),
        "center" => collect(center_values),
        "charge_sign" => validate_fixture_charge_sign(charge_sign),
        "normalize_charge" => normalize_charge,
        "is_gauge_field_solution" => false,
        "purpose" => "signed topological-density visualization fixture",
    )
end

function su2_diga_fixture_metadata(lattice_size, lumps;
    normalize_charge=CURRENT_INSTANTON_FIXTURE_NORMALIZE_CHARGE)

    dims = validate_lattice_size4(lattice_size)
    return Dict(
        "kind" => String(INSTANTON_FIXTURE_DIGA_SUPERPOSITION),
        "lattice_size" => collect(dims),
        "normalize_charge_per_lump" => normalize_charge,
        "is_gauge_field_solution" => false,
        "purpose" => "qualitative multi-lump signed-density visualization fixture",
        "lumps" => [
            su2_instanton_fixture_metadata(dims;
                rho=lump.rho,
                center=lump.center,
                charge_sign=lump.charge_sign,
                normalize_charge=normalize_charge) for lump in lumps
        ],
    )
end
