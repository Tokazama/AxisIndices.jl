

# N-Dimension -> M-Dimension
function to_axes(
    A::AbstractArray{T,N},
    args::NTuple{M,Any},
    interim_indices::Tuple,
    new_indices::Tuple,
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I),
) where {T,N,M}
    return _to_axes(axes(A), args, interim_indices, new_indices, check_length, staticness)
end

# 1-Dimension -> 1-Dimension
function to_axes(
    A::AbstractArray{T,1},
    args::NTuple{1,Any},
    interim_indices::Tuple,
    new_indices::Tuple,
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I),
) where {T}
    return _to_axes(axes(A), args, interim_indices, new_indices, check_length, staticness)
end

# N-dimensions -> 1-dimension
@inline function to_axes(
    A::AbstractArray{T,N},
    args::NTuple{1,Any},
    interim_indices::Tuple,
    new_indices::Tuple,
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I),
) where {T,N}
    axis = axes(A, 1)
    index = first(new_indices)
    if is_indices_axis(axis)
        return (assign_indices(axis, index),)
    else
        return (to_axis(axis, resize_last(keys(axis), length(index)), index, false, staticness),)
    end
end


@inline function _to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{T, Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool,
    staticness,
) where {A,T,I}

    S = AxisIndicesStyle(A, T)
    if is_element(S)
        return _to_axes(
            maybe_tail(old_axes),
            maybe_tail(args),
            maybe_tail(interim_indices),
            new_indices,
            check_length,
            staticness
        )
    else
        axis = first(old_axes)
        index = first(new_indices)
        if is_indices_axis(axis)
            new_axis = to_axis(axis, nothing, index, check_length, staticness)
        else
            new_axis = to_axis(axis, to_keys(axis, first(args), first(interim_indices)), index, check_length, staticness)
        end
        return (new_axis,
            _to_axes(
                maybe_tail(old_axes),
                maybe_tail(args),
                maybe_tail(interim_indices),
                maybe_tail(new_indices),
                check_length,
                staticness
            )...,
        )
    end
end

@inline function _to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{CartesianIndex{N},Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool,
    staticness
) where {A,N,I}

    _, old_axes2 = Base.IteratorsMD.split(old_axes, Val(N))
    _, interim_indices2 = Base.IteratorsMD.split(interim_indices, Val(N))
    return _to_axes(old_axes2, tail(args), interim_indices2, new_indices, check_length, staticness)
end

@inline function _to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{CartesianIndices, Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool,
    staticness
) where {A,I}

    return _to_axes(old_axes, tail(args), tail(interim_indices), new_indices, check_length, staticness)
end

_to_axes(::Tuple, ::Tuple{CartesianIndex{N},Vararg{Any}}, ::Tuple, ::Tuple{}, ::Bool, ::Any) where {N} = ()
_to_axes(::Tuple, ::Tuple{Any,Vararg{Any}},               ::Tuple, ::Tuple{}, ::Bool, ::Any) = ()
_to_axes(::Tuple, ::Tuple,                                ::Tuple, ::Tuple{}, ::Bool, ::Any) = ()

@inline function to_axes(
    old_axes::Tuple,
    new_keys::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}
    return (
        to_axis(first(old_axes), first(new_keys), first(new_indices), check_length, staticness),
        to_axes(tail(old_axes), tail(new_keys), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    old_axes::Tuple,
    ::Tuple{},
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(first(old_axes), nothing, first(new_indices), check_length, staticness),
        to_axes(tail(old_axes), (), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    ::Tuple{},
    new_keys::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(first(new_keys), first(new_indices), check_length, staticness),
        to_axes((), tail(new_keys), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    ::Tuple{},
    ::Tuple{},
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(nothing, first(new_indices), check_length, staticness),
        to_axes((), (), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    ::Tuple{},
    ks::Tuple{I,Vararg{Any}},
    new_indices::Tuple{},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(first(ks), check_length, staticness),
        to_axes((), tail(ks), (), check_length, staticness)...
    )
end

to_axes(::Tuple{}, ::Tuple{}, ::Tuple{}, check_length::Bool=true, staticness=StaticRanges.Fixed()) = ()
to_axes(::Tuple, ::Tuple{}, ::Tuple{}, check_length::Bool=true, staticness=StaticRanges.Fixed()) = ()

