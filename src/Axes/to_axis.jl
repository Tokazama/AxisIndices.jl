
# 1 arg
to_axis(axis::AbstractAxis) = axis
to_axis(ks::AbstractVector, check_length::Bool=true) = Axis(ks)
function to_axis(inds::Union{<:SOneTo,OneToUnion{<:Integer}}, check_length::Bool=true)
    if is_static(inds)
        return SimpleAxis(as_static(inds))
    else
        return SimpleAxis(inds)
    end
end
#to_axis(axis::AbstractUnitRange{<:Integer}) = SimpleAxis(axis)
to_axis(len::Integer) = SimpleAxis(len)

# 2 arg
function to_axis(
    ::Nothing,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true
)

    if is_static(inds)
        return SimpleAxis(as_static(inds))
    else
        return SimpleAxis(inds)
    end

end
SOneTo
function to_axis(
    ks::AbstractVector,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true
)
    if (ks isa Union{SOneTo,OneToUnion}) && (inds isa Union{SOneTo,OneToUnion})
        check_length && check_axis_length(ks, inds)
        if is_static(ks)
            return SimpleAxis(as_static(ks))
        elseif is_fixed(ks)
            if is_static(inds)
                return SimpleAxis(as_static(inds))
            else
                return SimpleAxis(ks)
            end
        else  # is_dynamic(ks)
            # if underlying array type is not dynamic can't change that
            # with dynamic keys
            if is_static(inds)
                return SimpleAxis(as_static(inds))
            elseif is_fixed(inds)
                return SimpleAxis(inds)
            else  # is_dynamic(inds)
                return SimpleAxis(ks)
            end
        end
    else
        if is_static(ks)
            return Axis(as_static(ks), as_static(inds, Val(length(ks))), check_length)
        elseif is_fixed(ks)
            if is_static(inds)
                return Axis(as_static(ks, Val(length(inds))), as_static(inds), check_length)
            else
                return Axis(ks, as_fixed(inds), check_length)
            end
        else
            if is_static(inds)
                return Axis(as_static(ks, Val(length(inds))), inds, check_length)
            elseif is_fixed(inds)
                return Axis(as_fixed(ks), inds, check_length)
            else  # is_dynamic(inds)
                return Axis(ks, inds, check_length)
            end
        end
    end
end

function to_axis(
    axis::AbstractAxis,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
)

    return resize_last(axis, inds)
end

function to_axis(
    f::Function,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
)

    return f(inds)
end


# 3 arg
function to_axis(
    axis::AbstractAxis,
    ::Nothing,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=false,
)

    return resize_last(axis, inds)
end

function to_axis(
    axis::AbstractAxis,
    ks::AbstractAxis,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
)

    return to_axis(axis, keys(ks), vs, check_length)
end

@inline function to_axis(
    axis::AbstractAxis,
    ks::AbstractVector,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
)

    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, inds)
    elseif (ks isa Union{SOneTo,OneToUnion}) && (inds isa Union{SOneTo,OneToUnion})
        check_length && check_axis_length(ks, inds)
        if is_static(ks)
            return unsafe_reconstruct(axis, as_static(ks))
        elseif is_fixed(ks)
            return unsafe_reconstruct(axis, ks)
        elseif is_dynamic(inds)
            # this far means `is_dynamic(ks)` but this isn't possible if the
            # underlying structure is not dynamic so it's not possible for the
            # keys to be dynamic unless also `is_dynamic(inds)`...
            return unsafe_reconstruct(axis, ks)
        else
            # ...so if `!is_dynamic(inds)` then we just use whatever inds is
            return unsafe_reconstruct(axis, inds)
        end
    else
        if is_static(ks)
            return unsafe_reconstruct(axis, as_static(ks), as_static(inds))
        elseif is_fixed(ks)
            return unsafe_reconstruct(axis, ks, as_fixed(inds))
        else  # is_dynamic(ks)
            if is_dynamic(inds)
                return unsafe_reconstruct(axis, ks, inds)
            else
                return unsafe_reconstruct(axis, as_fixed(ks), inds)
            end
        end
    end
end

