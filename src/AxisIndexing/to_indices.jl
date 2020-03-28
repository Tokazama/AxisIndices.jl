
function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{Any, Vararg{Any}})
    Base.@_inline_meta
    return (to_index(first(inds), first(I)), to_indices(A, maybetail(inds), tail(I))...)
end

@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{Colon, Vararg{Any}})
    Base.@_inline_meta
    return (values(first(inds)), to_indices(A, maybetail(inds), tail(I))...)
end

@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    Base.@_inline_meta
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, first(I)), to_indices(A, indstail, tail(I))...)
end

# And boolean arrays behave similarly; they also skip their number of dimensions
@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{Bool, N}, Vararg{Any}}) where N
    Base.@_inline_meta
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, first(I)), to_indices(A, indstail, tail(I))...)
end

maybetail(::Tuple{}) = ()
maybetail(t::Tuple) = tail(t)
@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndices, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, inds, (first(I).indices..., tail(I)...))
end

@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndices{0},Vararg{Any}})
    Base.@_inline_meta
    return (first(I), to_indices(A, inds, tail(I))...)
end

# But some index types require more context spanning multiple indices
# CartesianIndexes are simple; they just splat out
@propagate_inbounds function Base.to_indices(A, inds::Tuple{AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndex, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, inds, (first(I).I..., tail(I)...))
end

