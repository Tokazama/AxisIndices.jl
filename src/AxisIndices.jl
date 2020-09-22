
module AxisIndices

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end AxisIndices

using Reexport


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
    AxisArray,
    Axis,
    AxisArray,
    CenteredArray,
    CenteredAxis,
    IdentityArray,
    IdentityAxis,
    OffsetArray,
    OffsetAxis,
    SimpleAxis,
    StructAxis,
    as_keys,
    as_indices,
    struct_view

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
include("abstract_axis.jl")
include("axis_interface.jl")
include("offset_axis.jl")
include("axis_types.jl")
include("axes_methods.jl")
include("combine.jl")
include("promotion.jl")
include("arrays.jl")
include("alias_arrays.jl")
include("linear_algebra.jl")
include("struct_axis.jl")

end

