
module Arrays

using SparseArrays
using NamedDims
using LinearAlgebra
using Statistics

using EllipsisNotation: Ellipsis

using ArrayInterface
using ArrayInterface: parent_type

using MappedArrays
using StaticArrays

using StaticRanges
using StaticRanges: can_set_length
using StaticRanges: resize_last, resize_last!, grow_last, grow_last!, grow_first!, shrink_last!, shrink_first!
using StaticRanges: Length, OneToUnion

using AxisIndices.Styles
using AxisIndices.Interface
using AxisIndices.Interface: unsafe_reconstruct, check_axis_length, maybe_tail, naxes, check_axis_length
using AxisIndices.Interface: append_axis!
using AxisIndices.Interface: to_axis, to_axes, to_index

using AxisIndices.Axes
using AxisIndices.Axes: AbstractAxes
using AxisIndices.Axes: assign_indices, permute_axes, reverse_keys, reduce_axes, reshape_axes, cat_axis

using Base: @propagate_inbounds, OneTo, tail
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base: ReinterpretArray

export
    AbstractAxisArray,
    AbstractAxisMatrix,
    AbstractAxisVecOrMat,
    AbstractAxisVector,
    AxisArray,
    AxisVector,
    NamedAxisArray,
    permuteddimsview

# TODO these shouldn't be exported
export matmul_axes, get_factorization

const ArrayInitializer = Union{UndefInitializer, Missing, Nothing}

#const CoVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}

include("AbstractAxisArray.jl")
include("AxisArray.jl")
include("NamedAxisArray.jl")
include("broadcast.jl")
include("permutedims.jl")
include("map.jl")
include("factorizations.jl")
include("vectors.jl")
include("matrices.jl")
include("reinterpret.jl")

end
