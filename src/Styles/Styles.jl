# FIXME to_index(::OffsetAxis, :) returns the indices instead of a Slice
# TODO - Indices and Keys don't need AxisIndicesStyle pass in to_index b/c force_* bypasses this
module Styles

using AxisIndices.Interface
using AxisIndices.Interface: assign_indices, to_axis, maybe_tail
using ChainedFixes
using IntervalSets
using StaticRanges
using StaticRanges: Staticness, resize_last
using Base: @propagate_inbounds, OneTo, Fix2, tail, front, Fix2

export
    Indices,
    Keys,
    AxisIndicesStyle,
    KeyElement,
    IndexElement,
    BoolElement,
    CartesianElement,
    KeysCollection,
    IndicesCollection,
    IntervalCollection,
    BoolsCollection,
    KeysIn,
    IndicesIn,
    KeyEquals,
    IndexEquals,
    KeysFix2,
    IndicesFix2,
    SliceCollection,
    KeyedStyle,
    # methods
    is_collection,
    is_element,
    is_index,
    is_key,
    to_index,
    to_keys

"""
    Indices(arg)

Forces `arg` to refer to indices when indexing.
"""
struct Indices{T}
    x::T
end

"""
    Keys(arg)

Forces `arg` to refer to keys when indexing.
"""
struct Keys{T}
    x::T
end

"""
    AxisIndicesStyle

Supertype for traits that control the behavior of `AxisIndices.to_index` and
`AxisIndices.to_key`.
"""
abstract type AxisIndicesStyle end

"""
    is_index(x) -> Bool

Whether `x` is an `AxisIndicesStyle`, returns `true` if it's used to search the
indices space.
"""
is_index(::T) where {T} = is_index(T)
is_index(::Type{T}) where {T} = is_index(AxisIndicesStyle(T))
is_index(::Type{<:AxisIndicesStyle}) = false 

"""
    is_element(x) -> Bool

Whether `x` is an `AxisIndicesStyle`, returns `true` if it's used to index a single
element.
"""
is_element(::T) where {T} = is_element(T)
is_element(::Type{T}) where {T} = is_element(AxisIndicesStyle(T))
is_element(::Type{<:AxisIndicesStyle}) = false

"""
    is_collection(x) -> Bool

Whether `x` is an `AxisIndicesStyle`, returns `true` if it's used to index a collection
of indices.
"""
is_collection(x) = !is_element(x)

"""
    is_key(x) -> Bool

Whether `x` is an `AxisIndicesStyle`, returns `true` if it's used to search the
keys space.
"""
is_key(x) = !is_index(x)

"""
    to_keys([::AxisIndicesStyle,] axis, arg, index)

This method is the reverse of `AxisIndices.to_index`. `arg` refers to an argument
originally passed to `AxisIndices.to_index` and `index` refers to the index produced
by that same call to `AxisIndices.to_index`.

This method assumes to all arguments have passed through `AxisIndices.to_index` and
have been checked to be in bounds. Therefore, this is unsafe and intended only for
internal use.
"""
@inline function to_keys(axis, arg, index)
    return to_keys(AxisIndicesStyle(axis, arg), axis, arg, index)
end

@inline function to_keys(axis, arg::Indices, index)
    return to_keys(AxisIndicesStyle(axis, arg), axis, arg.x, index)
end

@inline function to_keys(axis, arg::Keys, index)
    return to_keys(AxisIndicesStyle(axis, arg), axis, arg.x, index)
end

"""
    to_index(axis, arg) -> to_index(AxisIndicesStyle(axis, arg), axis, arg)

Unique implementation of `to_index` for the `AxisIndices` package that specializes
based on each axis and indexing argument (as opposed to the array and indexing argument).
"""
@propagate_inbounds function to_index(axis, arg)
    return to_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function to_index(axis, arg::Indices)
    return to_index(force_indices(AxisIndicesStyle(axis, arg)), axis, arg.x)
end

@propagate_inbounds function to_index(axis, arg::Keys)
    return to_index(force_keys(AxisIndicesStyle(axis, arg)), axis, arg.x)
end

# check_index - basically checkindex but passes a style trait argument
@propagate_inbounds function check_index(axis, arg)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function check_index(axis, arg::Indices)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

