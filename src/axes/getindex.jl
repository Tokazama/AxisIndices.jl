
Base.getindex(axis::AbstractAxis, ::Colon) = copy(axis)
Base.getindex(axis::AbstractAxis, ::Ellipsis) = copy(axis)
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::Integer)
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    return Int(arg)
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{<:Integer})
    return _axis_to_axis(axis, arg)
end
@propagate_inbounds function _axis_to_axis(axis::PaddedAxis, arg::A) where {A}
    pds = pads(axis)
    p = parent(axis)
    start_index = static_first(inds)
    stop_index = static_last(inds)
    start_parent = static_first(p)
    stop_parent = static_last(p)

    nbefore = start_parent - start_index
    if nbefore > 0
        fpad = nbefore
        start = conform_dynamic(start_parent, start_index)
    else
        fpad = zero(nbefore)
        start = conform_dynamic(start_index, start_parent)
    end

    nafter = stop_index - stop_parent
    if nafter > 0
        lpad = nafter
        stop = conform_dynamic(stop_parent, stop_index)
    else
        lpad = zero(nafter)
        stop = conform_dynamic(stop_index, stop_parent)
    end
    @boundscheck if (lpad > last_pad(pds)) || (fpad > first_pad(pds))
        throw(BoundsError(axis, arg))
    end
    return initialize(
        reparam(pds)(_Pad(int(fpad), int(lpad))),
        @inbounds(_axis_to_axis(p, start:stop))
    )
end
@propagate_inbounds function _axis_to_axis(axis::StructAxis{T}, inds::UnitSRange{F,L}) where {T,F,L}
    new_axis = _axis_to_axis(parent(axis), inds)
    if known_length(axis) === ((L - F) + 1)
        return _StructAxis(T, new_axis)
    else
        return _StructAxis(NamedTuple{__names(T, inds), __types(T, inds)}, new_axis)
    end
end

@propagate_inbounds function _axis_to_axis(axis::KeyedAxis, arg::A) where {A}
    p = parent(axis)
    @boundscheck checkindex(Bool, p, arg)
    return _Axis(@inbounds(keys(axis)[arg]), @inbounds(_axis_to_axis(p, arg)))
end

# have parents offset axes check bounds
@propagate_inbounds function _axis_to_axis(axis::AbstractAxis, arg::A) where {A}
    return initialize(param(axis), _axis_to_axis(parent(axis), _sub_offset(axis, arg)))
end

@propagate_inbounds function _axis_to_axis(axis::SimpleAxis, arg::A) where {A}
    @boundscheck if (first(axis) > first(arg)) || (last(axis) < last(arg))
        throw(BoundsError(axis, arg))
    end
    return SimpleAxis(static_first(arg):static_last(arg))
end

###
### axis -> array
###
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{<:Integer})
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractArray{<:Integer})
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    idx = keys_to_index(is_key(axis, arg), axis, arg)
    return @inbounds(axis[idx])
end

# if we do have an offset then it is propagated in the keys
@inline function _axis_to_array(axis, inds)
    new_axis, array = _axis_to_array(parent(axis), inds)
    return initialize(drop_offset(param(axis)), new_axis), array
end
@inline function _axis_to_array(axis::SimpleAxis, inds)
    return SimpleAxis(static(1):static_length(inds)), @inbounds(parent(axis)[inds])
end
@inline function _axis_to_array(axis::KeyedAxis, inds)
    new_axis, array = _axis_to_array(parent(axis), inds)
    k = @inbounds(drop_offset(getfield(axis, :keys))[inds])
    return initialize(_AxisKeys(k), new_axis), array
end
@inline function _axis_to_array(axis::StructAxis{T}, inds::UnitSRange{F,L}) where {T,F,L}
    new_axis, array = _axis_to_array(parent(axis), inds)
    return _StructAxis(NamedTuple{__names(T, inds), __types(T, inds)}, new_axis), array
end
@inline function _axis_to_array(axis::StructAxis{T}, inds::StepSRange{F,S,L}) where {T,F,S,L}
    new_axis, array = _axis_to_array(parent(axis), inds)
    return _StructAxis(NamedTuple{__names(T, inds), __types(T, inds)}, new_axis), array
end
@inline function _axis_to_array(axis::StructAxis{T}, inds) where {T}
    new_axis, array = _axis_to_array(parent(axis), inds)
    return _Axis([fieldname(T, i) for i in inds], new_axis), array
end

