
module AxisIndices

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end AxisIndices

using ArrayInterface
using ChainedFixes
using IntervalSets
using LinearAlgebra
using MappedArrays
using PrettyTables
using SparseArrays
using StaticRanges
using Statistics
using SuiteSparse

using EllipsisNotation: Ellipsis
using StaticRanges
using StaticRanges: OneToUnion
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type
using StaticRanges: checkindexlo, checkindexhi
using StaticRanges: grow_first!, grow_last!, grow_first, grow_last
using StaticRanges: shrink_first!, shrink_last!, shrink_first, shrink_last
using StaticRanges: resize_last, resize_last!, resize_first, resize_first!
using StaticRanges: is_static, is_fixed, similar_type

using Base: @propagate_inbounds, tail, LogicalIndex, Slice, OneTo, Fix2, ReinterpretArray
using Base: IdentityUnitRange, setindex
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using ArrayInterface: known_length, known_first, known_step, known_last, can_change_size
using ArrayInterface: static_length, static_first, static_step, static_last, StaticInt, Zero, One
using ArrayInterface: indices, offsets, to_index, to_axis, to_axes, unsafe_reconstruct, parent_type
using ArrayInterface: can_setindex
using MappedArrays: MultiMappedArray, ReadonlyMultiMappedArray
using Base: print_array, print_matrix_row, print_matrix, alignment

const to_indices = ArrayInterface.to_indices

export
    AbstractAxis,
    AxisArray,
    AxisVector,
    AxisMatrix,
    Axis,
    AxisArray,
    CartesianAxes,
    CenteredArray,
    CenteredAxis,
    IdentityArray,
    IdentityAxis,
    LinearAxes,
    NamedAxisArray,
    OffsetArray,
    OffsetAxis,
    OffsetVector,
    SimpleAxis,
    permuteddimsview,
    StructAxis,
    struct_view

const ArrayInitializer = Union{UndefInitializer, Missing, Nothing}

# Val wraps the number of axes to retain
naxes(A::AbstractArray, v::Val) = naxes(axes(A), v)
naxes(axs::Tuple, v::Val{N}) where {N} = _naxes(axs, N)
@inline function _naxes(axs::Tuple, i::Int)
    if i === 0
        return ()
    else
        return (first(axs), _naxes(tail(axs), i - 1)...)
    end
end

@inline function _naxes(axs::Tuple{}, i::Int)
    if i === 0
        return ()
    else
        return (SimpleAxis(1), _naxes((), i - 1)...)
    end
end

include("errors.jl")
include("abstract_axis.jl")
include("axis_array.jl")
include("simple_axis.jl")
include("axis.jl")
include("offset_axis.jl")
include("centered_axis.jl")
include("identity_axis.jl")
include("padded_axis.jl")
include("struct_axis.jl")

# TODO assign_indices tests
function assign_indices(axis, inds)
    if can_change_size(axis) && !((known_length(inds) === nothing) || known_length(inds) === known_length(axis))
        return unsafe_reconstruct(axis, inds)
    else
        return axis
    end
end

"""
    is_key([collection,] arg) -> Bool

Whether `arg` refers to a key of `axis`.
"""
is_key(arg) = is_key(IndexLinear(), typeof(arg))
is_key(collection, arg) = is_key(IndexStyle(collection), typeof(arg))
is_key(collection, ::Type{I}) where {I} = is_key(IndexStyle(collection), I)
is_key(::IndexStyle, ::Type{T}) where {T<:Colon} = false
is_key(::IndexStyle, ::Type{T}) where {T<:Integer} = false
is_key(S::IndexStyle, ::Type{T}) where {T<:AbstractArray} = is_key(S, eltype(T))
is_key(::IndexStyle, ::Type{T}) where {T} = true

include("axes_methods.jl")
include("combine.jl")
include("arrays.jl")
include("alias_arrays.jl")
include("linear_algebra.jl")
include("deprecations.jl")
include("abstractarray.jl")
include("promotion.jl")
include("named.jl")
include("show.jl")

# TODO move this to ArrayInterface
ArrayInterface._multi_check_index(axs::Tuple, arg::LogicalIndex{<:Any,<:AxisArray}) = axs == axes(arg.mask)

end

