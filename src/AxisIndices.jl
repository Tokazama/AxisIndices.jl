
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

using EllipsisNotation: Ellipsis
using StaticRanges
using StaticRanges: unsafe_grow_beg!, unsafe_grow_end!, unsafe_shrink_beg!, unsafe_shrink_end!
using StaticRanges: is_static

using Base: @propagate_inbounds, tail, LogicalIndex, Slice, OneTo, Fix2, ReinterpretArray
using Base: IdentityUnitRange, setindex
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using ArrayInterface: OptionallyStaticUnitRange
using ArrayInterface: known_length, known_first, known_step, known_last, can_change_size
using ArrayInterface: static_length, static_first, static_step, static_last, StaticInt, Zero, One
using ArrayInterface: indices, offsets, to_index, to_axis, to_axes, unsafe_reconstruct, parent_type
using ArrayInterface: can_setindex, to_dims, AbstractArray2
using MappedArrays: MultiMappedArray, ReadonlyMultiMappedArray
using Base: print_array, print_matrix_row, print_matrix, alignment

const to_indices = ArrayInterface.to_indices

export
    AbstractAxis,
    AxisArray,
    AxisMatrix,
    AxisVector,
    Axis,
    AxisArray,
    CartesianAxes,
    LinearAxes,
    NamedAxisArray,
    SimpleAxis,
    StructAxis,
    center,
    closest,
    circular_pad,
    idaxis,
    permuteddimsview,
    nothing_pad,
    offset,
    one_pad,
    reflect_pad,
    replicate_pad,
    struct_view,
    symmetric_pad,
    zero_pad


const ArrayInitializer = Union{UndefInitializer, Missing, Nothing}

# TODO better erros than @assert in Pads
struct Pads{F,L}
    first_pad::F
    last_pad::L

    global _Pads(f::F, l::L) where {F,L} = new{F,L}(f, l)
    function Pads(f, l)
        @assert f > 0
        @assert l > 0
        _Pads(int(f), int(l))
    end
end

function Pads(; first_pad=Zero(), last_pad=Zero(), sym_pad=nothing)
    if sym_pad === nothing
        return Pads(first_pad, last_pad)
    else
        return Pads(sym_pad, sym_pad)
    end
end

include("utils.jl")
include("axis_array.jl")
include("axes/axes.jl")
include("abstract_axis.jl")

include("axis.jl")
include("offset_axis.jl")
include("centered_axis.jl")
include("struct_axis.jl")

include("padded_axis.jl")

include("similar.jl")

const MetaAxisArray{T,N,P,Axs,M} = Metadata.MetaArray{T,N,AxisArray{T,N,P,Axs},M}

const NamedMetaAxisArray{L,T,N,P,M,Axs} = NamedDimsArray{L,T,N,MetaAxisArray{T,N,P,Axs,M}}

include("getindex.jl")
include("permutedims.jl")
include("axes_methods.jl")
include("combine.jl")
include("reduce.jl")
include("arrays.jl")
include("resize.jl")
include("alias_arrays.jl")
include("linear_algebra.jl")
include("deprecations.jl")
include("abstractarray.jl")
include("promotion.jl")
include("named.jl")
include("show.jl")
include("fft.jl")

# TODO move this to ArrayInterface
ArrayInterface._multi_check_index(axs::Tuple, arg::LogicalIndex{<:Any,<:AxisArray}) = axs == axes(arg.mask)

###
### offsets
###
@inline function apply_offset(axis, arg)
    if arg isa Integer
        return Int(arg)
    else
        return arg
    end
end
apply_offset(axis::OffsetAxis, arg) = _apply_offset(getfield(axis, :offset), arg)
function apply_offset(axis::CenteredAxis, arg)
    p = parent(axis)
    return _apply_offset(_origin_to_offset(first(p), length(p), origin(axis)), arg)
end
_apply_offset(f, arg::Integer) = arg - f
_apply_offset(f, arg::AbstractArray) = arg .- f
function _apply_offset(f, arg::AbstractRange)
    if known_step(arg) === 1
        return (first(arg) - f):(last(arg) - f)
    else
        return (first(arg) - f):step(arg):(last(arg) - f)
    end
