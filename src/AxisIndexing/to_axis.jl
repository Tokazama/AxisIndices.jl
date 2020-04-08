
to_axis(axis::AbstractAxis) = axis

@inline function to_axis(axis)
    if is_static(axis)
        return SimpleAxis(as_static(axis))
    elseif is_fixed(axis)
        return SimpleAxis(as_fixed(axis))
    else
        return SimpleAxis(as_dynamic(axis))
    end
end

@inline function to_axis(ks::Ks, vs::Vs, check_length::Bool=true) where {Ks,Vs}
    if is_static(Vs)
        return Axis(as_static(ks, Val((length(Vs),))), as_static(vs), check_length)
    elseif is_fixed(Vs)
        return Axis(as_fixed(ks), as_fixed(vs), check_length)
    else
        return Axis(as_dynamic(ks), as_dynamic(vs), check_length)
    end
end

@inline function to_axis(axis::AbstractAxis, ks::Ks, vs::Vs, check_length::Bool=true) where {Ks,Vs}
    check_length && check_axis_length(ks, vs)

    if is_static(Vs)
        return unsafe_reconstruct(axis, as_static(ks, Val((length(Vs),))), as_static(vs))
    elseif is_fixed(Vs)
        return unsafe_reconstruct(axis, as_fixed(ks), as_fixed(vs))
    else
        return unsafe_reconstruct(axis, as_dynamic(ks), as_dynamic(vs))
    end
end

### TODO CLEANUP THIS!
function to_axis(old_axis::AbstractSimpleAxis, arg, index, new_indices)
    return unsafe_reconstruct(old_axis, new_indices)
end

function to_axis(old_axis::AbstractAxis, arg, index, new_indices)
    return to_axis(old_axis, to_key(old_axis, arg, index), new_indices)
end

@inline function to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{T, Vararg{Any}},
    inds::Tuple,
    new_indices
) where {A,T}

    S = AxisIndicesStyle(A, T)
    if is_element(S)
        to_axes(
            maybetail(old_axes),
            maybetail(args),
            maybetail(inds),
            new_indices,
        )
    else
        return (
            to_axis(maybe_first(old_axes),
                    maybe_first(args),
                    maybe_first(inds),
                    maybe_first(new_indices)
            ),
            to_axes(
                maybetail(old_axes),
                maybetail(args),
                maybetail(inds),
                maybetail(new_indices)
            )...
        )
    end
end

@inline function to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{CartesianIndex{N},Vararg{Any}},
    inds::Tuple,
    new_axes,
) where {A,N}

    _, old_axes2 = Base.IteratorsMD.split(old_axes, Val(N))
    _, inds2 = Base.IteratorsMD.split(inds, Val(N))
    return to_axes(old_axes2, tail(args), inds2, new_axes)
end

@inline function to_axes(
    old_axes,
    args::Tuple{CartesianIndices, Vararg{Any}},
    inds::Tuple,
    new_axes
) where {N}

    return to_axes(old_axes, tail(args), tail(inds), new_axes)
end

@inline function to_axis(ks::Ks, vs::AbstractAxis, check_length::Bool=true) where {Ks,Vs}
    return to_axis(ks, values(vs), check_length)
end

#=
@inline function to_axis(ks::AbstractAxis, vs::Vs, check_length::Bool=true) where {Vs}
    return to_axis(keys(ks), vs, check_length)
end

@inline function to_axis(ks::AbstractAxis, vs::AbstractAxis, check_length::Bool=true)
    return to_axis(keys(ks), values(vs), check_length)
end

# this one is necessary to avoid ambiguitities
@inline function to_axis(ks::AbstractSimpleAxis, vs::Vs, check_length::Bool=true) where {Vs}
    return to_axis(keys(ks), vs, check_length)
end

@inline function to_axis(axis::AbstractAxis, ks::AbstractAxis, vs::Vs, check_length::Bool=true) where {Vs}
    return to_axis(axis, keys(ks), vs, check_length)
end

@inline function to_axis(axis::AbstractAxis, ks::Ks, vs::AbstractAxis, check_length::Bool=true) where {Ks}
    return to_axis(axis, ks, values(vs), check_length)
end

function to_axis(axis::AbstractSimpleAxis, ks::Ks, vs::Vs, check_length::Bool=true) where {Ks,Vs}
    check_length && check_axis_length(ks, vs)
    return unsafe_reconstruct(axis, vs)
end
=#

to_axes(::Tuple{}, ::Tuple{Int64}, ::Tuple{}, ::Tuple{}) = ()
to_axes(::Tuple, ::Tuple{}, ::Tuple{}, ::Tuple) = ()

