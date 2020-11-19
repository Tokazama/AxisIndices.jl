
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractRange{I}) where {I<:Integer}
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Integer)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{Bool})
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return eachindex(axis)[arg]
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{I}) where {I<:Integer}
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end
ArrayInterface.to_index(::IndexAxis, axis, ::Colon) = indices(axis)

#= TODO delete these
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractUnitRange{I}) where I<:Integer
    return to_index(parent(axis), arg)
end
@propagate_inbounds function _to_index(axis, arg::CartesianIndex)
    @boundscheck checkbounds(axis, arg)
    return arg
end
=#
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Union{<:Equal,Approx})
    idx = findfirst(arg, keys(axis))
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(@inbounds(eachindex(axis)[idx]))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg)
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

@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Interval)
    idx = find_all(in(arg), keys(axis))
    return @inbounds(indices(axis)[idx])  # FIXME
end

# if it's not an `Axis` then there aren't non-integer keys
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Function)
    return @inbounds(eachindex(axis)[find_all(arg, keys(axis))])
end

@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray)
    return map(arg_i -> to_index(axis, arg_i), arg)
end

function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractRange)
    if typeof(arg) <: keytype(axis)
        inds = find_all_in(arg, keys(axis))
        # if `inds` is same length as `arg` then all of `arg` was found and is inbounds
        @boundscheck if length(inds) != length(arg)
            throw(BoundsError(axis, arg))
        end
        return @inbounds(eachindex(axis)[idx])
    else
        # FIXME SubAxis will have problems with this if the parent axis keys selected extend
        # beyond the 
        return to_index(parent(axis), arg)
    end
end