@propagate_inbounds function check_index(axis, arg::Keys)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

"""
    KeyElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a single
key to a single index.
"""
struct KeyElement <: AxisIndicesStyle end

is_element(::Type{KeyElement}) = true

AxisIndicesStyle(::Type{T}) where {T} = KeyElement()

@propagate_inbounds function to_index(::KeyElement, axis, arg)
    mapping = find_firsteq(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

to_keys(::KeyElement, axis, arg, index) = arg

check_index(::KeyElement, axis, arg) = arg in keys(axis)

"""
    IndexElement

A subtype of `AxisIndicesStyle` for propagating an argument to a single index.
"""
struct IndexElement <: AxisIndicesStyle end

is_element(::Type{IndexElement}) = true

is_index(::Type{IndexElement}) = true

AxisIndicesStyle(::Type{<:Integer}) = IndexElement()

@propagate_inbounds function to_index(::IndexElement, axis, arg)
    @boundscheck if !in(arg, indices(axis))
        throw(BoundsError(axis, arg))
    end
    return arg
end

to_keys(::IndexElement, axis, arg, index) = v2k(keys(axis), indices(axis), index)

check_index(::IndexElement, axis, arg) = arg in indices(axis)

"""
    BoolElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a single
`Bool` to a single index.
"""
struct BoolElement <: AxisIndicesStyle end

is_element(::Type{BoolElement}) = true

is_index(::Type{BoolElement}) = true

AxisIndicesStyle(::Type{Bool}) = BoolElement()

@propagate_inbounds to_index(::BoolElement, axis, arg) = getindex(values(axis), arg)

check_index(::BoolElement, axis, arg) = checkindex(Bool, indices(axis), arg)

"""
    CartesianElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a `CartesianIndex`
to a single index.
"""
struct CartesianElement <: AxisIndicesStyle end

is_element(::Type{CartesianElement}) = true

AxisIndicesStyle(::Type{CartesianIndex{1}}) = CartesianElement()

@propagate_inbounds function to_index(::CartesianElement, axis, arg)
    index = first(arg.I)
    @boundscheck if !checkindex(Bool, values(axis), index)
        throw(BoundsError(axis, arg))
    end
    return index
end

check_index(::CartesianElement, axis, arg) = checkindex(Bool, indices(axis), first(arg.I))

"""
    KeysCollection

A subtype of `AxisIndicesStyle` for mapping a collection of keys a collection of indices.
"""
struct KeysCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{T}}) where {T} = KeysCollection()

to_keys(::KeysCollection, axis, arg, index) = arg

@propagate_inbounds function to_index(::KeysCollection, axis, arg)
    mapping = findin(arg, keys(axis))
    @boundscheck if length(arg) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

check_index(::KeysCollection, axis, arg) = length(findin(arg, keys(axis))) == length(arg)

"""
    IndicesCollection

A subtype of `AxisIndicesStyle` for propagating an argument to a collection of indices.
"""
struct IndicesCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{<:Integer}}) = IndicesCollection()

@inline function to_keys(::IndicesCollection, axis, arg, index)
    mapping = findin(arg, indices(axis))
    return v2k(keys(axis), indices(axis), mapping)
end

# TODO boundschecking should be replace by the yet undeveloped `allin` method in StaticRanges
# if we're referring to an element than we just need to know if it's inbounds
@propagate_inbounds function to_index(::IndicesCollection, axis, arg)
    @boundscheck if length(findin(arg, indices(axis))) != length(arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end

check_index(::IndicesCollection, axis, arg) = length(findin(arg, indices(axis))) == length(arg)

"""
    BoolsCollection

A subtype of `AxisIndicesStyle` for mapping a collection of `Bool`s to a
collection of indices.
"""
struct BoolsCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{Bool}}) = BoolsCollection()

@inline function to_keys(::BoolsCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), index))
end

@propagate_inbounds function to_index(::BoolsCollection, axis, arg)
    return getindex(values(axis), arg)
end

check_index(::BoolsCollection, axis, arg) = checkindex(Bool, indices(axis), arg)

"""
    IntervalCollection

A subtype of `AxisIndicesStyle` for mapping an interval argument (`start..stop`)
from keys within said interval to a collection of indices.
"""
struct IntervalCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Interval}) = IntervalCollection()

