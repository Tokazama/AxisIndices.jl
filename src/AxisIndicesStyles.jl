module AxisIndicesStyles

using Base: Fix2
using IntervalSets
using StaticRanges

export
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
    KeyEquals,
    KeysFix2,
    SliceCollection,
    is_element,
    is_index,
    is_collection,
    is_key

if length(methods(isapprox, Tuple{Any})) == 0
    Base.isapprox(y; kwargs...) = x -> isapprox(x, y; kwargs...)
end
const IsApproxFix = typeof(isapprox(Any)).name.wrapper


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

"""
    IndexElement

A subtype of `AxisIndicesStyle` for propagating an argument to a single index.
"""
struct IndexElement <: AxisIndicesStyle end
is_element(::Type{IndexElement}) = true
is_index(::Type{IndexElement}) = true

"""
    BoolElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a single
`Bool` to a single index.
"""
struct BoolElement <: AxisIndicesStyle end
is_element(::Type{BoolElement}) = true
is_index(::Type{BoolElement}) = true

"""
    CartesianElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a `CartesianIndex`
to a single index.
"""
struct CartesianElement <: AxisIndicesStyle end
is_element(::Type{CartesianElement}) = true

"""
    KeysCollection

A subtype of `AxisIndicesStyle` for mapping a collection of keys a collection of indices.
"""
struct KeysCollection <: AxisIndicesStyle end

"""
    IndicesCollection

A subtype of `AxisIndicesStyle` for propagating an argument to a collection of indices.
"""
struct IndicesCollection <: AxisIndicesStyle end

"""
    BoolsCollection

A subtype of `AxisIndicesStyle` for mapping a collection of `Bool`s to a
collection of indices.
"""
struct BoolsCollection <: AxisIndicesStyle end

"""
    IntervalCollection

A subtype of `AxisIndicesStyle` for mapping an interval argument (`start..stop`)
from keys within said interval to a collection of indices.
"""
struct IntervalCollection <: AxisIndicesStyle end

"""
    KeysIn

A subtype of `AxisIndicesStyle` for mapping all keys given `in(keys)` to a collection
of indices.
"""
struct KeysIn <: AxisIndicesStyle end

"""
    KeyEquals

A subtype of `AxisIndicesStyle` for mapping a single key in a `isequal(key)` argument
to a single index.
"""
struct KeyEquals <: AxisIndicesStyle end
is_element(::Type{KeyEquals}) = true

"""
    KeysFix2

A subtype of `AxisIndicesStyle` for mapping all keys from fixed argument (e.g., `>(key)`)
to the corresponding collection of indices.
"""
struct KeysFix2 <: AxisIndicesStyle end

"""
    SliceCollection

A subtype of `AxisIndicesStyle` indicating that the entire axis should be propagated.
"""
struct SliceCollection <: AxisIndicesStyle end
is_index(::Type{SliceCollection}) = true

# we throw `axis` in there in case someone want's to change the default
@inline AxisIndicesStyle(::A, ::T) where {A, T} = AxisIndicesStyle(A, T)

AxisIndicesStyle(::Type{A}, ::Type{T}) where {A,T} = AxisIndicesStyle(T)

# Element
AxisIndicesStyle(::Type{T}) where {T} = KeyElement()
AxisIndicesStyle(::Type{<:Integer}) = IndexElement()
AxisIndicesStyle(::Type{Bool}) = BoolElement()
AxisIndicesStyle(::Type{CartesianIndex{1}}) = CartesianElement()

# Collections
AxisIndicesStyle(::Type{<:AbstractArray{T}}) where {T} = KeysCollection()
AxisIndicesStyle(::Type{<:AbstractArray{<:Integer}}) = IndicesCollection()
AxisIndicesStyle(::Type{<:AbstractArray{Bool}}) = BoolsCollection()
AxisIndicesStyle(::Type{<:Interval}) = IntervalCollection()

# Functions
AxisIndicesStyle(::Type{<:IsApproxFix}) = KeyEquals()
AxisIndicesStyle(::Type{<:Fix2{<:Union{typeof(isequal),typeof(==)}}}) = KeyEquals()
AxisIndicesStyle(::Type{<:Fix2{typeof(in)}}) = KeysIn()
AxisIndicesStyle(::Type{<:Fix2}) = KeysFix2()
AxisIndicesStyle(::Type{<:StaticRanges.ChainedFix}) = KeysFix2()
AxisIndicesStyle(::Type{Colon}) = SliceCollection()
AxisIndicesStyle(::Type{<:Base.Slice}) = SliceCollection()

end
