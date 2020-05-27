
@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{Any, Vararg{Any}})
    Base.@_inline_meta
    return (to_index(first(axs), first(args)), to_indices(A, maybe_tail(axs), tail(args))...)
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{Colon, Vararg{Any}})
    Base.@_inline_meta
    return (values(first(axs)), to_indices(A, maybe_tail(axs), tail(args))...)
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    Base.@_inline_meta
    _, axstail = Base.IteratorsMD.split(axs, Val(N))
    return (to_index(A, first(args)), to_indices(A, axstail, tail(args))...)
end

# And boolean arrays behave similarly; they also skip their number of dimensions
@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{AbstractArray{Bool, N}, Vararg{Any}}) where N
    Base.@_inline_meta
    _, axes_tail = Base.IteratorsMD.split(axs, Val(N))
    return (to_index(first(axs), first(args)), to_indices(A, axes_tail, tail(args))...)
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{CartesianIndices, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, axs, (first(args).indices..., tail(args)...))
end

@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{CartesianIndices{0},Vararg{Any}})
    Base.@_inline_meta
    return (first(args), to_indices(A, axs, tail(args))...)
end

# But some index types require more context spanning multiple indices
# CartesianIndexes are simple; they just splat out
@propagate_inbounds function Base.to_indices(A, axs::Tuple{AbstractAxis, Vararg{Any}}, args::Tuple{CartesianIndex, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, axs, (first(args).I..., tail(args)...))
end

###
### checkbounds
###
Base.checkbounds(x::AbstractAxis, i) = checkbounds(Bool, x, i)

@inline Base.checkbounds(::Type{Bool}, a::AbstractAxis, i) = checkindex(Bool, a, i)

@inline function Base.checkbounds(::Type{Bool}, a::AbstractAxis, i::CartesianIndex{1})
    return checkindex(Bool, a, first(i.I))
end

@inline function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::Integer)
    return StaticRanges.checkindexlo(a, i) & StaticRanges.checkindexhi(a, i)
end

@inline function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractVector)
    return StaticRanges.checkindexlo(a, i) & StaticRanges.checkindexhi(a, i)
end

@inline function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractUnitRange)
    return StaticRanges.checkindexlo(a, i) & StaticRanges.checkindexhi(a, i) 
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.Slice)
    return checkindex(Bool, values(x), I)
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractRange)
    return checkindex(Bool, values(x), I)
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractVector{Bool})
    return checkindex(Bool, values(x), I)
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.LogicalIndex)
    return checkindex(Bool, values(x), I)
end

###
### getindex
###


#=
We have to define several index types (AbstractUnitRange, Integer, and i...) in
order to avoid ambiguities.
=#
@propagate_inbounds function Base.getindex(
    axis::AbstractAxis{K,V,Ks,Vs},
    arg::AbstractUnitRange{<:Integer}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    index = to_index(axis, arg)
    return unsafe_reconstruct(axis, to_keys(axis, arg, index), index)
end

@propagate_inbounds function Base.getindex(
    axis::AbstractSimpleAxis{V,Vs},
    args::AbstractUnitRange{<:Integer}
) where {V<:Integer,Vs<:AbstractUnitRange{V}}

    return unsafe_reconstruct(axis, to_index(axis, args))
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::Integer
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    a::AbstractSimpleAxis{V,Vs},
    i::Integer

) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::StepRange{<:Integer}
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    axis::AbstractAxis{K,V,Ks,Vs},
    arg
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return _axis_getindex(axis, arg, to_index(axis, arg))
end

@inline function _axis_getindex(axis::AbstractAxis, arg, index::AbstractUnitRange)
    return unsafe_reconstruct(axis, to_keys(axis, arg, index), index)
end
_axis_getindex(axis::AbstractAxis, arg, index) = index

@inline function _axis_getindex(axis::AbstractSimpleAxis, arg, index::AbstractUnitRange)
    return unsafe_reconstruct(axis, index)
end
_axis_getindex(axis::AbstractSimpleAxis, arg, index) = index


"""
    CartesianAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> cartaxes = CartesianAxes((Axis(2.0:5.0), Axis(1:4)));

julia> cartinds = CartesianIndices((1:4, 1:4));

julia> cartaxes[2, 2]
CartesianIndex(2, 2)

julia> cartinds[2, 2]
CartesianIndex(2, 2)
```
"""
const CartesianAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = CartesianIndices{N,R}

function CartesianAxes(ks::Tuple{Vararg{<:Integer,N}}) where {N}
    return CartesianIndices(map(SimpleAxis, ks))
end

function CartesianAxes(ks::Tuple{Vararg{<:Any,N}}) where {N}
    return CartesianIndices(ntuple(i -> to_axis(getfield(ks, i), false), Val(N)))
end

CartesianAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = CartesianIndices(ks)

Base.axes(A::CartesianAxes) = getfield(A, :indices)

function Base.getindex(A::CartesianAxes, inds::Vararg{Int})
    Base.@_propagate_inbounds_meta
    return CartesianIndex(map(getindex, axes(A), inds))
end

function Base.getindex(A::CartesianAxes, inds...)
    Base.@_propagate_inbounds_meta
    return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end

"""
    LinearAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> linaxes = LinearAxes((Axis(2.0:5.0), Axis(1:4)));

julia> lininds = LinearIndices((1:4, 1:4));

julia> linaxes[2, 2]
6

julia> lininds[2, 2]
6
```
"""
const LinearAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = LinearIndices{N,R}

LinearAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = LinearIndices(map(to_axis, ks))

Base.axes(A::LinearAxes) = getfield(A, :indices)

@boundscheck function Base.getindex(iter::LinearAxes, i::Int)
    @boundscheck checkbounds(iter, i)
    return i
end

@propagate_inbounds function Base.getindex(A::LinearAxes, inds...)
    return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end