@inline to_keys(::IntervalCollection, axis, arg, index) = v2k(keys(axis), indices(axis), index)

function to_index(::IntervalCollection, axis, arg)
    return k2v(keys(axis), indices(axis), findin(arg, keys(axis)))
end

check_index(::IntervalCollection, axis, arg) = true

"""
    KeysIn

A subtype of `AxisIndicesStyle` for mapping all keys given `in(keys)` to a collection
of indices.
"""
struct KeysIn <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Fix2{typeof(in)}}) = KeysIn()

to_keys(::KeysIn, axis, arg, index) = arg.x

@propagate_inbounds function to_index(::KeysIn, axis, arg)
    mapping = findin(arg.x, keys(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

check_index(::KeysIn, axis, arg) = length(findin(arg.x, keys(axis))) == length(arg.x)

"""
    IndicesIn

A subtype of `AxisIndicesStyle` for mapping all keys given `in(keys)` to a collection
of indices.
"""
struct IndicesIn <: AxisIndicesStyle end

to_keys(::IndicesIn, axis, arg, index) = v2k(keys(axis), indices(axis), index)

@propagate_inbounds function to_index(::IndicesIn, axis, arg)
    mapping = findin(arg.x, indices(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return mapping
end

check_index(::IndicesIn, axis, arg) = length(findin(arg.x, indices(axis))) == length(arg.x)

"""
    KeyEquals

A subtype of `AxisIndicesStyle` for mapping a single key in a `isequal(key)` argument
to a single index.
"""
struct KeyEquals <: AxisIndicesStyle end

is_element(::Type{KeyEquals}) = true

AxisIndicesStyle(::Type{<:Approx}) = KeyEquals()

AxisIndicesStyle(::Type{<:Fix2{<:Union{typeof(isequal),typeof(==)}}}) = KeyEquals()

@propagate_inbounds function to_index(::KeyEquals, axis, arg)
    mapping = find_first(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

to_keys(::KeyEquals, axis, arg, index) = arg.x

check_index(::KeyEquals, axis, arg) = !isa(find_first(arg, keys(axis)), Nothing)

"""
    IndexEquals

A subtype of `AxisIndicesStyle` for mapping a single index in a `isequal(index)` argument
to a single index.
"""
struct IndexEquals <: AxisIndicesStyle end

is_element(::Type{IndexEquals}) = true

@propagate_inbounds function to_index(::IndexEquals, axis, arg)
    @boundscheck if !checkbounds(Bool, indices(axis), arg.x)
        throw(BoundsError(axis, arg.x))
    end
    return arg.x
end

to_keys(::IndexEquals, axis, arg, index) = v2k(keys(axis), indices(axis), index)

check_index(::IndexEquals, axis, arg) = checkbounds(Bool, indices(axis), arg.x)

"""
    KeysFix2

A subtype of `AxisIndicesStyle` for mapping all keys from fixed argument (e.g., `>(key)`)
to the corresponding collection of indices.
"""
struct KeysFix2 <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Fix2}) = KeysFix2()

AxisIndicesStyle(::Type{<:ChainedFix}) = KeysFix2()

@inline to_keys(::KeysFix2, axis, arg, index) = v2k(keys(axis), indices(axis), index)

@inline to_index(::KeysFix2, axis, arg) = k2v(keys(axis), indices(axis), find_all(arg, keys(axis)))

check_index(::KeysFix2, axis, arg) = true

"""
    IndicesFix2

A subtype of `AxisIndicesStyle` for mapping all indices from fixed argument (e.g., `>(indices)`)
to the corresponding collection of indices.
"""
struct IndicesFix2 <: AxisIndicesStyle end

@inline to_keys(::IndicesFix2, axis, arg, index) = v2k(keys(axis), indices(axis), index)

@inline to_index(::IndicesFix2, axis, arg) = find_all(arg, values(axis))

check_index(::IndicesFix2, axis, arg) = true

"""
    SliceCollection

A subtype of `AxisIndicesStyle` indicating that the entire axis should be propagated.
"""
struct SliceCollection <: AxisIndicesStyle end

is_index(::Type{SliceCollection}) = true

@inline to_keys(::SliceCollection, axis, arg, index) = keys(axis)

AxisIndicesStyle(::Type{Colon}) = SliceCollection()

AxisIndicesStyle(::Type{<:Base.Slice}) = SliceCollection()

to_index(::SliceCollection, axis, arg) = Base.Slice(values(axis))

check_index(::SliceCollection, axis, arg) = true

"""
    KeyedStyle{S}

A subtype of `AxisIndicesStyle` indicating that the axis is a always defaults to key based indexing.
"""
struct KeyedStyle{S} <: AxisIndicesStyle end

KeyedStyle(x) = KeyedStyle(AxisIndicesStyle(x))
KeyedStyle(S::AxisIndicesStyle) = KeyedStyle{force_keys(S)}()

is_element(::Type{KeyedStyle{T}}) where {T} = is_element(T)

to_index(::KeyedStyle{S}, axis, arg) where {S} = to_index(S, axis, arg)

to_keys(::KeyedStyle{S}, axis, arg, index) where {S} = to_keys(S, axis, arg, index)

check_index(::KeyedStyle{S}, axis, arg) where {S} = check_index(S, axis, arg)

# we throw `axis` in there in case someone want's to change the default
@inline AxisIndicesStyle(::A, ::T) where {A<:AbstractUnitRange, T} = AxisIndicesStyle(A, T)
AxisIndicesStyle(::Type{A}, ::Type{T}) where {A,T} = AxisIndicesStyle(T)

AxisIndicesStyle(::Type{Indices{T}}) where {T} = force_indices(AxisIndicesStyle(T))
force_indices(S::AxisIndicesStyle) = S
force_indices(::KeyedStyle{S}) where {S} = force_indices(S)
force_indices(::KeyElement) = IndexElement()
force_indices(::KeyEquals) = IndexEquals()
force_indices(::KeysFix2) = IndicesFix2()
force_indices(::KeysIn) = IndicesIn()

AxisIndicesStyle(::Type{Keys{T}}) where {T} = force_keys(AxisIndicesStyle(T))
force_keys(S::AxisIndicesStyle) = S
force_keys(S::IndicesCollection) = KeysCollection()
force_keys(S::IndexElement) = KeyElement()


# handle offsets
function k2v(ks, inds, index::Integer)
    if StaticRanges.has_offset_axes(inds)
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(inds, index + axis_offset(inds) - axis_offset(ks)))
        else
            return @inbounds(getindex(inds, index + axis_offset(inds)))
        end
    else
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(inds, index - axis_offset(ks)))
        else
            return @inbounds(getindex(inds, index))
        end
    end
end

function k2v(ks, inds, index::AbstractVector{<:Integer})
    if StaticRanges.has_offset_axes(inds)
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(inds, index .+ (axis_offset(inds) - axis_offset(ks))))
        else
            return @inbounds(getindex(inds, index .+ axis_offset(inds)))
        end
    else
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(inds, index .- axis_offset(ks)))
        else
            return @inbounds(getindex(inds, index))
        end
    end
