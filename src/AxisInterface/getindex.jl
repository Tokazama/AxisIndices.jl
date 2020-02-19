
# have to define several getindex methods to avoid ambiguities with other unit ranges
@propagate_inbounds function Base.getindex(a::AbstractAxis{K,<:Integer}, inds::AbstractUnitRange{<:Integer}) where {K}
    @boundscheck checkbounds(a, inds)
    @inbounds return _getindex(a, inds)
end
@propagate_inbounds function Base.getindex(a::AbstractAxis{K,<:Integer}, i::Integer) where {K}
    @boundscheck checkbounds(a, i)
    @inbounds return _getindex(a, i)
end
@propagate_inbounds function Base.getindex(a::AbstractAxis, inds::Function)
    return getindex(a, to_index(a, inds))
end

function _getindex(a::AbstractAxis, inds)
    ks = @inbounds(keys(a)[inds])
    vs = @inbounds(values(a)[inds])
    return similar_type(a, typeof(ks), typeof(vs))(ks, vs, allunique(inds), false)
end
_getindex(a::AbstractAxis, i::Integer) = @inbounds(values(a)[i])

_getindex(a::SimpleAxis, inds) = SimpleAxis(@inbounds(values(a)[inds]))
_getindex(a::SimpleAxis, i::Integer) = @inbounds(values(a)[i])
# TODO Type inference for things that we know produce UnitRange/GapRange, etc

