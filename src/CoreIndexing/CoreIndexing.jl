
"""
    CoreIndexing
"""
module CoreIndexing

using IntervalSets
using ArrayInterface
using ChainedFixes
using LinearAlgebra
using MappedArrays
using SparseArrays
using StaticRanges
using Statistics
using SuiteSparse
using EllipsisNotation: Ellipsis

using StaticRanges
using StaticRanges: OneToUnion
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type
using StaticRanges: checkindexlo, checkindexhi
using StaticRanges: grow_first!, grow_last!
using StaticRanges: resize_last, resize_last!, resize_first, resize_first!
using StaticRanges: shrink_last!, is_static, is_fixed, similar_type

using Base: @propagate_inbounds, tail, LogicalIndex, Slice, OneTo, Fix2, ReinterpretArray
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using ArrayInterface: known_length, known_first, known_step, known_last, can_change_size
using ArrayInterface: static_length, static_first, static_step, static_last
using ArrayInterface: indices, offsets, parent_type, StaticInt

export
    AbstractAxis,
    Axis,
    AxisArray,
    CenteredAxis,
    IdentityAxis,
    OffsetAxis,
    SimpleAxis,
    StructAxis,
    as_keys,
    as_indices

const ArrayInitializer = Union{UndefInitializer, Missing, Nothing}

function check_axis_length(ks, inds)
    if length(ks) != length(inds)
        throw(DimensionMismatch(
            "keys and indices must have same length, got length(keys) = $(length(ks))" *
            " and length(indices) = $(length(inds)).")
        )
    end
    return nothing
end

function check_axis_unique(ks, inds)
    allunique(ks) || error("All keys must be unique.")
    allunique(inds) || error("All indices must be unique.")
    return nothing
end

include("core.jl")
include("axis_types.jl")
include("axis_methods.jl")
include("axes_methods.jl")
include("combine.jl")
include("promotion.jl")
include("arrays.jl")
include("linear_algebra.jl")

#=
@inline function Base.getindex(iter::CartesianIndices{N,R}, I::Vararg{Int, N}) where {N,R}
    @boundscheck checkbounds(iter, I...)
    CartesianIndex(I .- first.(Base.axes1.(iter.indices)) .+ first.(iter.indices))
end

CartesianIndices{N,NTuple{N,<:AbstractAxis}} where N
=#

#=

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
    @boundscheck if !in(i, eachindex(iter))
        throw(BoundsError(iter, i))
    end
    return i
end

@propagate_inbounds function Base.getindex(A::LinearAxes, inds...)
    return Base._getindex(IndexStyle(A), A, Interface.to_indices(A, Tuple(inds))...)
end


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

_cartesian_axes(axs::Tuple{}) = ()
_cartesian_axes(axs::Tuple) = (to_axis(first(axs)), _cartesian_axes(tail(axs))...)

CartesianAxes(axs::Tuple{Vararg{Any,N}}) where {N} = CartesianIndices(_cartesian_axes(axs))

Base.axes(A::CartesianAxes) = getfield(A, :indices)

@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}},
    inds::Vararg{Int}
) where {N}

    return CartesianIndex(map(getindex, axes(A), inds))
end

Base.getindex(A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}}, ::Ellipsis) where {N} = A

@propagate_inbounds function Base.getindex(
    A::CartesianAxes{N,<:NTuple{N,<:AbstractAxis}},
    inds...
) where {N}

    return Base._getindex(IndexStyle(A), A, Interface.to_indices(A, Tuple(inds))...)
end

@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}},
    inds::Vararg{Int,N}
) where {N}

    return CartesianIndex(Interface.to_indices(A, Tuple(inds)))
end
=#

end

