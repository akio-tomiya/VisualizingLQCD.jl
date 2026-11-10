# LatticeField: a real scalar field on a four-dimensional lattice.
# This is the only thing the rendering side needs to know about; gauge fields,
# Dirac eigenmodes, or flux measurements all reduce to it.

"""
    LatticeField(data; name, signed=false, info=Dict())

A real scalar field on an `NX × NY × NZ × NT` lattice. The fourth index is the
Euclidean direction; it is shown as a sequence of slices, never as real time.
`signed` marks fields with both signs (for example the topological charge
density). `info` carries metadata such as the operator definition and is
written to the movie sidecar.
"""
struct LatticeField{T<:Real,A<:AbstractArray{T,4}}
    data::A
    name::String
    signed::Bool
    info::Dict{String,Any}
end

function LatticeField(data::AbstractArray{<:Real,4}; name::AbstractString,
    signed::Bool=false, info=Dict{String,Any}())
    return LatticeField(data, String(name), signed, Dict{String,Any}(info))
end

Base.size(field::LatticeField) = size(field.data)
Base.size(field::LatticeField, d::Integer) = size(field.data, d)
Base.getindex(field::LatticeField, I...) = getindex(field.data, I...)
Base.sum(field::LatticeField) = sum(field.data)

"""
    slice(field, t)

The three-dimensional slice of `field` at Euclidean index `t` (a view).
"""
slice(field::LatticeField, t::Integer) = view(field.data, :, :, :, t)

function Base.show(io::IO, field::LatticeField)
    dims = join(size(field), "×")
    print(io, "LatticeField(\"", field.name, "\", ", dims, field.signed ? ", signed)" : ")")
end

export LatticeField, slice
