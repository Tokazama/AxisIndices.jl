
#= to_index

1. Is `inds` a collection or single element. If it is a collection we do find_all, otherwise find_first
2. Does `inds` refer to keys or indices?
3. Does `inds` have the appropriate functional filter
=#
"""
    ToIndexStyle

`ToIndexStyle` specifies how `to_index` should convert provided indices into the
native indexing of structure.
"""
abstract type ToIndexStyle end

struct ToKeysCollection <: ToIndexStyle end

struct ToKeysElement <: ToIndexStyle end

struct ToIndicesCollection <: ToIndexStyle end

struct ToIndicesElement <: ToIndexStyle end

const ToCollection = Union{ToKeysCollection,ToIndicesCollection}
const ToElement = Union{ToKeysElement,ToIndicesElement}

const ToKeys = Union{ToKeysCollection,ToKeysElement}
const ToIndices = Union{ToIndicesCollection,ToIndicesElement}


@inline function ToIndexStyle(::Type{A}, ::Type{I}) where {A,I}
    if is_collection(I)
        if is_key_type(I)
            return ToKeysCollection()
        else
            return ToIndicesCollection()
        end
    else
        if is_key_type(I)
            return ToKeysElement()
        else
            return ToIndicesElement()
        end
    end
end


# ensure that everything goes through an initial search step
check_for_function(::ToCollection, x::Function) = x
check_for_function(::ToCollection, x) = in(x)

check_for_function(::ToElement, x::Function) = x
check_for_function(::ToElement, x) = isequal(x)

# retrieve values or keys
keys_or_values(::ToKeys) = keys
keys_or_values(::ToIndices) = values

# choose find_all or find_first filter function
choose_filter(::ToCollection) = find_all
choose_filter(::ToElement) = find_first

@propagate_inbounds function Base.to_index(axis::AbstractAxis, inds::CartesianIndex{1})
    return to_index(axis, first(inds.I))
end

Base.to_index(axis::AbstractAxis, inds::Base.Slice) = values(axis)

@propagate_inbounds function Base.to_index(axis::AbstractAxis, inds)
    return to_index(ToIndexStyle(typeof(axis),typeof(inds)), axis, inds)
end

_get_length(x::Fix2{typeof(in)}) = length(x.x)
_get_length(x::Function) = nothing
_get_length(x) = length(x)

@propagate_inbounds function Base.to_index(s::ToCollection, axis::AbstractUnitRange{T}, inds) where {T}
    newinds = find_all(check_for_function(s, inds), keys_or_values(s)(axis))

    l = _get_length(inds)
    @boundscheck if !isnothing(l) && l != length(newinds)
        throw(BoundsError(axis, inds))
    end
    _getindex(axis, newinds)
end

@propagate_inbounds function Base.to_index(s::ToElement, axis::AbstractUnitRange{T}, i)::T where {T}
    newi = find_first(check_for_function(s, i), keys_or_values(s)(axis))

    @boundscheck if newi isa Nothing
        throw(BoundsError(axis, i))
    end
    _getindex(axis, newi)
end

#=
@propagate_inbounds function Base.to_index(s::ToCollection, axis::AbstractUnitRange{T}, inds) where {T}
    newinds = find_all(check_for_function(s, inds), keys_or_values(s)(axis))

    l = _get_length(inds)
    @boundscheck if !isnothing(l) && l != length(newinds)
        throw(BoundsError(axis, inds))
    end
    @inbounds getindex(values(axis), newinds)
end

@propagate_inbounds function Base.to_index(s::ToElement, axis::AbstractUnitRange{T}, i)::T where {T}
    newi = find_first(check_for_function(s, i), keys_or_values(s)(axis))

    @boundscheck if newi isa Nothing
        throw(BoundsError(axis, i))
    end
    @inbounds(getindex(values(axis), newi))
end
=#

###
### to_indices
###
@propagate_inbounds function Base.to_indices(A::AbstractAxisIndicesVector, I::Tuple{Any})
    Base.@_inline_meta
    return (to_index(axes(A, 1), first(I)),)
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndicesVector, I::Tuple{Integer})
    Base.@_inline_meta
    return (to_index(axes(A, 1), first(I)),)
end

# this is linear indexing over a multidimensional array so we ignore axes
@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{Any})
    Base.@_inline_meta
    return (to_index(eachindex(IndexLinear(), A), first(I)),)
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{CartesianIndex})
    Base.@_inline_meta
    return to_indices(A, first(I).I)
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{Integer})
    Base.@_inline_meta
    return (to_index(eachindex(IndexLinear(), A), first(I)),)
end

function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{Any, Vararg{Any}})
    Base.@_inline_meta
    return (to_index(first(inds), first(I)), to_indices(A, maybetail(inds), tail(I))...)
end

@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{Colon, Vararg{Any}})
    Base.@_inline_meta
    return (values(first(inds)), to_indices(A, maybetail(inds), tail(I))...)
end

@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    Base.@_inline_meta
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, first(I)), to_indices(A, indstail, tail(I))...)
end

# And boolean arrays behave similarly; they also skip their number of dimensions
@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{Bool, N}, Vararg{Any}}) where N
    Base.@_inline_meta
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, first(I)), to_indices(A, indstail, tail(I))...)
end

maybetail(::Tuple{}) = ()
maybetail(t::Tuple) = tail(t)
@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndices, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, inds, (first(I).indices..., tail(I)...))
end

@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndices{0},Vararg{Any}})
    Base.@_inline_meta
    return (first(I), to_indices(A, inds, tail(I))...)
end

# But some index types require more context spanning multiple indices
# CartesianIndexes are simple; they just splat out
@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndex, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, inds, (first(I).I..., tail(I)...))
end

