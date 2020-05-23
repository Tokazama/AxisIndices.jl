
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
    return to_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

@propagate_inbounds function to_index(axis, arg::Keys)
    return to_index(AxisIndicesStyle(axis, arg), axis, arg.x)
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
    return k2v(axis, mapping)
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
@inbounds(getindex(keys(axis), v2k(axis, index)))
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
    @boundscheck if !checkindex(Bool, values(axis), index)
        throw(BoundsError(axis, arg))
    end
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
    return k2v(axis, mapping)
end

"""
    IndicesCollection

A subtype of `AxisIndicesStyle` for propagating an argument to a collection of indices.
"""
struct IndicesCollection <: AxisIndicesStyle end

AxisIndicesStyle(::Type{<:AbstractArray{<:Integer}}) = IndicesCollection()

@inline function to_keys(::IndicesCollection, axis, arg, index)
    return @inbounds(getindex(keys(axis), v2k(axis, index)))
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
    return @inbounds(getindex(keys(axis), v2k(axis, index)))
end

function to_index(::IntervalCollection, axis, arg)
    mapping = findin(arg, keys(axis))
    return k2v(axis, mapping)
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
    return k2v(axis, mapping)
end

"""
    IndicesIn

A subtype of `AxisIndicesStyle` for mapping all keys given `in(keys)` to a collection
of indices.
"""
struct IndicesIn <: AxisIndicesStyle end

function to_keys(::IndicesIn, axis, arg, index)
    return @inbounds(getindex(keys(axis), v2k(axis, index)))
end

