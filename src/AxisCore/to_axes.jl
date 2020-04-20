
@inline function to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{T, Vararg{Any}},
    inds::Tuple,
    new_indices::Tuple{Vararg{Any}}
) where {A<:AbstractAxis,T}

    S = AxisIndicesStyle(A, T)
    if is_element(S)
        to_axes(
            maybetail(old_axes),
            maybetail(args),
            maybetail(inds),
            new_indices,
        )
    else
        axis = first(old_axes)
        return (
            similar(
                axis,
                to_keys(S, axis, first(args), first(inds)),
                first(new_indices),
                false
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
    args::Tuple{T, Vararg{Any}},
    inds::Tuple,
    new_indices::Tuple{Vararg{Any}}
) where {A<:AbstractSimpleAxis,T}

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
            similar(first(old_axes), first(new_indices)),
            to_axes(
                maybetail(old_axes),
                maybetail(args),
                maybetail(inds),
                maybetail(new_indices)
            )...
        )
    end
end

for T in (AbstractAxis,AbstractSimpleAxis)
    @eval begin
        @inline function to_axes(
            old_axes::Tuple{A,Vararg{Any}},
            args::Tuple{CartesianIndex{N},Vararg{Any}},
            inds::Tuple,
            new_axes::Tuple{Vararg{Any}},
        ) where {A<:$T,N}

            _, old_axes2 = Base.IteratorsMD.split(old_axes, Val(N))
            _, inds2 = Base.IteratorsMD.split(inds, Val(N))
            return to_axes(old_axes2, tail(args), inds2, new_axes)
        end

        @inline function to_axes(
            old_axes::Tuple{A,Vararg{Any}},
            args::Tuple{CartesianIndices, Vararg{Any}},
            inds::Tuple,
            new_axes::Tuple{Vararg{Any}}
        ) where {A<:$T}

            return to_axes(old_axes, tail(args), tail(inds), new_axes)
        end

        function to_axes(::Tuple{A,Vararg{Any}}, ::Tuple{CartesianIndex{N},Vararg{Any}}, ::Tuple, ::Tuple{}) where {A<:$T,N}
            return ()
        end

        function to_axes(::Tuple{A,Vararg{Any}}, ::Tuple{Any,Vararg{Any}}, ::Tuple, ::Tuple{}) where {A<:$T}
            return ()
        end
    end
end

to_axes(::Tuple{}, ::Tuple, ::Tuple, ::Tuple{}) = ()
