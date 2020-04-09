
@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{Integer})
    Base.@_inline_meta
    return (AxisIndexing.to_index(eachindex(IndexLinear(), A), first(I)),)
end

for T in (Any, Integer, CartesianIndex{1}, AbstractVector)
    @eval begin
        @propagate_inbounds function Base.to_indices(
            A::AbstractAxisIndices{T,1,P,Tuple{Ax1}},
            args::Tuple{Arg1}
        ) where {T,P,Ax1,Arg1<:$T}

            Base.@_inline_meta
            return (AxisIndexing.to_index(axes(A, 1)::Ax1, first(args)::Arg1),)
        end

        # this is linear indexing over a multidimensional array so we ignore axes
        @propagate_inbounds function Base.to_indices(
            A::AbstractAxisIndices{T,N,P,Tuple{Ax1,Vararg{Any}}},
            args::Tuple{Arg1}
        ) where {T,N,P,Ax1,Arg1<:$T}
            Base.@_inline_meta
            return (AxisIndexing.to_index(eachindex(IndexLinear(), A), first(I)),)
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

Base.to_indices(::AbstractAxisIndices, ::Tuple{}, ::Tuple{}) = ()

Base.IndexStyle(::Type{<:AbstractAxisIndices{T,N,A,AI}}) where {T,N,A,AI} = IndexStyle(A)

for (unsafe_f, f) in ((:unsafe_getindex, :getindex), (:unsafe_view, :view), (:unsafe_dotview, :dotview))
    @eval begin
        @propagate_inbounds function Base.$f(A::AbstractAxisIndices, args...)
            return AxisIndexing.$unsafe_f(A, args, to_indices(A, args))
        end
    end
end

