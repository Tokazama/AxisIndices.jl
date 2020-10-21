
###
### to_index
###
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractRange{I}) where {I<:Integer}
    return to_index(eachindex(axis), arg)
end
@propagate_inbounds ArrayInterface.to_index(::IndexAxis, axis, arg) = _to_index(axis, arg)
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Integer)
    @boundscheck checkbounds(axis, arg)
    return Int(arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{Bool})
    return to_index(eachindex(axis), arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{I}) where {I<:Integer}
    return to_index(eachindex(axis), arg)
end
ArrayInterface.to_index(::IndexAxis, axis, ::Colon) = indices(axis)
@propagate_inbounds function ArrayInterface.to_index(
    ::IndexAxis,
    axis,
    arg::AbstractUnitRange{I}
) where I<:Integer

    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return AbstractUnitRange{Int}(arg)
end
@propagate_inbounds function _to_index(axis, arg::CartesianIndex)
    @boundscheck checkbounds(axis, arg)
    return arg
end

@propagate_inbounds function _to_index(axis, arg::Interval)
    idx = find_all(in(arg), keys(axis))
    return @inbounds(indices(axis)[idx])
end

# if it's not an `Axis` then there aren't non-integer keys
@propagate_inbounds _to_index(axis, arg) = _to_index_any(axis, arg)
@propagate_inbounds function _to_index_any(axis, arg)
    if parent_type(axis) <: typeof(axis)
        throw(ArgumentError("invalid index: IndexStyle $S does not support indices of type $(typeof(arg))."))
    else
        return _to_index_any(parent(axis), arg)
    end
end
@propagate_inbounds function _to_index_any(axis::Axis, arg)
    ks = keys(axis)
    if arg isa keytype(axis)
        idx = find_first(==(arg), ks)
    else
        idx = find_first(==(keytype(axis)(arg)), ks)
    end
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, (arg,)))
    end
    # if firstindex of kas is not the same as first of parent(axis)
    p = parent(axis)
    kindex = firstindex(ks)
    pindex = first(p)
    return Int(@inbounds(p[idx + (pindex - kindex)]))
end

@propagate_inbounds function _to_index(axis, arg::Function)
    return @inbounds(eachindex(axis)[find_all(arg, keys(axis))])
end

@propagate_inbounds function _to_index(axis, arg::Union{<:Equal,Approx})
    idx = findfirst(arg, keys(axis))
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(@inbounds(eachindex(axis)[idx]))
end

@propagate_inbounds function _to_index(axis, arg::AbstractArray)
    return map(arg_i -> to_index(axis, arg_i), arg)
end

# FIXME technically `in` isn't correct here because in doesn't guarantee the
# order is preserved
@propagate_inbounds _to_index(axis, arg::AbstractRange) = _to_index_range(axis, arg)
@propagate_inbounds _to_index_range(axis, arg) = to_index(parent(axis), arg)
function _to_index_range(axis::Axis, arg)
    inds = find_all_in(arg, keys(axis))
    # if `inds` is same length as `arg` then all of `arg` was found and is inbounds
    @boundscheck if length(inds) != length(arg)
        throw(BoundsError(axis, arg))
    end
    return @inbounds(eachindex(axis)[idx])
end


