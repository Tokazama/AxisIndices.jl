
@propagate_inbounds function to_index(axis, arg)
    return to_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function to_index(::KeysIn, axis, arg)
    mapping = findin(arg.x, keys(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return _k2v(axis, mapping)
end

@propagate_inbounds function to_index(::KeyEquals, axis, arg)
    mapping = find_first(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return _k2v(axis, mapping)
end

function to_index(::IntervalCollection, axis, arg)
    mapping = findin(arg, keys(axis))
    return _k2v(axis, mapping)
end

@propagate_inbounds function to_index(::KeysCollection, axis, arg)
    mapping = findin(arg, keys(axis))
    @boundscheck if length(arg) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return _k2v(axis, mapping)
end

@propagate_inbounds function to_index(::KeyElement, axis, arg)
    mapping = find_firsteq(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return _k2v(axis, mapping)
end

@propagate_inbounds function to_index(::CartesianElement, axis, arg)
    index = first(arg.I)
    @boundscheck checkbounds(axis, index)
    return index
end

@inline to_index(::KeysFix2, axis, arg) = _k2v(axis, find_all(arg, keys(axis)))

@propagate_inbounds function to_index(::BoolsCollection, axis, arg)
    return getindex(values(axis), arg)
end

@propagate_inbounds function to_index(::BoolElement, axis, arg)
    return getindex(values(axis), arg)
end

to_index(::SliceCollection, axis, arg) = Base.Slice(values(axis))

# if we're referring to an element than we just need to know if it's inbounds
@propagate_inbounds function to_index(::IndicesCollection, axis, arg)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end

@propagate_inbounds function to_index(::IndexElement, axis, arg)
    @boundscheck if !checkbounds(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end

