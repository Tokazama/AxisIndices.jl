# FIXME to_index(::OffsetAxis, :) returns the indices instead of a Slice
# FIXME to_index(::IndicesCollection, axis, ::AbstractAxis) causes problems (i.e., axis[axis] -> errors)

"""
    to_index(axis, arg) -> to_index(AxisIndicesStyle(axis, arg), axis, arg)

Unique implementation of `to_index` for the `AxisIndices` package that specializes
based on each axis and indexing argument (as opposed to the array and indexing argument).
"""
@propagate_inbounds function to_index(axis, arg)
    return to_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function to_index(axis, arg::Indices)
    return to_index(Styles.force_indices(AxisIndicesStyle(axis, arg)), axis, arg.x)
end

@propagate_inbounds function to_index(axis, arg::Keys)
    return to_index(Styles.force_keys(AxisIndicesStyle(axis, arg)), axis, arg.x)
end

@propagate_inbounds function to_index(::KeyElement, axis, arg)
    mapping = find_firsteq(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

@propagate_inbounds function to_index(::IndexElement, axis, arg)
    @boundscheck if !in(arg, indices(axis))
        throw(BoundsError(axis, arg))
    end
    return arg
end

@propagate_inbounds to_index(::BoolElement, axis, arg) = getindex(values(axis), arg)

@propagate_inbounds function to_index(::CartesianElement, axis, arg)
    index = first(arg.I)
    @boundscheck if !checkindex(Bool, values(axis), index)
        throw(BoundsError(axis, arg))
    end
    return index
end

@propagate_inbounds function to_index(::KeysCollection, axis, arg)
    mapping = findin(arg, keys(axis))
    @boundscheck if length(arg) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

# TODO boundschecking should be replace by the yet undeveloped `allin` method in StaticRanges
# if we're referring to an element than we just need to know if it's inbounds
@propagate_inbounds function to_index(::IndicesCollection, axis, arg)
    @boundscheck if length(findin(arg, indices(axis))) != length(arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end

@propagate_inbounds function to_index(::BoolsCollection, axis, arg)
    return getindex(values(axis), arg)
end

function to_index(::IntervalCollection, axis, arg)
    return k2v(keys(axis), indices(axis), findin(arg, keys(axis)))
end

@propagate_inbounds function to_index(::KeysIn, axis, arg)
    mapping = findin(arg.x, keys(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

@propagate_inbounds function to_index(::IndicesIn, axis, arg)
    mapping = findin(arg.x, indices(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return mapping
end

@propagate_inbounds function to_index(::KeyEquals, axis, arg)
    mapping = find_first(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

@propagate_inbounds function to_index(::IndexEquals, axis, arg)
    @boundscheck if !checkbounds(Bool, indices(axis), arg.x)
        throw(BoundsError(axis, arg.x))
    end
    return arg.x
end

@inline to_index(::KeysFix2, axis, arg) = k2v(keys(axis), indices(axis), find_all(arg, keys(axis)))

@inline to_index(::IndicesFix2, axis, arg) = find_all(arg, values(axis))

to_index(::SliceCollection, axis, arg) = Base.Slice(indices(axis))

to_index(::KeyedStyle{S}, axis, arg) where {S} = to_index(S, axis, arg)

