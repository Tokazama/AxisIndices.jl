
@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{Any, Vararg{Any}})
    Base.@_inline_meta
    return (to_index(first(axs), first(args)), to_indices(A, maybetail(axs), tail(args))...)
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{Colon, Vararg{Any}})
    Base.@_inline_meta
    return (values(first(axs)), to_indices(A, maybetail(axs), tail(args))...)
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    Base.@_inline_meta
    _, axstail = Base.IteratorsMD.split(axs, Val(N))
    return (to_index(A, first(args)), to_indices(A, axstail, tail(args))...)
end

# And boolean arrays behave similarly; they also skip their number of dimensions
@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{AbstractArray{Bool, N}, Vararg{Any}}) where N
    Base.@_inline_meta
    _, axes_tail = Base.IteratorsMD.split(axs, Val(N))
    return (to_index(first(axs), first(args)), to_indices(A, axes_tail, tail(args))...)
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{CartesianIndices, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, axs, (first(args).indices..., tail(args)...))
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{CartesianIndices{0},Vararg{Any}})
    Base.@_inline_meta
    return (first(args), to_indices(A, axs, tail(args))...)
end

# But some index types require more context spanning multiple indices
# CartesianIndexes are simple; they just splat out
@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{CartesianIndex, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, axs, (first(args).I..., tail(args)...))
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{Integer})
    Base.@_inline_meta
    return (Indexing.to_index(eachindex(IndexLinear(), A), first(I)),)
end

for T in (Any, Integer, CartesianIndex{1}, AbstractVector)
    @eval begin
        @propagate_inbounds function Base.to_indices(
            A::AbstractAxisIndices{T,1,P,Tuple{Ax1}},
            args::Tuple{Arg1}
        ) where {T,P,Ax1,Arg1<:$T}

            Base.@_inline_meta
            return (Indexing.to_index(axes(A, 1)::Ax1, first(args)::Arg1),)
        end

        # this is linear indexing over a multidimensional array so we ignore axes
        @propagate_inbounds function Base.to_indices(
            A::AbstractAxisIndices{T,N,P,Tuple{Ax1,Vararg{Any}}},
            args::Tuple{Arg1}
        ) where {T,N,P,Ax1,Arg1<:$T}
            Base.@_inline_meta
            return (Indexing.to_index(eachindex(IndexLinear(), A), first(I)),)
        end
    end
end

# These are extra indices that just need to be ensured are in bounds
@propagate_inbounds function Base.to_indices(
    A::AbstractAxisIndices{T,N},
    axs::Tuple{},
    args::Tuple{Any,Vararg{Any,M}}
) where {T,N,M}

    Base.@_inline_meta
    @boundscheck for dim in (N+1):(N+M+1)
        axis = axes(A, dim)
        arg = getfield(args, dim - N)
        if !checkindex(Bool, axis, arg)
            throw(BoundsError(axis, arg))
        end
    end
    return ()
end

@propagate_inbounds function Base.to_indices(
    A::AbstractAxisIndices,
    args::Tuple{Vararg{Union{Integer, CartesianIndex}}}
)

    Base.@_inline_meta
    to_indices(A, axes(A), args)
end

