function spatial_axes(spec::ConfigSpec)
    nx, ny, nz, _ = spec.lattice
    a = 1.0
    return (x=collect(range(0, a * nx, length=nx)),
            y=collect(range(0, a * ny, length=ny)),
            z=collect(range(0, a * nz, length=nz)))
end

function render_movie(field::ScalarField, axes, levels::Vector{Float64}, spec::RenderSpec)
    # Production code should call GLMakie or CairoMakie here.
    # This skeleton intentionally keeps the renderer independent from Gaugefields.
    return (field=field.name, axes=axes, levels=levels, output=spec.output)
end
