# Operators: turn a gauge configuration into a LatticeField.
#
# `measure(op, U)` extends QCDMeasurements.measure with the operator types
# below, so `using VisualizingLQCD, QCDMeasurements` sees a single function.
#
# Built-in operators:     TopologicalChargeDensity, ActionDensity, PlaquetteDensity
# User-defined operators: LoopDensity         f(W)          W = closed-path product at a site
#                         FieldStrengthDensity  f(F)        F[mu, nu] = clover field strength
#                         SiteOperator          f(ctx, site) free access to links around a site

abstract type AbstractLatticeOperator end

lattice_extents(U) = (U[1].NX, U[1].NY, U[1].NZ, U[1].NT)
num_colors(U) = U[1].NC

# Color matrix of a link-like field at one site as a static matrix.
@inline function site_matrix(A, ::Val{NC}, x, y, z, t) where {NC}
    return SMatrix{NC,NC,ComplexF64}(ntuple(
        i -> A[(i - 1) % NC + 1, (i - 1) ÷ NC + 1, x, y, z, t], Val(NC * NC)))
end

# Evaluate f(x, y, z, t)::Real on every site, in parallel over Euclidean slices.
function site_map(f, dims)
    out = zeros(Float64, dims)
    Threads.@threads for t in 1:dims[4]
        for z in 1:dims[3], y in 1:dims[2], x in 1:dims[1]
            out[x, y, z, t] = f(x, y, z, t)
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Built-in operators

"""
    TopologicalChargeDensity(; method=:clover)

q(x) = -1/(32π²) ε_{μνρσ} tr F_{μν} F_{ρσ}, with field strengths from the loop
sets of QCDMeasurements.jl. `method` is `:plaquette`, `:clover`, `:improved`
(Alexandrou et al. 2015), or `:bilson_thompson`. The sum over sites equals
the charge of `QCDMeasurements.Topological_charge_measurement`.
"""
struct TopologicalChargeDensity <: AbstractLatticeOperator
    method::Symbol
    TopologicalChargeDensity(method::Symbol) = new(validate_topological_charge_method(method))
end
TopologicalChargeDensity(; method::Symbol=CURRENT_TOPOLOGICAL_CHARGE_METHOD) =
    TopologicalChargeDensity(method)

function measure(op::TopologicalChargeDensity, U)
    data = topological_charge_density(U, lattice_extents(U)..., num_colors(U); method=op.method)
    return LatticeField(data; name="topological_charge_density", signed=true,
        info=topological_charge_density_observable_metadata(method=op.method))
end

"""
    ActionDensity(; planes=all six planes)

s(x) = (1/number of planes) Σ_{μ<ν} (1 - Re tr U_{μν}(x) / Nc).
"""
struct ActionDensity <: AbstractLatticeOperator
    planes::Vector{Tuple{Int,Int}}
end
ActionDensity(; planes=CURRENT_PLAQUETTE_PLANES_4D) = ActionDensity(collect(planes))

function measure(op::ActionDensity, U)
    data = local_action_density(U, lattice_extents(U)..., num_colors(U); planes=op.planes)
    return LatticeField(data; name="action_density",
        info=local_action_density_observable_metadata(planes=op.planes))
end

"""
    PlaquetteDensity(mu, nu)

p(x) = 1 - Re tr U_{μν}(x) / Nc for one plane.
"""
struct PlaquetteDensity <: AbstractLatticeOperator
    plane::Tuple{Int,Int}
end
PlaquetteDensity(mu::Integer, nu::Integer) = PlaquetteDensity((Int(mu), Int(nu)))

function measure(op::PlaquetteDensity, U)
    data = plaquette_plane_deviation(U, lattice_extents(U)..., num_colors(U); plane=op.plane)
    return LatticeField(data; name="plaquette_density",
        info=plaquette_plane_observable_metadata(plane=op.plane))
end

# ---------------------------------------------------------------------------
# User-defined operators

const WilsonPath = Vector{Tuple{Int,Int}}

function validate_closed_path(path)
    displacement = zeros(Int, 4)
    for (mu, n) in path
        1 <= mu <= 4 || throw(ArgumentError("path direction should be in 1:4; got $mu"))
        displacement[mu] += n
    end
    all(iszero, displacement) ||
        throw(ArgumentError("path $path is not closed (net displacement $displacement)"))
    return WilsonPath(path)
end

"""
    LoopDensity(f, path; name="loop_density", signed=true)
    LoopDensity(f, paths; ...)

Evaluate the path-ordered product `W(x)` of a closed path starting at each
site (or the sum over several paths) and return `f(W)` per site. `W` is an
`SMatrix{Nc,Nc,ComplexF64}`. A path is a list of `(direction, steps)` pairs,
the same notation as Wilsonloop.jl:

```julia
plaq = LoopDensity([(1, +1), (2, +1), (1, -1), (2, -1)]) do W
    1 - real(tr(W)) / size(W, 1)
end
field = measure(plaq, U)
```

`f` runs on several threads at once, so it should not mutate shared state.
"""
struct LoopDensity{F} <: AbstractLatticeOperator
    f::F
    paths::Vector{WilsonPath}
    name::String
    signed::Bool
end

function LoopDensity(f, paths::AbstractVector; name::AbstractString="loop_density",
    signed::Bool=true)
    isempty(paths) && throw(ArgumentError("LoopDensity needs at least one path"))
    path_list = first(paths) isa Tuple ? [paths] : collect(paths)
    return LoopDensity(f, [validate_closed_path(p) for p in path_list], String(name), signed)
end

