
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

Base.checkbounds(a::AbstractAxis, i) = checkbounds(Bool, a, i)

Base.checkbounds(::Type{Bool}, a::AbstractAxis, i) = checkindex(Bool, a, i)

function Base.checkbounds(::Type{Bool}, a::AbstractAxis, i::CartesianIndex{1})
    return checkindex(Bool, a, first(i.I))
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::Integer)
    return checkindexlo(a, i) & checkindexhi(a, i)
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractVector)
    return checkindexlo(a, i) & checkindexhi(a, i)
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractUnitRange)
    return checkindexlo(a, i) & checkindexhi(a, i) 
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::Base.Slice)
    return checkindex(Bool, values(a), i)
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::StepRange)
    return checkindexlo(a, i) & checkindexhi(a, i)
end

function Base.checkindex(::Type{Bool}, indx::AbstractAxis, I::AbstractVector{Bool})
    return length(indx) == length(I)
end

function Base.checkindex(::Type{Bool}, indx::AbstractAxis, I::Base.LogicalIndex)
    return length(indx) == length(axes(I.mask, 1))
end

