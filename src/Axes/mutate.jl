
function Base.empty!(axis::AbstractAxis)
    if is_indices_axis(axis)
        empty!(indices(axis))
    else
        empty!(keys(axis))
        empty!(indices(axis))
    end
    return axis
end

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

# TODO check for existing key first
function push_key!(axis::AbstractAxis, key)
    push!(keys(axis), key)
    grow_last!(indices(axis), 1)
end

function pushfirst_key!(axis::AbstractAxis, key)
    pushfirst!(keys(axis), key)
    grow_last!(indices(axis), 1)
end

