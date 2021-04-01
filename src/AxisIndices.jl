
module AxisIndices

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end AxisIndices

using AbstractFFTs
using ArrayInterface
using ChainedFixes
using IntervalSets
using LinearAlgebra
using MappedArrays
using Metadata
using NamedDims
using SparseArrays
using ArrayInterface.Static
using StaticRanges
using Statistics
using SuiteSparse

using ArrayInterface.Static: is_static, nstatic, eachop_tuple

using EllipsisNotation: Ellipsis
using StaticRanges
using StaticRanges: unsafe_grow_beg!, unsafe_grow_end!, unsafe_shrink_beg!,
    unsafe_shrink_end!, unsafe_grow_end, unsafe_shrink_end

using Base: @propagate_inbounds, tail, LogicalIndex, Slice, OneTo, Fix2, ReinterpretArray
using Base: IdentityUnitRange, setindex
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using ArrayInterface: OptionallyStaticUnitRange
using ArrayInterface: known_length, known_first, known_step, known_last, can_change_size
using ArrayInterface: static_length, static_first, static_step, static_last, StaticInt, Zero, One
using ArrayInterface: indices, offsets, to_index, to_axis, to_axes, unsafe_reconstruct, parent_type
using ArrayInterface: can_setindex, to_dims, AbstractArray2, axes_types
using MappedArrays: MultiMappedArray, ReadonlyMultiMappedArray
using Base: print_array, print_matrix_row, print_matrix, alignment

const to_indices = ArrayInterface.to_indices

export
    AxisArray,
    AxisMatrix,
    AxisVector,
    AxisArray,
    CartesianAxes,
    LinearAxes,
    closest,
    permuteddimsview,
    struct_view,
    SimpleAxis,
    AxisKeys,
    AxisOffset,
    AxisOrigin,
    AxisName,
    ReflectPads,
    ReplicatePads,
    SymmetricPads,
    ReflectPads,
    OnePads,
    ZeroPads,
    CircularPads


"""
    AxisArray{T,N,P,A}

An array struct that wraps any parent array and assigns it an `AbstractAxis` for
each dimension. The first argument is the parent array and the second argument is
a tuple of subtypes to `AbstractAxis` or keys that will be converted to subtypes
of `AbstractAxis` with the provided keys.
"""
struct AxisArray{T,N,P,A<:Tuple{Vararg{<:Any,N}}} <: AbstractArray2{T,N}
    parent::P
    axes::A

    global function _AxisArray(p::P, a::A) where {P,N,A<:Tuple{Vararg{Any,N}}}
        return new{eltype(P),N,P,A}(p, a)
    end
end

ArrayInterface.parent_type(::Type{AxisArray{T,N,P,A}}) where {T,N,P,A} = P
Base.parent(x::AxisArray) = getfield(x, :parent)

ArrayInterface.axes_types(::Type{AxisArray{T,N,P,A}}) where {T,N,P,A} = A
ArrayInterface.axes(x::AxisArray) = getfield(x, :axes)

Base.getproperty(x::AxisArray, s::Symbol) = getproperty(parent(x), s)
Base.setproperty!(x::AxisArray, s::Symbol, val) = setproperty!(parent(x), s, val)

"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{P} <: AbstractUnitRange{Int} end

struct Axis{PA,P<:AbstractUnitRange{Int}} <: AbstractAxis{P}
    param::PA
    parent::P

    global _Axis(param::PA, parent::P) where {PA,P} = new{PA,P}(param, parent)
end

ArrayInterface.parent_type(::Type{Axis{PA,P}}) where {PA,P} = P
Base.parent(axis::Axis) = getfield(axis, :parent)


const ArrayInitializer = Union{UndefInitializer,Missing, Nothing}

include("utils.jl")
include("axis_parameters.jl")
include("axes_methods.jl")
include("axis_array.jl")
include("alias_arrays.jl")
include("indexing.jl")
include("linear_algebra.jl")
include("fft.jl")
include("arrays.jl")
#include("named.jl")
include("show.jl")

# TODO move this to ArrayInterface
ArrayInterface._multi_check_index(axs::Tuple, arg::LogicalIndex{<:Any,<:AxisArray}) = axs == axes(arg.mask)

include("closest.jl")

export ..

end