###
### getindex
###
Base.getindex(axis::AbstractAxis, ::Colon) = copy(axis)
Base.getindex(axis::AbstractAxis, ::Ellipsis) = copy(axis)
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::Integer)
    @boundscheck checkbounds(axis, arg)
    return eltype(axis)(arg)
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractArray{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end

ArrayInterface.unsafe_get_element(axis::AbstractAxis, inds) = eltype(axis)(first(inds))

@inline function ArrayInterface.unsafe_get_collection(axis::AbstractAxis, inds::Tuple)
    return _unsafe_get_axis_collection(axis, first(inds))
end
_unsafe_get_axis_collection(axis, i::Integer) = Int(i)
@inline function _unsafe_get_axis_collection(axis, inds)
    if known_step(inds) === one(eltype(inds))
        return index_axis_to_axis(axis, inds)
    else
        return __unsafe_get_axis_collection(index_axis_to_array(axis, inds), inds)
    end
end
@inline function __unsafe_get_axis_collection(axis, inds::AbstractRange)
    T = eltype(axis)
    if eltype(inds) <: T
        return AxisArray{T,1,typeof(inds),Tuple{typeof(axis)}}(inds, (axis,); checks=NoChecks)
    else
        return __unsafe_get_axis_collection(axis, AbstractRange{T}(inds))
    end
end
@inline function __unsafe_get_axis_collection(axis, inds)
    T = eltype(axis)
    if eltype(inds) <: T
        return AxisArray{T,1,typeof(inds),Tuple{typeof(axis)}}(inds, (axis,); checks=NoChecks)
    else
        return __unsafe_get_axis_collection(axis, AbstractArray{T}(inds))
    end
end

#= 
    index_axis_to_array(axis, inds)

An axis may have other axis types nested within it so we need to propagate the indexing,
but we can usually just use unsafe_reconstruct.
=#
@inline function index_axis_to_axis(axis::SimpleAxis, inds)
    return SimpleAxis(static_first(inds):static_last(inds))
end
@inline function index_axis_to_axis(axis, inds)
    return unsafe_reconstruct(axis, index_axis_to_axis(parent(axis), _sub_offset(axis, inds)))
end
@inline function index_axis_to_axis(axis::IdentityAxis, inds)
    return IdentityAxis(inds, index_axis_to_axis(parent(axis),  _sub_offset(axis, inds)))
end

# TODO this might be worth making part of official API if a better name and more thought out
# documentation/implementation accompanies it b/c eventually all axis types have to deal
# with non unit range indexing.
#= 
    index_axis_to_array(axis, inds)

An axis cannot be preserved if the elements with any collection that doesn't have a step of 1.
=#
index_axis_to_array(axis::SimpleAxis, inds) = SimpleAxis(eachindex(inds))
function index_axis_to_array(axis::Axis, inds)
    if allunique(inds)  # propagate keys corresponds to inds
        return Axis(@inbounds(keys(axis)[inds]), index_axis_to_array(parent(axis), inds); checks=NoChecks)
    else  # b/c not all indices are unique it will result in non-unique keys so drop keys
        return index_axis_to_array(parent(axis), inds)
    end
end
function index_axis_to_array(axis, inds)
    return unsafe_reconstruct(axis, index_axis_to_array(parent(axis), _sub_offset(axis, inds)))
end

###
### checkindex
###
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg) = _check_index_any(axis, arg)
_check_index_any(axis, arg) = checkindex(Bool, parent(axis), arg)
_check_index_any(axis::Axis, arg) = in(arg, keys(axis))

Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Interval) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Colon) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Slice) = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractArray{T}) where {T}
    return _check_index_array(axis, arg)
end
_check_index_array(axis, arg) = checkindex(Bool, parent(axis), arg)
function _check_index_array(axis::Axis, arg::AbstractArray{T}) where {T}
    if T <: Integer
        return checkindex(Bool, parent(axis), arg)
    else
        return all(in(keys(axis)), arg)
    end
end

Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::AbstractArray{Bool}) = false
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractVector{Bool})
    return checkindex(Bool, parent(axis), arg)
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Real) = _check_index_real(axis, arg)
_check_index_real(axis, arg) = checkindex(Bool, parent(axis), arg)
function _check_index_real(axis::AbstractOffsetAxis, arg)
    return checkindex(Bool, parent(axis), _sub_offset(axis, arg))
end
function _check_index_real(axis::Axis, arg)
    if arg isa Integer
        return checkindex(Bool, parent(axis), arg)
    else
        return _check_index_any(axis, arg)
    end
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Union{<:Equal,<:Approx})
    return !(find_first(arg, keys(axis)) === nothing)
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractRange{T}) where {T}
    return _check_index_range(axis, arg)
end
_check_index_range(axis, arg) = checkindex(Bool, parent(axis), arg)
function _check_index_range(axis::AbstractOffsetAxis, arg)
    return checkindex(Bool, parent(axis), _sub_offset(axis, arg))
end
function _check_index_range(axis::Axis, arg::AbstractRange{T}) where {T}
    if T <: Integer
        return checkindex(Bool, parent(axis), arg)
    else
        return length(find_all_in(arg, keys(axis))) == length(axis)
    end
end

Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Fix2) = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::LogicalIndex)
    return (axis,) == axes(arg.mask)
end
