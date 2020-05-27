
@inline function Base.to_indices(A::AbstractAxisArray{T,N}, axs::Tuple{}, args::Tuple{CartesianIndex,Vararg{Any,M}}) where {T,N,M}
    return to_indices(A, axs, (first(args).I..., tail(args)...))
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisArray, I::Tuple{Integer})
    Base.@_inline_meta
    return (to_index(eachindex(IndexLinear(), A), first(I)),)
end

for T in (Any, Integer, CartesianIndex{1}, AbstractVector)
    @eval begin
        @propagate_inbounds function Base.to_indices(
            A::AbstractAxisArray{T,1,P,Tuple{Ax1}},
            args::Tuple{Arg1}
        ) where {T,P,Ax1,Arg1<:$T}

            Base.@_inline_meta
            return (to_index(axes(A, 1)::Ax1, first(args)::Arg1),)
        end

        # this is linear indexing over a multidimensional array so we ignore axes
        @propagate_inbounds function Base.to_indices(
            A::AbstractAxisArray{T,N,P,Tuple{Ax1,Vararg{Any}}},
            args::Tuple{Arg1}
        ) where {T,N,P,Ax1,Arg1<:$T}
            Base.@_inline_meta
            return (to_index(eachindex(IndexLinear(), A), first(I)),)
        end
    end
end

Base.to_indices(A::AbstractAxisArray{T,0}, args::Tuple{Integer}) where {T} = args

# These are extra indices that just need to be ensured are in bounds
@propagate_inbounds function Base.to_indices(
    A::AbstractAxisArray{T,N},
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
    A::AbstractAxisArray,
    args::Tuple{Vararg{Union{Integer, CartesianIndex}}}
)

    Base.@_inline_meta
    return to_indices(A, axes(A), args)
end

# avoid ambiguities with `to_indices(A, I::Tuple{})
Base.to_indices(A::AbstractAxisArray, I::Tuple{}) = ()

# TODO is there any utility in keeping axes at this point?
Base.LogicalIndex(A::AbstractAxisArray) = Base.LogicalIndex(parent(A))

