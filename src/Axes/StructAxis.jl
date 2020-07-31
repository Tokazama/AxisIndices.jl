
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
        return new{T,L,V,Vs}(inds)
    end
end

StructAxis{T}() where {T} = StructAxis{T,_fieldcount(T)}()

StructAxis{T}(vs::AbstractUnitRange) where {T} = StructAxis{T,_fieldcount(T)}(vs)

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

axis_eltype(::StructAxis{T}, i) where {T} = fieldtype(T, i)

function StaticRanges.similar_type(
    ::Type{StructAxis{T,L,V,Vs}},
    new_type::Type=T,
    new_vals::Type=OneToSRange{Int,nfields(T)}
) where {T,L,V,Vs}

    return StructAxis{T,nfields(T),eltype(new_vals),new_vals}
end

# `ks` should always be a `<:AbstractVector{Symbol}`
@inline function Interface.unsafe_reconstruct(axis::StructAxis, ks, vs)
    return StructAxis{NamedTuple{Tuple(ks),axis_eltypes(axis, ks)}}(vs)
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

#structaxis(x) = axes(x, structdim(x))

function to_index_type(axis::StructAxis{T}, arg) where {T}
    return fieldtype(T, to_index(axis, arg))
end

_fieldnames(::StructAxis{T}) where {T} = Tuple(T.name.names)

function to_axis(
    ks::StructAxis{T},
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
) where {T}

    check_length && check_axis_length(ks, vs)
    return StructAxis{T}(vs)
end

# TODO This documentation is confusing...but I'm tired right now.
"""
    struct_view(A)

Creates a `MappedArray` using the `StructAxis` of `A` to identify the dimension
that needs to be collapsed into a series of `SubArray`s as views that composed
the `MappedArray`
"""
@inline struct_view(A) = _struct_view(A, structdim(A))
@inline _struct_view(A, dim) = _struct_view(A, dim, axes(A, dim))
@inline function _struct_view(A, dim, axis::StructAxis{T}) where {T}
    inds_before = ntuple(d->(:), dim-1)
    inds_after = ntuple(d->(:), ndims(A)-dim)
    return mappedarray(T, (view(A, inds_before..., i, inds_after...) for i in values(axis))...)
end

@inline function _struct_view(A, dim, axis::StructAxis{T}) where {T<:NamedTuple}
    inds_before = ntuple(d->(:), dim-1)
    inds_after = ntuple(d->(:), ndims(A)-dim)
    return mappedarray((args...) ->T(args) , (view(A, inds_before..., i, inds_after...) for i in values(axis))...)
end


# This can't be changed for a type
StaticRanges.as_static(axis::StructAxis) = axis
StaticRanges.as_fixed(axis::StructAxis) = axis
StaticRanges.as_dynamic(axis::StructAxis) = axis
