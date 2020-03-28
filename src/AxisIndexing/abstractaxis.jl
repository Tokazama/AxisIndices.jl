
# This file is for code that is only relevant to AbstractAxis
#
# * TODO list for AbstractAxis
# - Is this necessary `Base.UnitRange{T}(a::AbstractAxis) where {T} = UnitRange{T}(values(a))`
# - Should AbstractAxes be a formal type?
# - is `nothing` what we want when there isn't a step in the keys
# - specialize `collect` on first type argument

"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,V<:Integer,Ks,Vs} <: AbstractUnitRange{V} end

"""
    AbstractSimpleAxis{V,Vs}

A subtype of `AbstractAxis` where the keys and values are represented by a single collection.
"""
abstract type AbstractSimpleAxis{V,Vs} <: AbstractAxis{V,V,Vs,Vs} end

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
   ) where {A<:AbstractAxis}
    return similar_type(A, ks_type, vs_type)
end

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
   ) where {A<:AbstractSimpleAxis}
    return similar_type(A, vs_type)
end

"""
    unsafe_reconstruct(axis::AbstractAxis, keys::Ks, values::Vs)

Reconstructs an `AbstractAxis` of the same type as `axis` but with keys of type `Ks` and values of type `Vs`.
This method is considered unsafe because it bypasses checks  to ensure that `keys` and `values` have the same length and the all `keys` are unique.
"""
function unsafe_reconstruct(a::AbstractAxis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs)
end

"""
    unsafe_reconstruct(axis::AbstractSimpleAxis, values::Vs)

Reconstructs an `AbstractSimpleAxis` of the same type as `axis` but values of type `Vs`.
"""
unsafe_reconstruct(a::AbstractSimpleAxis, vs::Vs) where {Vs} = similar_type(a, Vs)(vs)

maybe_unsafe_reconstruct(a::AbstractAxis, inds) = @inbounds(values(a)[inds])
function maybe_unsafe_reconstruct(a::AbstractAxis, inds::AbstractUnitRange)
    unsafe_reconstruct(a, @inbounds(keys(a)[inds]), @inbounds(values(a)[inds]))
end

maybe_unsafe_reconstruct(a::AbstractSimpleAxis, inds) = @inbounds(values(a)[inds])
function maybe_unsafe_reconstruct(a::AbstractSimpleAxis, inds::AbstractUnitRange)
    return unsafe_reconstruct(a, @inbounds(values(a)[inds]))
end

Base.isempty(a::AbstractAxis) = isempty(values(a))

function Base.empty!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    empty!(keys(a))
    empty!(values(a))
    return a
end

function Base.empty!(a::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    empty!(values(a))
    return a
end

# This is required for performing `similar` on arrays
Base.to_shape(r::AbstractAxis) = length(r)

#Base.convert(::Type{T}, a::T) where {T<:AbstractAxis} = a
#Base.convert(::Type{T}, a) where {T<:AbstractAxis} = T(a)
Base.sum(x::AbstractAxis) = sum(values(x))

###
### static traits
###
# for when we want the same underlying memory layout but reversed keys

# TODO should this be a formal abstract type?
const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}

"""
    indices(x, i)

Returns the indices corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
UnitMRange(1:2)
```
"""
indices(x, i) = values(axes(x, i))

"""
    indices(x)

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(UnitMRange(1:2), UnitMRange(1:2))
```
"""
indices(x) = map(values, axes(x))
indices(x::AbstractAxis) = values(x)

