
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

@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg)
    return checkindex(Bool, axis, arg)
end
@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg::AbstractVector)
    return checkindex(Bool, axis, arg)
end
@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg::CartesianIndex)
    return checkindex(Bool, axis, arg)
end

for T in (AbstractVector{Bool},
          AbstractArray,
          AbstractRange,
          Base.Slice,
          AbstractUnitRange,
          Integer,
          CartesianIndex{1},
          Base.LogicalIndex,
          Any
         )
    @eval begin
        function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::$T)
            return Styles.check_index(axis, arg)
        end
    end
end


###
### getindex
###


#=
We have to define several index types (AbstractUnitRange, Integer, and i...) in
order to avoid ambiguities.
=#
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{<:Integer})
    inds = to_index(axis, arg)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, to_keys(axis, arg, inds), inds)
    end
end

@propagate_inbounds Base.getindex(axis::AbstractAxis, i::Integer) = to_index(axis, i)

@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{<:Integer})
    return to_index(axis, arg)
end

@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    return _axis_getindex(axis, arg, to_index(axis, arg))
end

@inline function _axis_getindex(axis::AbstractAxis, arg, inds::AbstractUnitRange)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, to_keys(axis, arg, inds), inds)
    end
end
_axis_getindex(axis::AbstractAxis, arg, index) = index

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

