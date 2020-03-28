# This file is for methods related to retreiving elements of collections

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

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::AbstractAxisIndices, inds...)
            return $_f(a, to_indices(a, inds))
        end

        @propagate_inbounds function $_f(a::AbstractAxisIndices, inds::Tuple{Vararg{<:Integer}})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::AbstractAxisIndices{T,N}, inds::Tuple{Vararg{<:Any,M}}) where {T,N,M}
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::AbstractAxisIndices{T,N}, inds::Tuple{Vararg{<:Any,N}}) where {T,N}
            return unsafe_reconstruct(a, Base.$f(parent(a), inds...), reindex(axes(a), inds))
        end
    end
end

