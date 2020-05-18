
as_staticness(::StaticRanges.Static, x) = as_static(x)
as_staticness(::StaticRanges.Fixed, x) = as_fixed(x)
as_staticness(::StaticRanges.Dynamic, x) = as_dynamic(x)

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
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(vs)
)
    return Axis(as_staticness(staticness, ks), as_staticness(staticness, vs), check_length)
end

function to_axis(
    ks::AbstractAxis,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=Staticness(vs)
)
    return resize_last(ks, as_staticness(staticness, vs))
end

# 3 arg
@inline function to_axis(
    axis::AbstractAxis,
    ks::AbstractVector,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(vs)
)

    if is_simple_axis(axis)
        if (ks isa OneToUnion) && (vs isa OneToUnion)
            check_length && check_axis_length(ks, vs)
            return unsafe_reconstruct(axis, as_staticness(staticness, vs))
        else
            return Axis(as_staticness(staticness, ks), as_staticness(staticness, vs), check_length)
        end
    else
        return similar(axis, as_staticness(staticness, ks), as_staticness(staticness, vs), check_length)
    end
end

function to_axis(
    axis::AbstractAxis,
    ::Nothing,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(vs)
)

    return resize_last(axis, vs)
end

function to_axis(
    axis::AbstractAxis,
    ks::AbstractAxis,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(vs)
)

    return to_axis(axis, keys(ks), vs, check_length, staticness)
end

#=
@inline function to_axis(
    axis::AbstractAxis,
    arg,
    ind,
    vs::AbstractUnitRange{<:Integer},
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(vs)
)

    if is_simple_axis(axis)
        return to_axis(axis, nothing, vs, check_length, staticness)
    else
        return to_axis(axis, to_keys(axis, arg, ind), vs, check_length, staticness)
    end
end
=#

#=
# Do an additional pass to ensure that the user really wants to abandon the old_axis type,
# b/c we can't have keys diffent from indices with an AbstractSimpleAxis
function _to_axis(axis::AbstractAxis, ks::OneToUnion, vs::OneToUnion, check_length::Bool)
    check_length && check_axis_length(ks, vs)
    return unsafe_reconstruct(axis, ks)
end
#...but we can only do that in a type stable way with OneTo
_to_axis(axis::AbstractAxis, ks, vs, check_length::Bool) = Axis(ks, vs, check_length)

@inline _to_axes(S::Staticness, ks::Tuple{<:AbstractVector,Vararg{Any}}, vs::Tuple, check_length::Bool) =
    (to_axis(S, first(ks), first(vs)), _to_axes(S, maybe_tail(ks), maybe_tail(vs), check_length)...)
@inline _to_axes(S::Staticness, ks::Tuple{<:Integer,Vararg{Any}}, vs::Tuple, check_length::Bool) =
    (to_axis(S, first(vs)), _to_axes(S, maybe_tail(ks), maybe_tail(vs), check_length)...)
@inline _to_axes(S::Staticness, ks::Tuple{}, vs::Tuple, check_length::Bool) =
    (to_axis(S, first(vs)), _to_axes(S, (), maybe_tail(vs), check_length)...)
_to_axes(S::Staticness, ks::Tuple{}, vs::Tuple{}, check_length::Bool) = ()


=#

