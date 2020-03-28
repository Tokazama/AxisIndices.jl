
@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{Integer})
    Base.@_inline_meta
    return (to_index(eachindex(IndexLinear(), A), first(I)),)
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndicesVector, I::Tuple{Any})
    Base.@_inline_meta
    return (to_index(axes(A, 1), first(I)),)
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndicesVector, I::Tuple{Integer})
    Base.@_inline_meta
    return (to_index(axes(A, 1), first(I)),)
end

# this is linear indexing over a multidimensional array so we ignore axes
@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{Any})
    Base.@_inline_meta
    return (to_index(eachindex(IndexLinear(), A), first(I)),)
end

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{CartesianIndex})
    Base.@_inline_meta
    return to_indices(A, first(I).I)
end

Base.IndexStyle(::Type{<:AbstractAxisIndices{T,N,A,AI}}) where {T,N,A,AI} = IndexStyle(A)

@propagate_inbounds function Base.getindex(A::AbstractAxisIndices, inds...)
    return AxisIndexing.unsafe_getindex(A, to_indices(A, inds))
end

@propagate_inbounds function Base.view(A::AbstractAxisIndices, inds...)
    return AxisIndexing.unsafe_view(A, to_indices(A, inds))
end

@propagate_inbounds function Base.dotview(A::AbstractAxisIndices, inds...)
    return AxisIndexing.unsafe_dotview(A, to_indices(A, inds))
end

