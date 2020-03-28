
# Notes:
# `@propagate_inbounds` is widely used because indexing with filtering syntax
# means we don't know that it's inbounds until we've passed the function through
# `to_index`.

# this is necessary for when we get to the head to_index(::ToIndexStyle, ::AbstractAxis, inds)
# `inds` needs to be a function but we don't know if it's a single element (==) or a collection (in)
# Of course, if the user provides a function as input to the indexing in the first place this
# isn't an issue at all.

abstract type ToIndexStyle end

"""
    SearchKeys()

Calling `to_index(::SearchKeys, axis, inds) -> newinds` results in:
1. Identifying the positions of `keys(axis)` that equal `inds`
2. Retreiving the `values(axis)` that correspond to the identified positions.
3. Attempt to reconstruct the axis type (e.g., `Axis` or `SimpleAxis`) with the relevant keys and values. This is only possible if `newinds isa AbstractUnitRange{Integer}` is `true`
"""
struct SearchKeys <: ToIndexStyle end

"""
    SearchIndices()

Calling `to_index(::SearchIndices, axis, inds) -> newinds` results in:
1. Identifying the positions of `values(axis)` that equal `inds`
2. Attempt to reconstruct the axis type (e.g., `Axis` or `SimpleAxis`) with the relevant keys and values. This is only possible if `newinds isa AbstractUnitRange{Integer}` is `true`
"""
struct SearchIndices <: ToIndexStyle end

"""
    GetIndices()

Calling `to_index(::GetIndices, axis, inds) -> newinds` results in:
1. Performs `getindex(values(axis), inds)`
2. If the initual output is a subtype of `AbstractUnitRange{Integer}` then an axis type is returned. Otherwise just the initial output is returned.
"""
struct GetIndices <: ToIndexStyle end

"""
    ToIndexStyle

`ToIndexStyle` specifies how `to_index(axis, inds)` should convert a provided
argument indices into the native indexing of structure. `ToIndexStyle(eltype(inds))`
determines whether [`SearchKeys`](@ref), [`SearchIndices`](@ref), or
[`GetIndices`](@ref) is returned.
"""
ToIndexStyle(::T) where {T} = ToIndexStyle(T)
ToIndexStyle(::Type{T}) where {T} = _to_index_style(IndexerStyle(T), T)
_to_index_style(::ToCollection, ::Type{T}) where {T} = ToIndexStyle(eltype(T))
_to_index_style(::ToElement, ::Type{T}) where {T} = SearchKeys()
_to_index_style(::ToElement, ::Type{T}) where {T<:Integer} = SearchIndices()
_to_index_style(::ToElement, ::Type{T}) where {T<:CartesianIndex} = SearchIndices()
_to_index_style(::ToElement, ::Type{T}) where {T<:Bool} = GetIndices()

###
### to_index
###
@propagate_inbounds function Base.to_index(axis::AbstractAxis, inds)
    return to_index(ToIndexStyle(inds), axis, inds)
end
Base.to_index(axis::AbstractAxis, inds::Base.Slice) = values(axis)
@propagate_inbounds function Base.to_index(style::SearchKeys, axis, inds)
    return to_axis_index(IndexerStyle(inds), axis, keys(axis), inds)
end
@propagate_inbounds function Base.to_index(style::SearchIndices, axis, inds)
    return to_axis_index(IndexerStyle(inds), axis, values(axis), inds)
end
@propagate_inbounds function Base.to_index(style::GetIndices, axis, inds)
    @boundscheck checkbounds(values(axis), inds)
    return maybe_unsafe_reconstruct(axis, inds)
end

_in(inds) = in(inds)
_in(inds::Function) = inds
_length_eq(inds::Fix2{typeof(in)}, newinds) = length(inds.x) == length(newinds)
_length_eq(inds::Function, newinds) = true
_length_eq(inds::Interval, newinds) = true
_length_eq(inds, newinds) = length(inds) == length(newinds)

@propagate_inbounds function to_axis_index(style::ToCollection, axis, collection, inds)
    newinds = find_all(_in(inds), collection)
    @boundscheck if !(eltype(newinds) <: Integer) | !_length_eq(inds, newinds)
        throw(BoundsError(axis, inds))
    end
    return maybe_unsafe_reconstruct(axis, newinds)
end

_eq(inds) = isequal(inds)
_eq(inds::CartesianIndex{1}) = isequal(first(inds.I))
_eq(inds::Function) = inds
@propagate_inbounds function to_axis_index(style::ToElement, axis, collection, inds)
    newinds = find_first(_eq(inds), collection)
    @boundscheck if newinds isa Nothing
        throw(BoundsError(axis, inds))
    end
    return maybe_unsafe_reconstruct(axis, newinds)
end

