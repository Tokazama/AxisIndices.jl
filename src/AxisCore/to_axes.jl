
@inline function to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{T, Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I),
) where {A,T,I}

    S = AxisIndicesStyle(A, T)
    if is_element(S)
        return to_axes(
            maybetail(old_axes),
            maybetail(args),
            maybetail(interim_indices),
            new_indices,
            check_length,
            staticness
        )
    else
        return (
            to_axis(
                first(old_axes),
                (first(args), first(interim_indices)),
                 first(new_indices),
                 check_length,
                 staticness
            ),
            to_axes(
                maybetail(old_axes),
                maybetail(args),
                maybetail(interim_indices),
                maybetail(new_indices),
                check_length,
                staticness
            )...
        )
    end
end

@inline function to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{CartesianIndex{N},Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I)
) where {A,N,I}

    _, old_axes2 = Base.IteratorsMD.split(old_axes, Val(N))
    _, interim_indices2 = Base.IteratorsMD.split(interim_indices, Val(N))
    return to_axes(old_axes2, tail(args), interim_indices2, new_indices, check_length, staticness)
end

@inline function to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{CartesianIndices, Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I)
) where {A,I}

    return to_axes(old_axes, tail(args), tail(interim_indices), new_indices, check_length, staticness)
end

function to_axes(
    ::Tuple{A,Vararg{Any}},
    ::Tuple{CartesianIndex{N},Vararg{Any}},
    ::Tuple,
    ::Tuple{},
    check_length::Bool=false,
    staticness=StaticRanges.Fixed(),
) where {A,N}

    return ()
end

function to_axes(
    ::Tuple,
    ::Tuple{Any,Vararg{Any}},
    ::Tuple,
    ::Tuple{},
    check_length::Bool=false,
    staticness=StaticRanges.Fixed()
)

    return ()
end

function to_axes(
    ::Tuple,
    ::Tuple,
    ::Tuple,
    ::Tuple{},
    check_length::Bool=false,
    staticness=StaticRanges.Fixed()
)
    return ()
end

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

