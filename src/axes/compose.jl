
@inline function compose_axes(::Tuple{}, x::AbstractArray{<:Any,N}) where {N}
    if N === 0
        return ()
    elseif N === 1 && can_change_size(x)
        return (compose_axis(DynamicAxis(length(x))),)
    else
        return map(compose_axis, axes(x))
    end
end
function compose_axes(ks::Tuple{Vararg{<:Any,N}}, x::AbstractArray{<:Any,N}) where {N}
    if N === 0
        return ()
    elseif N === 1 && can_change_size(x)
        return compose_axes(ks, (DynamicAxis(length(x)),))
    else
        return compose_axes(ks, axes(x))
    end
end
function compose_axes(ks::Tuple, x::AbstractArray{<:Any,N}) where {N}
    throw(DimensionMismatch("Number of axis arguments provided ($(length(ks))) does " *
                            "not match number of parent axes ($N)."))
end
@inline function compose_axes(ks::Tuple{Vararg{<:Any,N}}, inds::Tuple{Vararg{<:Any,N}}) where {N}
    return (
        compose_axis(first(ks), first(inds)),
        compose_axes(tail(ks), tail(inds))...
    )
end
compose_axes(::Tuple{}, ::Tuple{}) = ()
compose_axes(::Tuple{}, inds::Tuple) = map(compose_axis, inds)
compose_axes(axs::Tuple, ::Tuple{}) = map(compose_axis, axs)

###
### compose_axis
###
compose_axis(x::Integer) = SimpleAxis(x)
compose_axis(x) = Axis(x)
compose_axis(x::AbstractAxis) = x
function compose_axis(x::AbstractUnitRange{I}) where {I<:Integer}
    if known_first(x) === one(eltype(x))
        return SimpleAxis(x)
    else
        return OffsetAxis(x)
    end
end
compose_axis(x::IdentityUnitRange) = compose_axis(x.indices)

# 3-args
compose_axis(::Nothing, inds) = compose_axis(inds)
compose_axis(ks::Function, inds) = ks(inds)
function compose_axis(ks::Integer, inds)
    if ks isa StaticInt
        return SimpleAxis(known_first(inds):ks)
    else
        return SimpleAxis(inds)
    end
end
function compose_axis(ks, inds)
    check_axis_length(ks, inds)
    return _compose_axis(ks, inds)
end
function _compose_axis(ks::AbstractAxis, inds)
    # if the indices are the same then don't reconstruct
    if first(parent(ks)) == first(inds)
        return copy(ks)
    else
        return unsafe_reconstruct(ks, inds)
    end
end
@inline function _compose_axis(ks, inds)
    start = known_first(ks)
    if known_step(ks) === 1
        if known_first(ks) === nothing
            return OffsetAxis(first(ks) - static_first(inds), inds)
        elseif known_first(ks) === known_first(inds)
            # if we don't know the length of `inds` but we know the length of `ks` then we
            # should reconstruct `inds` so that it has a static length
            if known_last(inds) === nothing && known_last(ks) !== nothing
                return set_length(inds, static_length(ks))
            else
                return copy(inds)
            end
        else
            return OffsetAxis(static_first(ks) - static_first(inds), inds)
        end
    else
        check_unique_keys(ks)
        return _Axis(ks, compose_axis(inds))
    end
end

