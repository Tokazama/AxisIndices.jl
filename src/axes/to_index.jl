
ArrayInterface.to_index(::IndexAxis, axis, arg::CartesianIndices{0}) = arg
ArrayInterface.to_index(::IndexAxis, axis::PaddedAxis, arg::Colon) = LazyIndex(indices(axis), axis)
ArrayInterface.to_index(::IndexAxis, axis::OffsetAxis, arg::Colon) = to_index(parent(axis), arg)
ArrayInterface.to_index(::IndexAxis, axis::CenteredAxis, arg::Colon) = to_index(parent(axis), arg)
ArrayInterface.to_index(::IndexAxis, axis, arg::Colon) = indices(axis)
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{Bool})
    @boundscheck checkbounds(axis, arg)
    return @inbounds(to_index(parent(axis), arg))
end

#= to_index(::IndexAxis, axis, ::Integer) =#
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Integer)
    return to_index(parent(axis), arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::OffsetAxis, arg::Integer)
    return to_index(parent(axis), arg - getfield(axis, :offset))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::CenteredAxis, arg::Integer)
    return to_index(parent(axis), arg - _origin_to_offset(axis))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::PaddedAxis{P}, arg::Integer) where {P}
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    p = parent(axis)
    return @inbounds(to_index(p, pad_index(pads(axis), static_first(p), static_last(p), arg)))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::PaddedAxis{P}, arg::Integer) where {P<:FillPads}
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    p = parent(axis)
    i = pad_index(pads(axis), static_first(p), static_last(p), arg)
    if i === -1
        return i
    else
        return @inbounds(to_index(p, i))
    end
end

#= to_index(::IndexAxis, axis, ::AbstractRange{<:Integer}) =#
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractRange{<:Integer})
    return to_index(parent(axis), arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::OffsetAxis, arg::AbstractRange{<:Integer})
    return to_index(parent(axis), arg - getfield(axis, :offset))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::CenteredAxis, arg::AbstractRange{<:Integer})
    o = _origin_to_offset(axis)
    return to_index(parent(axis), (static_first(arg) - o):(static_last(arg) - o))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::PaddedAxis, arg::AbstractRange{<:Integer})
    @boundscheck checkindex(Bool, axis, i) || throw(BoundsError(axis, i))
    return LazyIndex(axis, arg)
end

#= to_index(::IndexAxis, axis, ::AbstractUnitRange{<:Integer}) =#
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractUnitRange{<:Integer})
    return to_index(parent(axis), arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::OffsetAxis, arg::AbstractUnitRange{<:Integer})
    o = getfield(axis, :offset)
    return to_index(parent(axis), (static_first(arg) - o):(static_last(arg) - o))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::CenteredAxis, arg::AbstractUnitRange{<:Integer})
    o = _origin_to_offset(axis)
    return to_index(parent(axis), (static_first(arg) - o):(static_last(arg) - o))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::PaddedAxis, arg::AbstractUnitRange{<:Integer})
    @boundscheck checkindex(Bool, axis, i) || throw(BoundsError(axis, i))
    return LazyIndex(axis, arg)
end

#= to_index(::IndexAxis, axis, ::AbstractArray{<:Integer}) =#
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{<:Integer})
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    return _sub_axis_when_offset(has_offset(axis), axis, arg)
end
_sub_axis_when_offset(::True, axis, arg) = LazyIndex(axis, arg)
_sub_axis_when_offset(::False, axis, arg) = @inbounds(to_index(parent(axis), arg))


@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis::A, arg::Arg) where {A,Arg}
    return _to_index(is_key(axis, arg), axis, arg)
end

@propagate_inbounds _to_index(::StaticInt{0}, axis, arg) = to_index(parent(axis), arg)
@propagate_inbounds function _to_index(::StaticInt{N}, axis, arg) where {N}
    inds = keys_to_index(StaticInt{N}(), axis, arg)
    return @inbounds(to_index(axis, inds))
end

# FIXME there should be lazy offsets for non range vectors so we don't allocate new arrays
# so we don't initiate a broadcast if we are subtracting zero
_broadcast_offset(inds, ::Zero) = inds
_broadcast_offset(inds, ::StaticInt{O}) where {O} = inds .- O
function _broadcast_offset(inds, o::Int)
    if o === 0
        return inds
    else
        return inds .- o
    end
end

@inline function _sub_offset(axis::PaddedAxis, i::Integer)
    p = parent(axis)
    return pad_index(pads(axis), static_first(p), static_last(p), i)
end
_sub_offset(axis, x) = x
_sub_offset(axis::OffsetAxis, arg) = __sub_offset(getfield(axis, :offset), arg)
function _sub_offset(axis::CenteredAxis, arg)
    p = parent(axis)
    return __sub_offset(_origin_to_offset(first(p), length(p), origin(axis)), arg)
end
__sub_offset(f, arg::Integer) = arg - f
__sub_offset(f, arg::AbstractArray) = arg .- f
function __sub_offset(f, arg::AbstractRange)
    if known_step(arg) === 1
        return (first(arg) - f):(last(arg) - f)
    else
        return (first(arg) - f):step(arg):(last(arg) - f)
    end
end

function pad_index(p::FillPads, start, stop, i)
    if start > i
        return -1
    elseif stop < i
        return -1
    else
        return Int(i)
    end
end
function pad_index(::ReplicatePads, start, stop, i)
    if start > i
        return start
    elseif stop < i
        return stop
    else
        return Int(i)
    end
end
function pad_index(::SymmetricPads, start, stop, i)
    if start > i
        return 2start - i
    elseif stop < i
        return 2stop - i
    else
        return Int(i)
    end
end
function pad_index(::CircularPads, start, stop, i)
    if start > i
        return stop - start + i + one(start)
    elseif stop < i
        return start + i - stop - one(stop)
    else
        return Int(i)
    end
end
function pad_index(::ReflectPads, start, stop, i)
    if start > i
        return 2start - i - one(start)
    elseif stop < i
        return 2stop - i + one(stop)
    else
        return Int(i)
    end
end