end

function v2k(ks, inds, index::Integer)
    if StaticRanges.has_offset_axes(inds)
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(ks, index - axis_offset(inds) + axis_offset(ks)))
        else
            return @inbounds(getindex(ks, index - axis_offset(inds)))
        end
    else
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(ks, index + axis_offset(ks)))
        else
            return @inbounds(getindex(ks, index))
        end
    end
end

function v2k(ks, inds, index::AbstractVector{<:Integer})
    if StaticRanges.has_offset_axes(inds)
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(ks, index .- (axis_offset(inds) + axis_offset(ks))))
        else
            return @inbounds(getindex(ks, index .- axis_offset(inds)))
        end
    else
        if StaticRanges.has_offset_axes(ks)
            return @inbounds(getindex(ks, index .+ axis_offset(ks)))
        else
            return @inbounds(getindex(ks, index))
        end
    end
end

###
### to_axes
###

# N-Dimension -> M-Dimension
function to_axes(
    A::AbstractArray{T,N},
    args::NTuple{M,Any},
    interim_indices::Tuple,
    new_indices::Tuple,
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I),
) where {T,N,M}
    return _to_axes(axes(A), args, interim_indices, new_indices, check_length, staticness)
end

# 1-Dimension -> 1-Dimension
function to_axes(
    A::AbstractArray{T,1},
    args::NTuple{1,Any},
    interim_indices::Tuple,
    new_indices::Tuple,
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I),
) where {T}
    return _to_axes(axes(A), args, interim_indices, new_indices, check_length, staticness)
