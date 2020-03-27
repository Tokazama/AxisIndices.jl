# Notes:
# `@propagate_inbounds` is widely used because indexing with filtering syntax
# means we don't know that it's inbounds until we've passed the function through
# `to_index`.

# this is necessary for when we get to the head to_index(::ToIndexStyle, ::AbstractAxis, inds)
# `inds` needs to be a function but we don't know if it's a single element (==) or a collection (in)
# Of course, if the user provides a function as input to the indexing in the first place this
# isn't an issue at all.
is_collection(::Type{T}) where {T} = false
is_collection(::Type{T}) where {T<:F2Eq} = false
is_collection(::Type{T}) where {T<:Function} = true
is_collection(::Type{T}) where {T<:AbstractArray} = true
is_collection(::Type{T}) where {T<:Tuple} = true
is_collection(::Type{T}) where {T<:Interval} = true
is_collection(::Type{T}) where {T<:AbstractDict} = true

# TODO Not the greatest name
"""
    is_key_type(::T) -> Bool

Returns `true` if `T` is always considered a key for indexing. Only `CartesianIndex`
and subtypes of `Real` return `false`.
"""
is_key_type(::Type{T}) where {T} = true
is_key_type(::Type{<:CartesianIndex}) = false
is_key_type(::Type{<:Integer}) = false

"""
    CombineStyle

Abstract type that determines the behavior of `broadcast_axis`, `cat_axis`, `append_axis!`.
"""
abstract type CombineStyle end

"""
    CombineAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractAxis`.
"""
struct CombineAxis <: CombineStyle end

"""
    CombineSimpleAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractSimpleAxis`.
"""
struct CombineSimpleAxis <: CombineStyle end

"""
    CombineResize

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
resizing a collection (as opposed to by concatenation or appending).
"""
struct CombineResize <: CombineStyle end

"""
    CombineStack

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
stacking elements in some whay (as opposed to resizing a collection).
"""
struct CombineStack <: CombineStyle end

CombineStyle(x, y) = CombineStyle(CombineStyle(x), CombineStyle(y))
CombineStyle(::T) where {T} = CombineStyle(T)
CombineStyle(::Type{T}) where {T} = CombineStack() # default
CombineStyle(::Type{T}) where {T<:AbstractAxis} = CombineAxis()
CombineStyle(::Type{T}) where {T<:AbstractSimpleAxis} = CombineSimpleAxis()
CombineStyle(::Type{T}) where {T<:AbstractRange} = CombineResize()
CombineStyle(::Type{T}) where {T<:LinearIndices{1}} = CombineResize()  # b/c it really is OneTo{Int}

CombineStyle(::CombineAxis, ::CombineStyle) = CombineAxis()
CombineStyle(::CombineStyle, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineSimpleAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineSimpleAxis) = CombineAxis()

CombineStyle(::CombineSimpleAxis, ::CombineStyle) = CombineSimpleAxis()
CombineStyle(::CombineStyle, ::CombineSimpleAxis) = CombineSimpleAxis()
CombineStyle(::CombineSimpleAxis, ::CombineSimpleAxis) = CombineSimpleAxis()

CombineStyle(x::CombineStyle, y::CombineStyle) = x


abstract type ToIndexStyle end

"""
    ToKeysCollection()

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
function ToIndexStyle(::Type{T}) where {T}
    if is_collection(T)
        return ToIndexStyle(eltype(T))
    else
        return SearchKeys()
    end
end
ToIndexStyle(::Type{T}) where {T<:Integer} = SearchIndices()
ToIndexStyle(::Type{T}) where {T<:Bool} = GetIndices()

# FIXME This bit has all sorts of stuff that scares me
# 1. This isn't in Compat.jl yet so I can't just depend on it.
# 2. Compat dependencies often give me errors when updating packages
# 3. An anonymous function has a name based on its place in code, therefore we
#    have to derive the name programmatically because it can change between
#    versions of Julia
if length(methods(isapprox, Tuple{Any})) == 0
    Base.isapprox(y; kwargs...) = x -> isapprox(x, y; kwargs...)
end
const IsApproxFix = typeof(isapprox(Any)).name.wrapper

is_collection(::Type{T}) where {T<:IsApproxFix} = false

maybe_wrap_in(x::Function) = x
maybe_wrap_in(x) = in(x)

maybe_wrap_eq(x::Function) = x
maybe_wrap_eq(x) = isequal(x)

@propagate_inbounds function Base.to_index(axis::AbstractAxis, inds::CartesianIndex{1})
    return to_index(axis, first(inds.I))
end

Base.to_index(axis::AbstractAxis, inds::Base.Slice) = values(axis)

@propagate_inbounds function Base.to_index(axis::AbstractAxis, inds)
    return to_index(ToIndexStyle(eltype(inds)), axis, inds)
end

_get_length(x::Fix2{typeof(in)}) = length(x.x)
_get_length(x::Function) = nothing
_get_length(x::Interval) = nothing
_get_length(x) = length(x)

@propagate_inbounds function Base.to_index(::SearchKeys, axis::AbstractUnitRange{T}, inds::I) where {T,I}
    if is_collection(I)
        newinds = find_all(maybe_wrap_in(inds), keys(axis))
        l = _get_length(inds)
        @boundscheck if !(eltype(newinds) <: Integer) || !isnothing(l) && l != length(newinds)
            throw(BoundsError(axis, inds))
        end
    else
        newinds = find_first(maybe_wrap_eq(inds), keys(axis))
        @boundscheck if newinds isa Nothing
            throw(BoundsError(axis, inds))
        end
    end
    return maybe_unsafe_reconstruct(axis, newinds)
end

@propagate_inbounds function Base.to_index(::SearchIndices, axis::AbstractUnitRange{T}, inds::I) where {T,I}
    if is_collection(I)
        newinds = find_all(maybe_wrap_in(inds), values(axis))
        l = _get_length(inds)
        @boundscheck if !isnothing(l) && l != length(newinds)
            throw(BoundsError(axis, inds))
        end
    else
        newinds = find_first(maybe_wrap_eq(inds), values(axis))
        @boundscheck if newinds isa Nothing
            throw(BoundsError(axis, inds))
        end
    end
    return maybe_unsafe_reconstruct(axis, newinds)
end

@propagate_inbounds function Base.to_index(::GetIndices, axis::AbstractUnitRange{T}, inds::I) where {T,I}
    @boundscheck checkbounds(values(axis), inds)
    return maybe_unsafe_reconstruct(axis, inds)
end
