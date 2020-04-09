
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

