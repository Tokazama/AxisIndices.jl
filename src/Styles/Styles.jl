# TODO - Indices and Keys don't need AxisIndicesStyle pass in to_index b/c force_* bypasses this
# as_indices
# as_keys
# ndims
# ArgsStyle is better name
module Styles

using ChainedFixes
using IntervalSets
using StaticRanges
using StaticRanges: Staticness, resize_last
using Base: @propagate_inbounds, OneTo, Fix2, tail, front

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
    CartesianIndexCollection,
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
    is_key

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
    KeyElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a single
key to a single index.
"""
struct KeyElement <: AxisIndicesStyle end

is_element(::Type{KeyElement}) = true

AxisIndicesStyle(::Type{T}) where {T} = KeyElement()

"""
    IndexElement

A subtype of `AxisIndicesStyle` for propagating an argument to a single index.
"""
struct IndexElement <: AxisIndicesStyle end

is_element(::Type{IndexElement}) = true

is_index(::Type{IndexElement}) = true

AxisIndicesStyle(::Type{<:Integer}) = IndexElement()

"""
    BoolElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a single
`Bool` to a single index.
"""
struct BoolElement <: AxisIndicesStyle end

is_element(::Type{BoolElement}) = true

is_index(::Type{BoolElement}) = true

AxisIndicesStyle(::Type{Bool}) = BoolElement()

"""
    CartesianElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a `CartesianIndex`
to a single index.
"""
struct CartesianElement <: AxisIndicesStyle end

is_element(::Type{CartesianElement}) = true

AxisIndicesStyle(::Type{CartesianIndex{1}}) = CartesianElement()


"""
    KeysCollection

A subtype of `AxisIndicesStyle` for mapping a collection of keys a collection of indices.
"""
struct KeysCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{T}}) where {T} = KeysCollection()

"""
    IndicesCollection

A subtype of `AxisIndicesStyle` for propagating an argument to a collection of indices.
"""
struct IndicesCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{<:Integer}}) = IndicesCollection()

"""
    CartesianIndexCollection

A subtype of `AxisIndicesStyle` for propagating an argument to a collection of indices.
"""
struct CartesianIndexCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{<:CartesianIndex}}) = CartesianIndexCollection()

is_element(::Type{CartesianIndexCollection}) = true

"""
    BoolsCollection

A subtype of `AxisIndicesStyle` for mapping a collection of `Bool`s to a
collection of indices.
"""
struct BoolsCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{Bool}}) = BoolsCollection()

"""
    IntervalCollection

A subtype of `AxisIndicesStyle` for mapping an interval argument (`start..stop`)
from keys within said interval to a collection of indices.
"""
struct IntervalCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Interval}) = IntervalCollection()

"""
    KeysIn

A subtype of `AxisIndicesStyle` for mapping all keys given `in(keys)` to a collection
of indices.
"""
struct KeysIn <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Fix2{typeof(in)}}) = KeysIn()

"""
    IndicesIn

A subtype of `AxisIndicesStyle` for mapping all keys given `in(keys)` to a collection
of indices.
"""
struct IndicesIn <: AxisIndicesStyle end

"""
    KeyEquals

A subtype of `AxisIndicesStyle` for mapping a single key in a `isequal(key)` argument
to a single index.
"""
struct KeyEquals <: AxisIndicesStyle end

is_element(::Type{KeyEquals}) = true

AxisIndicesStyle(::Type{<:Approx}) = KeyEquals()

AxisIndicesStyle(::Type{<:Fix2{<:Union{typeof(isequal),typeof(==)}}}) = KeyEquals()

"""
    IndexEquals

A subtype of `AxisIndicesStyle` for mapping a single index in a `isequal(index)` argument
to a single index.
"""
struct IndexEquals <: AxisIndicesStyle end

is_element(::Type{IndexEquals}) = true

"""
    KeysFix2

A subtype of `AxisIndicesStyle` for mapping all keys from fixed argument (e.g., `>(key)`)
to the corresponding collection of indices.
"""
struct KeysFix2 <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Fix2}) = KeysFix2()

AxisIndicesStyle(::Type{<:ChainedFix}) = KeysFix2()

"""
    IndicesFix2

A subtype of `AxisIndicesStyle` for mapping all indices from fixed argument (e.g., `>(indices)`)
to the corresponding collection of indices.
"""
struct IndicesFix2 <: AxisIndicesStyle end

"""
    SliceCollection

A subtype of `AxisIndicesStyle` indicating that the entire axis should be propagated.
"""
struct SliceCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{Colon}) = SliceCollection()

AxisIndicesStyle(::Type{<:Base.Slice}) = SliceCollection()

is_index(::Type{SliceCollection}) = true

"""
    KeyedStyle{S}

A subtype of `AxisIndicesStyle` indicating that the axis is a always defaults to key based indexing.
"""
struct KeyedStyle{S} <: AxisIndicesStyle end

KeyedStyle(x) = KeyedStyle(AxisIndicesStyle(x))

KeyedStyle(S::AxisIndicesStyle) = KeyedStyle{force_keys(S)}()

is_element(::Type{KeyedStyle{T}}) where {T} = is_element(T)

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



end
