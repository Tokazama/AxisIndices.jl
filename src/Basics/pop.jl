
function Base.pop!(A::AbstractAxisIndices{T,1}) where {T}
    StaticRanges.shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end

function StaticRanges.pop(x::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    return unsafe_reconstruct(x, pop(keys(x)), pop(values(x)))
end

function StaticRanges.pop(x::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    return unsafe_reconstruct(x, pop(values(x)))
end

function Base.pop!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    StaticRanges.can_set_last(a) || error("Cannot change size of index of type $(typeof(a)).")
    pop!(keys(a))
    return pop!(values(a))
end

Base.pop!(si::AbstractSimpleAxis{V,Vs}) where {V,Vs} = pop!(values(si))

