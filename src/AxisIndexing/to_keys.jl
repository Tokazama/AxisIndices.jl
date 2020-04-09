
"""
    to_keys([::AxisIndicesStyle,] axis, arg, index)

This method is the reverse of `AxisIndices.to_index`. `arg` refers to an argument
originally passed to `AxisIndices.to_index` and `index` refers to the index produced
by that same call to `AxisIndices.to_index`.

This method assumes to all arguments have passed through `AxisIndices.to_index` and
have been checked to be in bounds. Therefore, this is unsafe and intended only for
internal use.
"""
@inline to_keys(axis, arg, index) = to_keys(AxisIndicesStyle(axis, arg), axis, arg, index)

@inline function to_keys(::IndicesCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), _v2k(axis, index)))
end

@inline function to_keys(::KeysFix2, axis, arg, index)
    return @inbounds(getindex(keys(axis), _v2k(axis, index)))
end

@inline function to_keys(::IntervalCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), _v2k(axis, index)))
end

@inline function to_keys(::BoolsCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), index))
end

@inline to_keys(::KeysIn, axis, arg, index) = arg.x

@inline to_keys(::KeysCollection, axis, arg, index) = arg

@inline to_keys(::SliceCollection, axis, arg, index) = keys(axis)

