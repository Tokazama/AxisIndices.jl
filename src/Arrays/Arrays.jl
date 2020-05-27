module Arrays

using NamedDims
using LinearAlgebra
using Statistics

using ArrayInterface
using MappedArrays
using MetadataArrays
using StaticArrays
using StaticRanges
using StaticRanges: can_set_length
using StaticRanges: resize_last, resize_last!, grow_last, grow_last!, grow_first!, shrink_last!, shrink_first!
using StaticRanges: Static, Fixed, Dynamic, Staticness, Length, OneToUnion

using AxisIndices.Interface
using AxisIndices.Interface: unsafe_reconstruct, check_axis_length, to_index, maybe_tail, naxes, check_axis_length
using AxisIndices.Interface: append_axis!


using AxisIndices.Axes
using AxisIndices.Axes: assign_indices, permute_axes, cat_axis, reverse_keys, reduce_axes, reshape_axes
using AxisIndices.Axes: AbstractAxes

using AxisIndices.PrettyArrays

using Base: @propagate_inbounds, OneTo, tail
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

export
    AbstractAxisArray,
    AbstractAxisMatrix,
    AbstractAxisVecOrMat,
    AbstractAxisVector,
    AxisArray,
    AxisVector,
    MetaAxisArray,
    NamedAxisArray

export matmul_axes, get_factorization

const CoVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}

include("abstractaxisarray.jl")
include("axisarray.jl")
include("metaaxisarray.jl")
include("broadcast.jl")
include("permutedims.jl")
include("map.jl")
include("matmul.jl")
include("factorizations.jl")
include("namedaxisarray.jl")
include("vectors.jl")
include("matrix.jl")

end
