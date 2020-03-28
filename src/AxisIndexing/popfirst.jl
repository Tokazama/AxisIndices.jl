
function StaticRanges.popfirst(x::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    return unsafe_reconstruct(x, popfirst(keys(x)), popfirst(values(x)))
end

function StaticRanges.popfirst(x::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    return unsafe_reconstruct(x, popfirst(values(x)))
end

function Base.popfirst!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    can_set_first(a) || error("Cannot change size of index of type $(typeof(a)).")
    popfirst!(keys(a))
    return popfirst!(values(a))
end

Base.popfirst!(si::AbstractSimpleAxis{V,Vs}) where {V,Vs} = popfirst!(values(si))