end

# add offsets
_add_offset(axis, x) = x
_add_offset(axis::OffsetAxis, arg) = __add_offset(getfield(axis, :offset), arg)
function _add_offset(axis::CenteredAxis, arg)
    p = parent(axis)
    return __add_offset(_origin_to_offset(first(p), length(p), origin(axis)), arg)
end
__add_offset(f, arg::Integer) = arg + f
__add_offset(f, arg::AbstractArray) = arg .+ f
function __add_offset(f, arg::AbstractRange)
    if known_step(arg) === 1
        return (first(arg) + f):(last(arg) + f)
    else
        return (first(arg) + f):step(arg):(last(arg) + f)
    end
end

# subtract offsets
apply_offsets(::Tuple{}, ::Tuple{}) = ()
apply_offsets(::Tuple{}, ::Tuple) = ()
apply_offsets(::Tuple, ::Tuple{}) = ()
@inline function apply_offsets(axs::Tuple{A}, inds::Tuple{<:Integer}) where {A}
    return (_sub_offset(first(axs), first(inds)),)
end
@inline function apply_offsets(axs::Tuple, inds::Tuple)
    return (_sub_offset(first(axs), first(inds)), apply_offsets(tail(axs), tail(inds))...)
end

# Metadata stuff
@inline function Metadata.metadata(x::AxisArray; dim=nothing, kwargs...)
    if dim === nothing
        return metadata(parent(x); kwargs...)
    else
        return metadata(axes(x, dim); kwargs...)
    end
end

# TODO replace initialize with to_axis or something
param(::InitOffset) = AxisOffset
param(::InitOrigin) = AxisOrigin
param(::InitZeroPads) = ZeroPads
param(::InitOnePads) = OnePads
param(::InitNothingPads) = NothingPads
param(::InitReplicatePads) = ReplicatePads
param(::InitSymmetricPads) = SymmetricPads
param(::InitCircularPads) = CircularPads
param(::InitReflectPads) = ReflectPads

param(axis::KeyedAxis) = _AxisKeys(getfield(axis, :keys))
param(axis::SimpleAxis) = nothing
param(axis::OffsetAxis) = AxisOffset(getfield(axis, :offset))
param(axis::CenteredAxis) = AxisOrigin(getfield(axis, :origin))
param(axis::PaddedAxis) = getfield(axis, :pads)
param(axis::StructAxis{T}) where {T} = _AxisStruct(T)

reparam(::NothingPads) = NothingPads
reparam(::OnePads) = OnePads
reparam(::ZeroPads) = ZeroPads
reparam(::ReplicatePads) = ReplicatePads
reparam(::SymmetricPads) = SymmetricPads
reparam(::CircularPads) = CircularPads
reparam(::ReflectPads) = ReflectPads


initialize(::Nothing, axis::AbstractUnitRange{Int}) = SimpleAxis(axis)
initialize(p::AxisOrigin, axis::AbstractUnitRange{Int}) = _CenteredAxis(p.origin, axis)
initialize(p::AxisOffset, axis::AbstractUnitRange{Int}) = _OffsetAxis(p.offset, axis)
initialize(p::PadsParameter, axis::AbstractUnitRange{Int}) = _PaddedAxis(p, axis)
initialize(p::AxisKeys, axis::AbstractUnitRange{Int}) = _Axis(p.keys, axis)
initialize(p::AxisStruct{T}, axis::AbstractUnitRange{Int}) where {T} = _StructAxis(T, axis)

initialize(p::PadsParameter, x) = AxisArray(x, ntuple(_ -> p, Val(ndims(x))))
initialize(::Axis, param, axis) = _Axis(param, axis)
initialize(::CenteredAxis, param, axis) = _CenteredAxis(param, axis)
initialize(::OffsetAxis, param, axis) = _CenteredAxis(param, axis)
initialize(::PaddedAxis, param, axis) = _PaddedAxis(param, axis)
initialize(::StructAxis, ::Type{T}, axis) where {T} = _StructAxis(T, axis)

include("closest.jl")

export ..

end

