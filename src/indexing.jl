# This file is for methods related to retreiving elements of collections

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
    return similar_type(x)(resize_first(keys(x), length(vs)), vs)
end

function StaticRanges.set_first(x::AbstractSimpleAxis{V}, val::V) where {V}
    val = set_first(values(x), val)
    return similar_type(x, typeof(val))(val)
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
    return similar_type(x)(resize_last(keys(x), length(vs)), vs)
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
    val = set_last(values(x), val)
    return similar_type(x, typeof(val))(val)
end

###
### to_index
###
@propagate_inbounds function Base.to_index(x::AbstractAxis, i::T) where {T}
    if is_key_type(T)
        return _maybe_throw_boundserror(x, findfirst(==(i), keys(x)))
    else
        return _maybe_throw_boundserror(x, Int(i))
    end
end

@propagate_inbounds function Base.to_index(x::AbstractAxis, f::Base.Fix2{<:Union{typeof(isequal),typeof(==)}})
    return _maybe_throw_boundserror(x, find_first(f, keys(x)))
end

@propagate_inbounds Base.to_index(x::AbstractAxis, f::Function) = find_all(f, keys(x))

@propagate_inbounds Base.to_index(x::AbstractAxis, i::CartesianIndex{1}) = first(i.I)


@propagate_inbounds function _maybe_throw_boundserror(x, i)::Integer
    @boundscheck if i isa Nothing
        throw(BoundsError(x, i))
    end
    return i
end

@propagate_inbounds function _maybe_throw_boundserror(x, inds::AbstractVector)
    @boundscheck if !(eltype(inds) <: Integer)
        throw(BoundsError(x, i))
    end
    return inds
end

@propagate_inbounds function Base.to_index(x::AbstractAxis, inds::AbstractVector{T}) where {T<:Integer}
    return to_index(inds)
end

@propagate_inbounds function Base.to_index(x::AbstractAxis, inds::AbstractVector{T}) where {T}
    if is_key_type(T)
        return _maybe_throw_boundserror(x, find_all(in(inds), keys(x)))
    else
        return _maybe_throw_boundserror(x, inds)  # TODO should probably promote this somehow to Int elments
    end
end

###
### to_indices
###
function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{Any, Vararg{Any}})
    Base.@_inline_meta
    return (to_index(first(inds), first(I)), to_indices(A, maybetail(inds), tail(I))...)
end

function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{Colon, Vararg{Any}})
    Base.@_inline_meta
    return (values(first(inds)), to_indices(A, maybetail(inds), tail(I))...)
end

function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndex, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, inds, (I[1].I..., tail(I)...))
end

function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    Base.@_inline_meta
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, first(I)), to_indices(A, indstail, tail(I))...)
end
# And boolean arrays behave similarly; they also skip their number of dimensions
@inline function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{Bool, N}, Vararg{Any}}) where N
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, I[1]), to_indices(A, indstail, tail(I))...)
end

maybetail(::Tuple{}) = ()
maybetail(t::Tuple) = tail(t)

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
```jldoctest
julia> using AxisIndices

julia> x, y, z = Axis(1:10, 2:11), Axis(1:10), SimpleAxis(1:10);

julia>  reindex(x, collect(1:2:10))
Axis([1, 3, 5, 7, 9] => 2:6)

julia> reindex(y, collect(1:2:10))
Axis([1, 3, 5, 7, 9] => Base.OneTo(5))

julia> reindex(z, collect(1:2:10))
SimpleAxis(1:5)

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
    ks = @inbounds(keys(a)[inds])
    vs = _reindex(values(a), inds)
    return similar_type(a, typeof(ks), typeof(vs))(ks, vs)
end
function unsafe_reindex(a::AbstractSimpleAxis, inds)
    vs = _reindex(values(a), inds)
    return similar_type(a, typeof(vs))(vs)
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
    @inbounds return _getindex(a, inds)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::Integer
    )  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}
    @boundscheck checkbounds(a, i)
    @inbounds return _getindex(a, i)
end
@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    inds::Function
    ) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}
    return getindex(a, to_index(a, inds))
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
    ks = @inbounds(keys(a)[inds])
    vs = @inbounds(values(a)[inds])
    return similar_type(a, typeof(ks), typeof(vs))(ks, vs, allunique(inds), false)
end
_getindex(a::AbstractAxis, i::Integer) = @inbounds(values(a)[i])


_getindex(a::AbstractSimpleAxis, inds) = @inbounds(values(a)[inds])
function _getindex(a::AbstractSimpleAxis, inds::AbstractUnitRange)
    ks = @inbounds(values(a)[inds])
    return similar_type(a, typeof(ks))(ks)
end
_getindex(a::AbstractSimpleAxis, i::Integer) = @inbounds(values(a)[i])
# TODO Type inference for things that we know produce UnitRange/GapRange, etc

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices, value, inds...)
    return setindex!(parent(a), value, to_indices(a, axes(a), inds)...)
end

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::AbstractAxisIndices, inds...)
            return $_f(a, to_indices(a, axes(a), inds))
        end

        @propagate_inbounds function $_f(a::AbstractAxisIndices, inds::Tuple{Vararg{<:Integer}})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::AbstractAxisIndices{T,N}, inds::Tuple{Vararg{<:Any,M}}) where {T,N,M}
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::AbstractAxisIndices{T,N}, inds::Tuple{Vararg{<:Any,N}}) where {T,N}
            return reconstruct(a, Base.$f(parent(a), inds...), reindex(axes(a), inds))
        end
    end
end

###
### Iterators
###
Base.eachindex(a::AbstractAxis) = eachindex(values(a))

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

StaticRanges.check_iterate(r::AbstractAxis, i) = check_iterate(values(r), last(i))
StaticRanges.check_iterate(r::AbstractSimpleAxis, i) = check_iterate(values(r), i)

Base.collect(a::AbstractAxis) = collect(values(a))

