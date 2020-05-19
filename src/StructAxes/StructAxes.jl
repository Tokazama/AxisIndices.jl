module StructAxes

using NamedDims
using AxisIndices
using AxisIndices.AxisCore
using MappedArrays
using StaticArrays
using StaticRanges
using Base: OneTo, @propagate_inbounds

export StructAxis, structview, structdim

# TODO figure out how to place type inference of each field into indexing

@generated _fieldcount(::Type{T}) where {T} = fieldcount(T)

"""
    StructAxis{T}

An axis that uses a structure `T` to form its keys. the field names of
"""
struct StructAxis{T,L,V,Vs} <: AbstractAxis{Symbol,V,SVector{L,Symbol},Vs}
    values::Vs

    function StructAxis{T,L,V,Vs}(inds::Vs) where {T,L,V,Vs}
        # FIXME should unwrap_unionall be performed earlier?
        return new{Base.unwrap_unionall(T),L,V,Vs}(inds)
    end
end

StructAxis{T}() where {T} = StructAxis{T,_fieldcount(T)}()

@inline StructAxis{T,L}() where {T,L} = StructAxis{T,L}(OneToSRange{Int,L}())

function StructAxis{T,L}(inds::I) where {I<:AbstractUnitRange{<:Integer},T,L}
    if is_static(I)
        return StructAxis{T,L,eltype(I),I}(inds)
    else
        return StructAxis{T,L}(as_static(inds))
    end
end

@inline Base.keys(::StructAxis{T,L}) where {T,L} = SVector(fieldnames(T))::SVector{L,Symbol}

Base.values(axis::StructAxis) = getfield(axis, :values)

function AxisIndices.similar_type(
    ::Type{StructAxis{T,L,V,Vs}},
    new_type::Type=T,
    new_vals::Type=OneToSRange{Int,nfields(T)}
) where {T,L,V,Vs}

    return StructAxis{T,nfields(T),eltype(new_vals),new_vals}
end

# TODO what should happen with annotations here?
function AxisIndices.unsafe_reconstruct(axis::StructAxis, ks, vs)
    return similar_type(axis)(vs)
end

@inline function structdim(A)
    d = _structdim(axes_type(A))
    if d === 0
        error()
    else
        return d
    end
end
Base.@pure function _structdim(::Type{T}) where {T<:Tuple}
    for i in OneTo(length(T.parameters))
        T.parameters[i] <: StructAxis && return i
    end
    return 0
end

structaxis(x) = axes(x, structdim(x))

function to_index_type(axis::StructAxis{T}, arg) where {T}
    return fieldtype(T, to_index(axis, arg))
end

_fieldnames(::StructAxis{T}) where {T} = Tuple(T.name.names)

# get elemen type of `T` at field `i`
axis_index_eltype(::T) where {T} = axis_index_eltype(T)
axis_index_eltype(::Type{<:StructAxis{T}}) where {T} = T

axis_index_eltype(::T, i) where {T} = axis_index_eltype(T, i)
axis_index_eltype(::Type{<:StructAxis{T}}, i::Integer) where {T} = fieldtype(T, i)
axis_index_eltype(::Type{<:StructAxis{T}}, i::Colon) where {T} = T
axis_index_eltype(::Type{<:AbstractAxis}, i::Integer) = Any
@inline function axis_index_eltype(::Type{T}, inds::AbstractVector) where {T}
    return NamedTuple{
        ([fieldname(T, i) for i in inds]...),
        Tuple{[fieldtype(T, i) for i in inds]...}
    }
end

#=

function restruct(::Type{T}, inds)
    return NamedTuple{((fieldname(T, i) for i in inds)...,),
                      Tuple{(fieldname(T, i) for i in inds)...,}}
end


AxisIndices.to_keys(axis::StructAxis, )



Base.@pure _fieldnames(::Type{T}) where {T} = 


function _fieldnames(::Type{T}) where {T}
    ntuple(Val(nfields(T))) do i
        fieldname(T, i)
    end
end


Base.@pure function _eltypes(::Type{NT}) where {NT <: NamedTuple{names, T}} where {names, T <: NTuple{N, AbstractVector{S} where S}} where {N}
    return Tuple{Any[ _eltype(fieldtype(NT, i)) for i = 1:fieldcount(NT) ]...}
end


=#

# TODO Document

@inline structview(A) = _structview(A, structdim(A))
@inline _structview(A, dim) = _structview(A, dim, axes(A, dim))
@inline function _structview(A, dim, axis::StructAxis{T}) where {T}
    inds_before = ntuple(d->(:), dim-1)
    inds_after = ntuple(d->(:), ndims(A)-dim)
    return mappedarray(T, (view(A, inds_before..., i, inds_after...) for i in values(axis))...)
end

end
