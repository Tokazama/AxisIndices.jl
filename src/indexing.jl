# This file is for methods related to retreiving elements of collections
#
# Notes:
# `@propagate_inbounds` is widely used because indexing with filtering syntax
# means we don't know that it's inbounds until we've passed the function through
# `to_index`.

Base.IndexStyle(::Type{<:AbstractAxisIndices{T,N,A,AI}}) where {T,N,A,AI} = IndexStyle(A)

###
### first
###
Base.first(a::AbstractAxis) = first(values(a))
function StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis}
    return can_set_first(keys_type(T))
end
function StaticRanges.set_first!(x::AbstractAxis{K,V}, val::V) where {K,V}
    can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    resize_first!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_first(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_first(values(x), val)
    return unsafe_reconstruct(x, resize_first(keys(x), length(vs)), vs)
end

function StaticRanges.set_first(x::AbstractSimpleAxis{V}, val::V) where {V}
    return unsafe_reconstruct(x, set_first(values(x), val))
end
function StaticRanges.set_first!(x::AbstractSimpleAxis{V}, val::V) where {K,V}
    can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    return x
end

Base.firstindex(a::AbstractAxis) = firstindex(values(a))

###
### last
###
Base.last(a::AbstractAxis) = last(values(a))
function StaticRanges.can_set_last(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs}
    return StaticRanges.can_set_last(Ks) & StaticRanges.can_set_last(Vs)
end
function StaticRanges.set_last!(x::AbstractAxis{K,V}, val::V) where {K,V}
    can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    resize_last!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_last(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_last(values(x), val)
    return unsafe_reconstruct(x, resize_last(keys(x), length(vs)), vs)
end

Base.lastindex(a::AbstractAxis) = lastindex(values(a))

"""
    last_keys(x)

Returns the keys corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.last_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(3, 4)
```
"""
@inline last_keys(x) = map(last, axes_keys(x))

function StaticRanges.set_last!(x::AbstractSimpleAxis{V}, val::V) where {V}
    can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    return x
end

function StaticRanges.set_last(x::AbstractSimpleAxis{K}, val::K) where {K}
    return unsafe_reconstruct(x, set_last(values(x), val))
end

###
### checkbounds
###
Base.checkbounds(x::AbstractAxis, i) = checkbounds(Bool, x, i)

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

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.Slice)
    return checkindex(Bool, values(x), I)
end

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractRange)
    return checkindex(Bool, values(x), I)
end

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractVector{Bool})
    return checkindex(Bool, values(x), I)
end

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.LogicalIndex)
    return checkindex(Bool, values(x), I)
end

###
### reindex
###

"""
    reindex(a::AbstractAxis, inds::AbstractVector{Integer}) -> AbstractAxis

Returns an `AbstractAxis` of the same type as `a` where the keys of the axis are
constructed by indexing into the keys of `a` with `inds` (`keys(a)[inds]`) and the
values have the same first element as `first(values(a))` but a length matching `inds`.

## Examples
Note how in all cases the keys may change but values are still 1-based
```jldoctest
julia> using AxisIndices

julia> x, y, z = Axis(2:11, 1:10), Axis(1:10), SimpleAxis(1:10);

julia> reindex(x, 2:5)
Axis(3:6 => 1:4)

julia> reindex(y, 2:5)
Axis(2:5 => Base.OneTo(4))

julia> reindex(z, 2:5)
SimpleAxis(1:4)
```
"""
@propagate_inbounds reindex(a::AbstractAxis, inds) = unsafe_reindex(a, to_index(a, inds))
@propagate_inbounds function reindex(axs::Tuple, inds::Tuple{Integer,Vararg{Any}})
    return reindex(tail(axs), tail(inds))
end
@propagate_inbounds function reindex(axs::Tuple, inds::Tuple{AbstractVector{<:Integer},Vararg{Any}})
    return (unsafe_reindex(first(axs), first(inds)), reindex(tail(axs), tail(inds))...)
end
reindex(axs::Tuple{}, inds::Tuple{}) = ()


"""
    unsafe_reindex(a::AbstractAxis, inds::AbstractVector) -> AbstractAxis

Similar to `reindex` this function returns an index of the same type as `a` but
doesn't check that `inds` is inbounds.

See also: [`reindex`](@ref)

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.unsafe_reindex(SimpleAxis(OneToMRange(10)), 1:5)
SimpleAxis(OneToMRange(5))

julia> AxisIndices.unsafe_reindex(SimpleAxis(OneToSRange(10)), 1:5)
SimpleAxis(OneToSRange(5))
```
"""
function unsafe_reindex(a::AbstractAxis, inds)
    return unsafe_reconstruct(a, @inbounds(keys(a)[inds]), _reindex(values(a), inds))
end
function unsafe_reindex(a::AbstractSimpleAxis, inds)
    return unsafe_reconstruct(a, _reindex(values(a), inds))
end

_reindex(a::OneTo{T}, inds) where {T} = OneTo{T}(length(inds))
_reindex(a::OneToMRange{T}, inds) where {T} = OneToMRange{T}(length(inds))
_reindex(a::OneToSRange{T}, inds) where {T} = OneToSRange{T}(length(inds))
_reindex(a::T, inds) where {T<:AbstractUnitRange} = T(first(a), first(a) + length(inds) - 1)

###
### getindex
###
#=
We have to define several index types (AbstractUnitRange, Integer, and i...) in
order to avoid ambiguities.
=#
@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    inds::AbstractUnitRange{<:Integer}
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    @boundscheck checkbounds(a, inds)
    @inbounds return to_index(a, inds)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::Integer
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    @boundscheck checkbounds(a, i)
    @inbounds return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    inds::Function
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, inds)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i...
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    if length(i) > 1
        error(BoundsError(a, i...))
    else
        return _getindex(a, to_index(a, first(i)))
    end
end

_getindex(a::AbstractAxis, inds) = @inbounds(values(a)[inds])
function _getindex(a::AbstractAxis, inds::AbstractUnitRange)
    unsafe_reconstruct(a, @inbounds(keys(a)[inds]), @inbounds(values(a)[inds]))
end
_getindex(a::AbstractAxis, i::Integer) = @inbounds(values(a)[i])


_getindex(a::AbstractSimpleAxis, inds) = @inbounds(values(a)[inds])
function _getindex(a::AbstractSimpleAxis, inds::AbstractUnitRange)
    return unsafe_reconstruct(a, @inbounds(values(a)[inds]))
end
_getindex(a::AbstractSimpleAxis, i::Integer) = @inbounds(values(a)[i])
# TODO Type inference for things that we know produce UnitRange/GapRange, etc

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices, value, inds...)
    return setindex!(parent(a), value, to_indices(a, inds)...)
end

#=
@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices{T,1}, val, i) where {T}
    return setindex!(parent(a), val, Base.to_index(axes(a, 1), i))
end

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices{T,N}, val, i) where {T,N}
    return setindex!(parent(a), val, i)
end
=#

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

###
### Iterators
###
Base.eachindex(a::AbstractAxis) = values(a)

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

StaticRanges.check_iterate(r::AbstractAxis, i) = check_iterate(values(r), last(i))
StaticRanges.check_iterate(r::AbstractSimpleAxis, i) = check_iterate(values(r), i)

Base.collect(a::AbstractAxis) = collect(values(a))