end

# N-dimensions -> 1-dimension
@inline function to_axes(
    A::AbstractArray{T,N},
    args::NTuple{1,Any},
    interim_indices::Tuple,
    new_indices::Tuple,
    check_length::Bool=false,
    staticness=StaticRanges.Staticness(I),
) where {T,N}
    axis = axes(A, 1)
    index = first(new_indices)
    if is_indices_axis(axis)
        return (assign_indices(axis, index),)
    else
        return (to_axis(axis, resize_last(keys(axis), length(index)), index, false, staticness),)
    end
end


@inline function _to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{T, Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool,
    staticness,
) where {A,T,I}

    S = AxisIndicesStyle(A, T)
    if is_element(S)
        return _to_axes(
            maybe_tail(old_axes),
            maybe_tail(args),
            maybe_tail(interim_indices),
            new_indices,
            check_length,
            staticness
        )
    else
        axis = first(old_axes)
        index = first(new_indices)
        if is_indices_axis(axis)
            new_axis = to_axis(axis, nothing, index, check_length, staticness)
        else
            new_axis = to_axis(axis, to_keys(axis, first(args), first(interim_indices)), index, check_length, staticness)
        end
        return (new_axis,
            _to_axes(
                maybe_tail(old_axes),
                maybe_tail(args),
                maybe_tail(interim_indices),
                maybe_tail(new_indices),
                check_length,
                staticness
            )...,
        )
    end
end

@inline function _to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{CartesianIndex{N},Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool,
    staticness
) where {A,N,I}

    _, old_axes2 = Base.IteratorsMD.split(old_axes, Val(N))
    _, interim_indices2 = Base.IteratorsMD.split(interim_indices, Val(N))
    return _to_axes(old_axes2, tail(args), interim_indices2, new_indices, check_length, staticness)
end

@inline function _to_axes(
    old_axes::Tuple{A,Vararg{Any}},
    args::Tuple{CartesianIndices, Vararg{Any}},
    interim_indices::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool,
    staticness
) where {A,I}

    return _to_axes(old_axes, tail(args), tail(interim_indices), new_indices, check_length, staticness)
end

_to_axes(::Tuple, ::Tuple{CartesianIndex{N},Vararg{Any}}, ::Tuple, ::Tuple{}, ::Bool, ::Any) where {N} = ()
_to_axes(::Tuple, ::Tuple{Any,Vararg{Any}},               ::Tuple, ::Tuple{}, ::Bool, ::Any) = ()
_to_axes(::Tuple, ::Tuple,                                ::Tuple, ::Tuple{}, ::Bool, ::Any) = ()

@inline function to_axes(
    old_axes::Tuple,
    new_keys::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}
    return (
        to_axis(first(old_axes), first(new_keys), first(new_indices), check_length, staticness),
        to_axes(tail(old_axes), tail(new_keys), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    old_axes::Tuple,
    ::Tuple{},
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(first(old_axes), nothing, first(new_indices), check_length, staticness),
        to_axes(tail(old_axes), (), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    ::Tuple{},
    new_keys::Tuple,
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(first(new_keys), first(new_indices), check_length, staticness),
        to_axes((), tail(new_keys), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    ::Tuple{},
    ::Tuple{},
    new_indices::Tuple{I,Vararg{Any}},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(nothing, first(new_indices), check_length, staticness),
        to_axes((), (), tail(new_indices), check_length, staticness)...
    )
end

@inline function to_axes(
    ::Tuple{},
    ks::Tuple{I,Vararg{Any}},
    new_indices::Tuple{},
    check_length::Bool=true,
    staticness=StaticRanges.Staticness(I)
) where {I}

    return (
        to_axis(first(ks), check_length, staticness),
        to_axes((), tail(ks), (), check_length, staticness)...
    )
end

to_axes(::Tuple{}, ::Tuple{}, ::Tuple{}, check_length::Bool=true, staticness=StaticRanges.Fixed()) = ()
to_axes(::Tuple, ::Tuple{}, ::Tuple{}, check_length::Bool=true, staticness=StaticRanges.Fixed()) = ()

end
