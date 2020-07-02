
module Arrays

using SparseArrays
using NamedDims
using LinearAlgebra
using Statistics

using EllipsisNotation: Ellipsis
using ArrayInterface
using MappedArrays
using StaticArrays
using StaticRanges
using StaticRanges: can_set_length
using StaticRanges: resize_last, resize_last!, grow_last, grow_last!, grow_first!, shrink_last!, shrink_first!
using StaticRanges: Static, Fixed, Dynamic, Staticness, Length, OneToUnion

using AxisIndices.Styles

using AxisIndices.Metadata
using AxisIndices.Metadata: _construct_meta

using AxisIndices.Interface
using AxisIndices.Interface: unsafe_reconstruct, check_axis_length, maybe_tail, naxes, check_axis_length
using AxisIndices.Interface: append_axis!
using AxisIndices.Interface: as_staticness, to_axis, to_axes, to_index

using AxisIndices.Axes
using AxisIndices.Axes: AbstractAxes
using AxisIndices.Axes: assign_indices, permute_axes, reverse_keys, reduce_axes, reshape_axes, cat_axis

using AxisIndices.PrettyArrays

using Base: @propagate_inbounds, OneTo, tail
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

import MetadataArrays: MetadataArray

export
    AbstractAxisArray,
    AbstractAxisMatrix,
    AbstractAxisVecOrMat,
    AbstractAxisVector,
    AxisArray,
    AxisVector,
    MetaAxisArray,
    NamedAxisArray,
    NamedMetaAxisArray,
    OffsetArray,
    OffsetVector,
    permuteddimsview

# TODO these shouldn't be exported
export matmul_axes, get_factorization

const ArrayInitializer = Union{UndefInitializer, Missing, Nothing}

#const CoVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}

include("AbstractAxisArray.jl")
include("AxisArray.jl")
include("OffsetArray.jl")
include("NamedAxisArray.jl")
include("MetaAxisArray.jl")
include("NamedMetaAxisArray.jl")
include("broadcast.jl")
include("permutedims.jl")
include("map.jl")
include("factorizations.jl")
include("vectors.jl")
include("matrices.jl")

end
