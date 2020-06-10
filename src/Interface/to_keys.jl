
"""
    to_keys([::AxisIndicesStyle,] axis, arg, index)

This method is the reverse of `AxisIndices.to_index`. `arg` refers to an argument
originally passed to `AxisIndices.to_index` and `index` refers to the index produced
by that same call to `AxisIndices.to_index`.

This method assumes to all arguments have passed through `AxisIndices.to_index` and
have been checked to be in bounds. Therefore, this is unsafe and intended only for
internal use.
"""
@inline function to_keys(axis, arg, index)
    return to_keys(AxisIndicesStyle(axis, arg), axis, arg, index)
end

@inline function to_keys(axis, arg::Indices, index)
    return to_keys(AxisIndicesStyle(axis, arg), axis, arg.x, index)
end

@inline function to_keys(axis, arg::Keys, index)
    return to_keys(AxisIndicesStyle(axis, arg), axis, arg.x, index)
end

# check_index - basically checkindex but passes a style trait argument
@propagate_inbounds function check_index(axis, arg)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function check_index(axis, arg::Indices)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

@propagate_inbounds function check_index(axis, arg::Keys)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

to_keys(::KeyElement, axis, arg, index) = arg

to_keys(::IndexElement, axis, arg, index) = v2k(keys(axis), indices(axis), index)

to_keys(::KeysCollection, axis, arg, index) = arg

@inline function to_keys(::IndicesCollection, axis, arg, index)
    mapping = findin(arg, indices(axis))
    return v2k(keys(axis), indices(axis), mapping)
end


@inline function to_keys(::BoolsCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), index))
end

@inline to_keys(::IntervalCollection, axis, arg, index) = v2k(keys(axis), indices(axis), index)

to_keys(::KeysIn, axis, arg, index) = arg.x

to_keys(::IndicesIn, axis, arg, index) = v2k(keys(axis), indices(axis), index)

to_keys(::KeyEquals, axis, arg, index) = arg.x

to_keys(::IndexEquals, axis, arg, index) = v2k(keys(axis), indices(axis), index)


@inline to_keys(::KeysFix2, axis, arg, index) = v2k(keys(axis), indices(axis), index)

@inline to_keys(::IndicesFix2, axis, arg, index) = v2k(keys(axis), indices(axis), index)

@inline to_keys(::SliceCollection, axis, arg, index) = keys(axis)

to_keys(::KeyedStyle{S}, axis, arg, index) where {S} = to_keys(S, axis, arg, index)

