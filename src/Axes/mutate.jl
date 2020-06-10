
Base.empty!(axis::AbstractAxis) = set_length!(axis, 0)

function StaticRanges.pop(axis::AbstractAxis)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, pop(indices(axis)))
    else
        return unsafe_reconstruct(axis, pop(keys(axis)), pop(indices(axis)))
    end
end

function Base.pop!(axis::AbstractAxis)
    StaticRanges.can_set_last(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    if !is_indices_axis(axis)
        pop!(keys(axis))
    end
    return pop!(indices(axis))
end

function Base.pop!(axis::AbstractOffsetAxis)
    StaticRanges.can_set_last(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    out = pop!(indices(axis))
    _reset_keys!(axis, length(indices(axis)))
    return out
end

function StaticRanges.set_last!(axis::AbstractOffsetAxis{K,I}, val::I) where {K,I}
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(indices(axis), val)
    _reset_keys!(axis, length(indices(axis)))
    return axis
end

function StaticRanges.popfirst(axis::AbstractAxis)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, popfirst(indices(axis)))
    else
        return unsafe_reconstruct(axis, popfirst(keys(axis)), popfirst(indices(axis)))
    end
end

function Base.popfirst!(axis::AbstractAxis)
    StaticRanges.can_set_first(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    if !is_indices_axis(axis)
        popfirst!(keys(axis))
    end
    return popfirst!(indices(axis))
end

function Base.popfirst!(axis::AbstractOffsetAxis)
    StaticRanges.can_set_first(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    out = popfirst!(indices(axis))
    _reset_keys!(axis, length(indices(axis)))
    return out
end


# TODO check for existing key first
function push_key!(axis::AbstractAxis, key)
    if !is_indices_axis(axis)
        push!(keys(axis), key)
    end
    grow_last!(indices(axis), 1)
    return nothing
end

function pushfirst_key!(axis::AbstractAxis, key)
    if !is_indices_axis(axis)
        pushfirst!(keys(axis), key)
    end
    grow_last!(indices(axis), 1)
    return nothing
end

function StaticRanges.grow_last!(axis::AbstractOffsetAxis, n::Integer)
    can_set_length(axis) ||  throw(MethodError(grow_last!, (axis, n)))
    len = length(axis) + n
    StaticRanges.grow_last!(indices(axis), n)
    _reset_keys!(axis, len)
    return nothing
end

function StaticRanges.shrink_last!(axis::AbstractOffsetAxis, n::Integer)
    can_set_length(axis) ||  throw(MethodError(shrink_last!, (axis, n)))
    len = length(axis) - n
    StaticRanges.shrink_last!(indices(axis), n)
    _reset_keys!(axis, len)
    return nothing
end

function StaticRanges.set_length!(axis::AbstractOffsetAxis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(indices(axis), len)
    _reset_keys!(axis, len)
    return axis
end


# TODO check for existing key first
push_key!(axis::AbstractOffsetAxis, key) = grow_last!(axis, 1)

pushfirst_key!(axis::AbstractOffsetAxis, key) = grow_last!(axis, 1)
