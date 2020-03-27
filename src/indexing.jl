# This file is for methods related to retreiving elements of collections

###
### to_indices
###
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

@propagate_inbounds function Base.to_indices(A::AbstractAxisIndices, I::Tuple{Integer})
    Base.@_inline_meta
    return (to_index(eachindex(IndexLinear(), A), first(I)),)
end

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

Base.IndexStyle(::Type{<:AbstractAxisIndices{T,N,A,AI}}) where {T,N,A,AI} = IndexStyle(A)

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

    return to_index(a, inds)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::Integer
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::StepRange{<:Integer}
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, i)
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
        return to_index(a, first(i))
    end
end

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

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices, value, inds...)
    return setindex!(parent(a), value, to_indices(a, inds)...)
end

