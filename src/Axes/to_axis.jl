
# 1 arg
to_axis(axis::AbstractAxis) = axis
function to_axis(
    ks::AbstractVector,
    check_length::Bool=true,
    staticness=Staticness(ks)
)

    return Axis(as_staticness(staticness, ks))
end
function to_axis(
    vs::StaticRanges.OneToUnion{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(vs)
)
    return SimpleAxis(as_staticness(staticness, vs))
end
#to_axis(axis::AbstractUnitRange{<:Integer}) = SimpleAxis(axis)
to_axis(len::Integer) = SimpleAxis(len)

# 2 arg
function to_axis(
    ks::Nothing,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(vs)
)

    return SimpleAxis(as_staticness(staticness, vs))
end
function to_axis(
    ks::AbstractVector,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(inds)
)

    return Axis(as_staticness(staticness, ks), as_staticness(staticness, inds), check_length)
end

function to_axis(
    ks::AbstractAxis,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(inds)
)

    return resize_last(ks, as_staticness(staticness, inds))
end

function to_axis(
    f::Function,
    inds::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(inds)
)

    return f(inds)
end

# 3 arg
@inline function to_axis(
    axis::AbstractAxis,
    ks::AbstractVector,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(vs)
)

    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, as_staticness(staticness, vs))
    else
        if (ks isa OneToUnion) && (vs isa OneToUnion)
            check_length && check_axis_length(ks, vs)
            return unsafe_reconstruct(axis, as_staticness(staticness, vs))
        else
            return Axis(as_staticness(staticness, ks), as_staticness(staticness, vs), check_length)
        end
    end
end

function to_axis(
    axis::AbstractAxis,
    ::Nothing,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=false,
    staticness=Staticness(axis)
)

    return resize_last(axis, as_staticness(staticness, vs))
end

function to_axis(
    axis::AbstractAxis,
    ks::AbstractAxis,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(vs)
)

    return to_axis(axis, keys(ks), vs, check_length, staticness)
end