function measure(op::LoopDensity, U)
    loops = [Wilsonline(path; Dim=4) for path in op.paths]
    W = similar(U[1])
    temps = [similar(U[1]) for _ in 1:CURRENT_WILSONLINE_TEMP_COUNT]
    evaluate_gaugelinks!(W, loops, U, temps)
    data = loop_density_values(op.f, W, Val(num_colors(U)), lattice_extents(U))
    return LatticeField(data; name=op.name, signed=op.signed, info=Dict{String,Any}(
        "kind" => "loop_density",
        "name" => op.name,
        "paths" => [[collect(step) for step in path] for path in op.paths],
        "definition" => "user function of the summed path-ordered products W(x)",
    ))
end

loop_density_values(f, W, nc::Val, dims) =
    site_map((x, y, z, t) -> Float64(f(site_matrix(W, nc, x, y, z, t))), dims)

"""
    FieldStrengthDensity(f; loopset="clover", name="field_strength_density", signed=true)

Return `f(F)` per site, where `F[μ, ν]` (μ, ν = 1..4) is the traceless
anti-Hermitian part of the loop set averaged over its loops, as an
`SMatrix{Nc,Nc}` (`F[μ, μ]` is zero). `loopset` is a QCDMeasurements loop-set
name: `"plaq"`, `"clover"`, or `"rect"`. With the clover set,

```julia
q = FieldStrengthDensity() do F
    -sum(VisualizingLQCD.topological_epsilon4(m, n, r, s) * real(tr(F[m, n] * F[r, s]))
         for m in 1:4, n in 1:4, r in 1:4, s in 1:4) / (32π^2)
end
```

reproduces `TopologicalChargeDensity(method=:clover)` up to rounding.
"""
struct FieldStrengthDensity{F} <: AbstractLatticeOperator
    f::F
    loopset::String
    name::String
    signed::Bool
end

function FieldStrengthDensity(f; loopset::AbstractString="clover",
    name::AbstractString="field_strength_density", signed::Bool=true)
    loopset in ("plaq", "clover", "rect") ||
        throw(ArgumentError("unsupported loopset: $loopset"))
    return FieldStrengthDensity(f, String(loopset), String(name), signed)
end

function measure(op::FieldStrengthDensity, U)
    field_strength, loop_count = topological_field_strength_ta(U, op.loopset)
    data = field_strength_values(op.f, field_strength, loop_count,
        Val(num_colors(U)), lattice_extents(U))
    return LatticeField(data; name=op.name, signed=op.signed, info=Dict{String,Any}(
        "kind" => "field_strength_density",
        "name" => op.name,
        "loopset" => op.loopset,
        "field_strength_source" => "QCDMeasurements.calc_UμνTA!",
        "definition" => "user function of F[mu, nu] = TA(loop sum) / number of loops",
    ))
end

function field_strength_values(f, field_strength, loop_count, nc::Val{NC}, dims) where {NC}
    zero_matrix = zero(SMatrix{NC,NC,ComplexF64})
    return site_map(dims) do x, y, z, t
        F = SMatrix{4,4}(ntuple(Val(16)) do i
            mu, nu = (i - 1) % 4 + 1, (i - 1) ÷ 4 + 1
            mu == nu ? zero_matrix :
            site_matrix(field_strength[mu, nu], nc, x, y, z, t) / loop_count
        end)
        Float64(f(F))
    end
end

"""
    SiteOperator(f; name="site_operator", signed=true)

The most general operator: `f(ctx, site)` returns a real number for the site
`site = (x, y, z, t)`. Inside `f`, use

- `link(ctx, μ, site)`: the link `U_μ(site)` as an `SMatrix{Nc,Nc}`,
- `neighbor(ctx, site, μ, n=1)`: the site `n` steps along `μ` (periodic),
- `lattice_size(ctx)`: `(NX, NY, NZ, NT)`.

```julia
plaq12 = SiteOperator() do ctx, x
    U1 = link(ctx, 1, x); U2 = link(ctx, 2, neighbor(ctx, x, 1))
    U3 = link(ctx, 1, neighbor(ctx, x, 2)); U4 = link(ctx, 2, x)
    1 - real(tr(U1 * U2 * U3' * U4')) / 3
end
```
"""
struct SiteOperator{F} <: AbstractLatticeOperator
    f::F
    name::String
    signed::Bool
end
SiteOperator(f; name::AbstractString="site_operator", signed::Bool=true) =
    SiteOperator(f, String(name), signed)

struct SiteContext{NC,TU}
    U::TU
    dims::NTuple{4,Int}
end

link(ctx::SiteContext{NC}, mu::Integer, site) where {NC} =
    site_matrix(ctx.U[mu], Val(NC), site[1], site[2], site[3], site[4])
lattice_size(ctx::SiteContext) = ctx.dims

function neighbor(ctx::SiteContext, site, mu::Integer, n::Integer=1)
    return ntuple(i -> i == mu ? mod1(site[i] + n, ctx.dims[i]) : site[i], 4)
end

function measure(op::SiteOperator, U)
    dims = lattice_extents(U)
    ctx = SiteContext{num_colors(U),typeof(U)}(U, dims)
    data = site_map((x, y, z, t) -> Float64(op.f(ctx, (x, y, z, t))), dims)
    return LatticeField(data; name=op.name, signed=op.signed, info=Dict{String,Any}(
        "kind" => "site_operator",
        "name" => op.name,
        "definition" => "user function of the links around each site",
    ))
end

export measure, AbstractLatticeOperator
export TopologicalChargeDensity, ActionDensity, PlaquetteDensity
export LoopDensity, FieldStrengthDensity, SiteOperator, link, neighbor, lattice_size
