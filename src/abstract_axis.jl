
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,I<:Integer} <: AbstractUnitRange{I} end

for f in (:(==), :isequal)
    @eval begin
        Base.$(f)(x::AbstractAxis, y::AbstractAxis) = $f(eachindex(x), eachindex(y))
        Base.$(f)(x::AbstractArray, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::AbstractArray) = $f(eachindex(x), y)
        Base.$(f)(x::AbstractRange, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::AbstractRange) = $f(eachindex(x), y)
        Base.$(f)(x::StaticRanges.GapRange, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::StaticRanges.GapRange) = $f(eachindex(x), y)
        Base.$(f)(x::OrdinalRange, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::OrdinalRange) = $f(eachindex(x), y)
    end
end

Base.valtype(::Type{T}) where {K,I,T<:AbstractAxis{K,I}} = I

Base.keytype(::Type{T}) where {K,I,T<:AbstractAxis{K,I}} = K

Base.eachindex(axis::AbstractAxis) = parentindices(axis)

Base.allunique(a::AbstractAxis) = true

Base.empty!(axis::AbstractAxis) = set_length!(axis, 0)

@inline Base.in(x::Integer, axis::AbstractAxis) = !(x < first(axis) || x > last(axis))
@inline Base.length(axis::AbstractAxis) = length(parentindices(axis))

Base.pairs(axis::AbstractAxis) = Base.Iterators.Pairs(a, keys(axis))

# This is required for performing `similar` on arrays
Base.to_shape(axis::AbstractAxis) = length(axis)

Base.haskey(axis::AbstractAxis, key) = key in keys(axis)

@inline function Base.compute_offset1(parent, stride1::Integer, dims::Tuple{Int}, inds::Tuple{<:AbstractAxis}, I::Tuple)
    return Base.compute_linindex(parent, I) - stride1 * first(axes(parent, first(dims)))
end

@inline Base.axes(axis::AbstractAxis) = (Base.axes1(axis),)

@inline Base.axes1(axis::AbstractAxis) = copy(axis)

@inline Base.unsafe_indices(axis::AbstractAxis) = (axis,)

Base.isempty(axis::AbstractAxis) = isempty(parentindices(axis))

Base.sum(axis::AbstractAxis) = sum(eachindex(axis))

function ArrayInterface.can_change_size(::Type{T}) where {T<:AbstractAxis}
    return can_change_size(parent_type(T))
end

Base.collect(a::AbstractAxis) = collect(eachindex(a))

Base.step(axis::AbstractAxis) = oneunit(eltype(axis))

Base.step_hp(axis::AbstractAxis) = 1

Base.size(axis::AbstractAxis) = (length(axis),)


###
### getindex
###

@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::Integer)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return eltype(axis)(arg)
end
Base.getindex(axis::AbstractAxis, ::Colon) = eachindex(axis)  # TODO is this what should be returned?
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{I}) where {I<:Integer}
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end

    return _maybe_reconstruct_axis(axis, to_index(axis, arg))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{I}) where {I<:Integer}
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return _maybe_reconstruct_axis(axis, to_index(axis, arg))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StaticRanges.GapRange)
    return _maybe_reconstruct_axis(axis, vcat(axis[arg.first_range], axis[arg.last_range]))
end
Base.getindex(axis::AbstractAxis, ::Ellipsis) = indices(axis)
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    return _maybe_reconstruct_axis(axis, to_index(axis, arg))
end

#= TODO delete this
function unsafe_getindex(axis::AbstractUnitRange, arg, inds)
    return unsafe_getindex(IndexStyle(axis), axis, arg, inds)
end
unsafe_getindex(::IndexStyle, axis, arg, idx::Integer) = idx
function unsafe_getindex(::IndexStyle, axis, arg, idx::AbstractVector)
    return AbstractVector{eltype(axis)}(idx)
end
@inline function unsafe_getindex(S::IndexStyle, axis, arg, idx::AbstractUnitRange)
    return unsafe_reconstruct(S, axis, arg, idx)
end
=#

###
### checkindex
###
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Colon} = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Slice} = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:AbstractArray}
    if is_key(axis, arg)
        return length(find_all_in(drop_marker(arg), keys(axis))) == length(drop_marker(arg))
    else
        return checkindex(Bool, eachindex(axis), drop_marker(arg))
    end
end
Base.checkindex(::Type{Bool}, ::AbstractAxis, ::IndexingMarker{T}) where {N,T<:AbstractArray{Bool,N}} = N === 1
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Union{<:Equal,<:Approx}}
    if is_key(axis, arg)
        return !(find_first(drop_marker(arg), keys(axis)) === nothing)
    else
        return !(find_first(drop_marker(arg), eachindex(axis)) === nothing)
    end
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:AbstractRange}
    if is_key(axis, arg)
        return length(find_all_in(drop_marker(arg), keys(axis))) == length(axis)
    else
        return checkindex(Bool, eachindex(axis), drop_marker(arg))
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Fix2} = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T}
    if is_key(axis, arg)
        return drop_marker(arg) in keys(axis)
    else
        return drop_marker(arg) in eachindex(axis)
    end
end

function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg)
    if is_key(axis, arg)
        return arg in keys(axis)
    else
        return arg in eachindex(axis)
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Interval) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Colon) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Slice) = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractArray) 
    if is_key(axis, arg)
        return length(find_all_in(arg, keys(axis))) == length(arg)
    else
        return checkindex(Bool, eachindex(axis), arg)
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::AbstractArray{Bool}) = false
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractVector{Bool})
    return checkindex(Bool, eachindex(axis), arg)
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Real)
    if is_key(axis, arg)
        return in(arg, keys(axis))
    else
        return in(arg, eachindex(axis))
    end
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Union{<:Equal,<:Approx})
    return !(find_first(arg, keys(axis)) === nothing)
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractRange{T}) where {T}
    if is_key(axis, arg)
        return length(find_all_in(arg, keys(axis))) == length(axis)
    else
        return checkindex(Bool, eachindex(axis), arg)
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Fix2) = true
@inline function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::LogicalIndex)
    return (axis,) == axes(arg.mask)
end

_maybe_reconstruct_axis(axis, inds::Integer) = inds
_maybe_reconstruct_axis(axis, inds::AbstractUnitRange) = unsafe_reconstruct(axis, inds)
function _maybe_reconstruct_axis(axis, inds::AbstractArray)
    axs = (unsafe_reconstruct(axis, eachindex(inds)),)
    return AxisArray{eltype(axis),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
end

Base.:-(axis::AbstractAxis) = _maybe_reconstruct_axis(axis, -eachindex(axis))

function Base.:+(r::AbstractAxis, s::AbstractAxis)
    indsr = axes(r, 1)
    indsr == axes(s, 1) || throw(DimensionMismatch("axes $indsr and $(axes(s, 1)) do not match"))
    return _maybe_reconstruct_axis(indsr, eachindex(r) + eachindex(s))
end
function Base.:-(r::AbstractAxis, s::AbstractAxis)
    indsr = axes(r, 1)
    indsr == axes(s, 1) || throw(DimensionMismatch("axes $indsr and $(axes(s, 1)) do not match"))
    return _maybe_reconstruct_axis(indsr, eachindex(r) - eachindex(s))
end

ArrayInterface.offsets(axis::AbstractAxis, i) = offsets(axis)[i]

