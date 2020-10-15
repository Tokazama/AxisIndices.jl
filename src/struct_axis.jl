 
"""
    StructAxis{T}

An axis that uses a structure `T` to form its keys. the field names of
"""
struct StructAxis{T,L,I,Inds} <: AbstractAxis{I,Inds}
    parent::Inds

    function StructAxis{T,L,I,Inds}(inds::Inds) where {T,L,I,Inds}
        # FIXME should unwrap_unionall be performed earlier?
        return new{T,L,I,Inds}(inds)
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
end

function Base.keys(::StructAxis{T,L}) where {T,L}
    return AxisArray{Symbol,1,Vector{Symbol},Tuple{OneTo{StaticInt{L}}}}(
        Vector{Symbol}(fieldnames(T)...),
        (OneTo{StaticInt{L}}(StaticInt(L)),)
    )
end

function ArrayInterface.to_axis(::IndexAxis, axis::StructAxis, inds)
    if known_length(inds) === nothing
        # create StructAxis if we don't know length at compile time
        return Axis()
    else
        return _reconstruct_struct_axis(axis, arg, inds)
    end
end
# TODO ArrayInterface.unsafe_reconstruct(axis::StructAxis
function ArrayInterface.unsafe_reconstruct(args::StructAxis, inds) end

# TODO figure out how to place type inference of each field into indexing
@generated _fieldcount(::Type{T}) where {T} = fieldcount(T)


@inline function structdim(A::AxisArray{<:Any,<:Any,<:Any,Axs}) where {Axs}
    d = _structdim(Axs)
    if d === 0
        throw(MethodError(structdim, A))
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