@propagate_inbounds function to_index(::IndicesIn, axis, arg)
    mapping = findin(arg.x, values(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return mapping
end

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
    return k2v(axis, mapping)
end

to_keys(::KeyEquals, axis, arg, index) = arg.x

"""
    IndexEquals

A subtype of `AxisIndicesStyle` for mapping a single index in a `isequal(index)` argument
to a single index.
"""
struct IndexEquals <: AxisIndicesStyle end

is_element(::Type{IndexEquals}) = true

@propagate_inbounds function to_index(::IndexEquals, axis, arg)
    @boundscheck if !checkbounds(Bool, values(axis), arg.x)
        throw(BoundsError(axis, arg.x))
    end
    return arg.x
end

function to_keys(::IndexEquals, axis, arg, index)
    return @inbounds(getindex(keys(axis), v2k(axis, index)))
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
    return @inbounds(getindex(keys(axis), v2k(axis, index)))
end

@inline to_index(::KeysFix2, axis, arg) = k2v(axis, find_all(arg, keys(axis)))

"""
    IndicesFix2

A subtype of `AxisIndicesStyle` for mapping all indices from fixed argument (e.g., `>(indices)`)
to the corresponding collection of indices.
"""
struct IndicesFix2 <: AxisIndicesStyle end

@inline function to_keys(::IndicesFix2, axis, arg, index)
    return @inbounds(getindex(keys(axis), v2k(axis, index)))
end

@inline to_index(::IndicesFix2, axis, arg) = find_all(arg, values(axis))

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

"""
    KeyedStyle{S}

A subtype of `AxisIndicesStyle` indicating that the axis is a always defaults to key based indexing.
"""
struct KeyedStyle{S} <: AxisIndicesStyle end

KeyedStyle(S::AxisIndicesStyle) = KeyedStyle{S}()
KeyedStyle(S::IndicesCollection) =  KeyedStyle{KeysCollection()}()
KeyedStyle(S::IndexElement) = KeyedStyle{KeyElement()}()

#function AxisIndicesStyle(::Type{<:AbstractOffsetAxis}, ::Type{T}) where {T}
#    return KeyedStyle(AxisIndicesStyle(T))
#end

is_element(::Type{KeyedStyle{T}}) where {T} = is_element(T)

to_index(::KeyedStyle{S}, axis, arg) where {S} = to_index(S, axis, arg)

to_keys(::KeyedStyle{S}, axis, arg, index) where {S} = to_keys(S, axis, arg, index)

# we throw `axis` in there in case someone want's to change the default
@inline AxisIndicesStyle(::A, ::T) where {A<:AbstractUnitRange, T} = AxisIndicesStyle(A, T)
AxisIndicesStyle(::Type{A}, ::Type{T}) where {A,T} = AxisIndicesStyle(T)

AxisIndicesStyle(::Type{Indices{T}}) where {T} = force_indices(AxisIndicesStyle(T))
force_indices(S::AxisIndicesStyle) = S
force_indices(::KeyEquals) = IndexEquals()
force_indices(::KeysFix2) = IndicesFix2()
force_indices(::KeysIn) = IndicesIn()

AxisIndicesStyle(::Type{Keys{T}}) where {T} = force_keys(AxisIndicesStyle(T))
force_keys(S::AxisIndicesStyle) = S
force_keys(S::IndicesCollection) = KeysCollection()
force_keys(S::IndexElement) = KeyElement()

###
### Combine traits
###
"""
    CombineStyle

Abstract type that determines the behavior of `broadcast_axis`, `cat_axis`, `append_axis!`.
"""
abstract type CombineStyle end

"""
    CombineAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractAxis`.
"""
struct CombineAxis <: CombineStyle end

"""
    CombineSimpleAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractSimpleAxis`.
"""
struct CombineSimpleAxis <: CombineStyle end

"""
    CombineResize

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
resizing a collection (as opposed to by concatenation or appending).
"""
struct CombineResize <: CombineStyle end

"""
    CombineStack

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
stacking elements in some whay (as opposed to resizing a collection).
"""
struct CombineStack <: CombineStyle end

CombineStyle(x, y...) = CombineStyle(CombineStyle(x), CombineStyle(y...))
CombineStyle(::T) where {T} = CombineStyle(T)
CombineStyle(::Type{T}) where {T} = CombineStack() # default
CombineStyle(::Type{T}) where {T<:AbstractAxis} = CombineAxis()
CombineStyle(::Type{T}) where {T<:AbstractSimpleAxis} = CombineSimpleAxis()
CombineStyle(::Type{T}) where {T<:AbstractRange} = CombineResize()
CombineStyle(::Type{T}) where {T<:LinearIndices{1}} = CombineResize()  # b/c it really is OneTo{Int}

CombineStyle(::CombineAxis, ::CombineStyle) = CombineAxis()
CombineStyle(::CombineStyle, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineSimpleAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineSimpleAxis) = CombineAxis()

CombineStyle(::CombineSimpleAxis, ::CombineStyle) = CombineSimpleAxis()
CombineStyle(::CombineStyle, ::CombineSimpleAxis) = CombineSimpleAxis()
CombineStyle(::CombineSimpleAxis, ::CombineSimpleAxis) = CombineSimpleAxis()

CombineStyle(x::CombineStyle, y::CombineStyle) = x

"""
    is_simple_axis(x) -> Bool

If `true` then `x` is an axis type where `keys(x) === values(x)`
"""
is_simple_axis(::T) where {T} = is_simple_axis(T)
is_simple_axis(::Type{T}) where {T} = false
is_simple_axis(::Type{T}) where {T<:AbstractSimpleAxis} = true

###
### offset axes
###
function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:AbstractUnitRange}
    return true
end

function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:OneToUnion}
    return false
end

Base.has_offset_axes(A::AbstractAxisIndices) = Base.has_offset_axes(parent(A))

# StaticRanges.has_offset_axes is taken care of by any array type that defines `axes_type`

# Staticness
for f in (:is_static, :is_fixed, :is_dynamic)
    @eval begin
        function StaticRanges.$f(::Type{<:AbstractSimpleAxis{V,Vs}}) where {V,Vs}
            return StaticRanges.$f(Vs)
        end
    end
end

for f in (:as_static, :as_fixed, :as_dynamic)
    @eval begin
        function StaticRanges.$f(x::AbstractSimpleAxis{V,Vs}) where {V,Vs}
            return unsafe_reconstruct(x, StaticRanges.$f(values(x)))
        end
    end
end

for f in (:is_static, :is_fixed, :is_dynamic)
    @eval begin
        function StaticRanges.$f(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs}
            return StaticRanges.$f(Vs) & StaticRanges.$f(Ks)
        end
    end
end

for f in (:as_static, :as_fixed, :as_dynamic)
    @eval begin
        function StaticRanges.$f(x::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
            return unsafe_reconstruct(x, StaticRanges.$f(keys(x)), StaticRanges.$f(values(x)))
        end
    end
end

