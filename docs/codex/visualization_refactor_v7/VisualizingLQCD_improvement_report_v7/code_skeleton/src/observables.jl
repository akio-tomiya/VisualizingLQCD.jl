# Placeholders. Production implementations should use Gaugefields.jl and Wilsonloop.jl.

function measure(_U, obs::PlaquettePlane)
    error("PlaquettePlane measurement is not implemented in this design skeleton")
end

function measure(_U, obs::PlaquetteSum)
    error("PlaquetteSum measurement is not implemented in this design skeleton")
end

function synthetic_scalar_field(nx=16, ny=16, nz=16, nt=4)
    data = zeros(Float64, nx, ny, nz, nt)
    for t in 1:nt, z in 1:nz, y in 1:ny, x in 1:nx
        r2 = (x - nx/2)^2 + (y - ny/2)^2 + (z - nz/2)^2
        data[x, y, z, t] = exp(-r2 / 32) + 0.01 * t
    end
    return ScalarField(data, "synthetic_raw", "dimensionless", "synthetic Gaussian field")
end
