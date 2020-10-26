
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
using ArrayInterface: OptionallyStaticUnitRange
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
    circular_pad,
    idaxis,
    permuteddimsview,
    offset,
    one_pad,
    reflect_pad,
    replicate_pad,
    struct_view,
    symmetric_pad,
    zero_pad


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

"""
    AxisInitializer <: Function

Supertype for functions that assist in initialization of `AbstractAxis` subtypes.
"""
abstract type AxisInitializer <: Function end

(init::AxisInitializer)(x) = Base.Fix2(init, x)
function (init::AxisInitializer)(collection, x)
    if known_step(collection) === 1
        return axis_method(init, x, collection)
    else
        return AxisArray(collection, ntuple(_ -> init(x), Val(ndims(collection))))
    end
end
function (init::AxisInitializer)(collection, x::Tuple)
    if ndims(collection) !== length(x)
        throw(DimensionMismatch("Number of axis arguments provided ($(length(x))) does " *
                                "not match number of collections's axes ($(ndims(collection)))."))
    end
    if known_step(collection) === 1
        return axis_method(init, first(x), collection)
    else
        return AxisArray(collection, map(init, x))
    end
end

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

const MetaAxisArray{T,N,P,Axs,M} = Metadata.MetaArray{T,N,AxisArray{T,N,P,Axs},M}

const NamedMetaAxisArray{L,T,N,P,M,Axs} = NamedDimsArray{L,T,N,MetaAxisArray{T,N,P,Axs,M}}


include("indexing.jl")
include("permutedims.jl")
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
apply_offset(axis::IdentityAxis, arg) = _apply_offset(getfield(axis, :offset), arg)
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
_add_offset(axis::IdentityAxis, arg) = __add_offset(getfield(axis, :offset), arg)
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
_sub_offset(axis, x) = x
_sub_offset(axis::OffsetAxis, arg) = __sub_offset(getfield(axis, :offset), arg)
_sub_offset(axis::IdentityAxis, arg) = __sub_offset(getfield(axis, :offset), arg)
function _sub_offset(axis::CenteredAxis, arg)
    p = parent(axis)
    return __sub_offset(_origin_to_offset(first(p), length(p), origin(axis)), arg)
end
__sub_offset(f, arg::Integer) = arg - f
__sub_offset(f, arg::AbstractArray) = arg .- f
function __sub_offset(f, arg::AbstractRange)
    if known_step(arg) === 1
        return (first(arg) - f):(last(arg) - f)
    else
        return (first(arg) - f):step(arg):(last(arg) - f)
    end
end


# Metadata stuff
@inline function Metadata.metadata(x::AxisArray; dim=nothing, kwargs...)
    if dim === nothing
        return metadata(parent(x); kwargs...)
    else
        return metadata(axes(x, dim); kwargs...)
    end
end

export ..

end

