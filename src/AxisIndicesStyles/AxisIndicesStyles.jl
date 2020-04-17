module AxisIndicesStyles

using IntervalSets
using StaticRanges
using AxisIndices.AxisCore
using AxisIndices.AxisCore: _v2k, _k2v
using Base: @propagate_inbounds, tail, Fix2

export
    AxisIndicesStyle,
    # Traits
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
    is_key,
    to_index,
    to_keys

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
    to_keys([::AxisIndicesStyle,] axis, arg, index)

This method is the reverse of `AxisIndices.to_index`. `arg` refers to an argument
originally passed to `AxisIndices.to_index` and `index` refers to the index produced
by that same call to `AxisIndices.to_index`.

This method assumes to all arguments have passed through `AxisIndices.to_index` and
have been checked to be in bounds. Therefore, this is unsafe and intended only for
internal use.
"""
@inline to_keys(axis, arg, index) = to_keys(AxisIndicesStyle(axis, arg), axis, arg, index)

"""
    to_index(axis, arg) -> to_index(AxisIndicesStyle(axis, arg), axis, arg)

Unique implementation of `to_index` for the `AxisIndices` package that specializes
based on each axis and indexing argument (as opposed to the array and indexing argument).
"""
@propagate_inbounds function to_index(axis, arg)
    return to_index(AxisIndicesStyle(axis, arg), axis, arg)
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
    return _k2v(axis, mapping)
end
to_keys(::KeyElement, axis, arg, index) = arg

"""
    IndexElement

A subtype of `AxisIndicesStyle` for propagating an argument to a single index.
"""
struct IndexElement <: AxisIndicesStyle end

is_element(::Type{IndexElement}) = true

is_index(::Type{IndexElement}) = true

AxisIndicesStyle(::Type{<:Integer}) = IndexElement()

@propagate_inbounds function to_index(::IndexElement, axis, arg)
    @boundscheck if !checkbounds(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end

function to_keys(::IndexElement, axis, arg, index)
    return @inbounds(getindex(keys(axis), _v2k(axis, index)))
end

"""
    BoolElement

A subtype of `AxisIndicesStyle` for mapping an argument that refers to a single
`Bool` to a single index.
"""
struct BoolElement <: AxisIndicesStyle end

is_element(::Type{BoolElement}) = true

is_index(::Type{BoolElement}) = true

AxisIndicesStyle(::Type{Bool}) = BoolElement()

@propagate_inbounds function to_index(::BoolElement, axis, arg)
    return getindex(values(axis), arg)
end

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
    @boundscheck checkbounds(axis, index)
    return index
end

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
    return _k2v(axis, mapping)
end



"""
    IndicesCollection

A subtype of `AxisIndicesStyle` for propagating an argument to a collection of indices.
"""
struct IndicesCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{<:Integer}}) = IndicesCollection()

@inline function to_keys(::IndicesCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), _v2k(axis, index)))
end

# if we're referring to an element than we just need to know if it's inbounds
@propagate_inbounds function to_index(::IndicesCollection, axis, arg)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end

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

"""
    IntervalCollection

A subtype of `AxisIndicesStyle` for mapping an interval argument (`start..stop`)
from keys within said interval to a collection of indices.
"""
struct IntervalCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Interval}) = IntervalCollection()

@inline function to_keys(::IntervalCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), _v2k(axis, index)))
end

function to_index(::IntervalCollection, axis, arg)
    mapping = findin(arg, keys(axis))
    return _k2v(axis, mapping)
end

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
    return _k2v(axis, mapping)
end


"""
    KeyEquals

A subtype of `AxisIndicesStyle` for mapping a single key in a `isequal(key)` argument
to a single index.
"""
struct KeyEquals <: AxisIndicesStyle end

is_element(::Type{KeyEquals}) = true

AxisIndicesStyle(::Type{<:IsApproxFix}) = KeyEquals()

AxisIndicesStyle(::Type{<:Fix2{<:Union{typeof(isequal),typeof(==)}}}) = KeyEquals()

@propagate_inbounds function to_index(::KeyEquals, axis, arg)
    mapping = find_first(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return _k2v(axis, mapping)
end

"""
    KeysFix2

A subtype of `AxisIndicesStyle` for mapping all keys from fixed argument (e.g., `>(key)`)
to the corresponding collection of indices.
"""
struct KeysFix2 <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:Fix2}) = KeysFix2()

AxisIndicesStyle(::Type{<:StaticRanges.ChainedFix}) = KeysFix2()

@inline function to_keys(::KeysFix2, axis, arg, index)
    return @inbounds(getindex(keys(axis), _v2k(axis, index)))
end

@inline to_index(::KeysFix2, axis, arg) = _k2v(axis, find_all(arg, keys(axis)))

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

# we throw `axis` in there in case someone want's to change the default
@inline AxisIndicesStyle(::A, ::T) where {A<:AbstractUnitRange, T} = AxisIndicesStyle(A, T)
AxisIndicesStyle(::Type{A}, ::Type{T}) where {A,T} = AxisIndicesStyle(T)

end
