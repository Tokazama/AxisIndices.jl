
"""
    AxisParameter

Supertype for parameters that initialize construction of an axis.
"""
abstract type AxisParameter <: Function end

struct Pads{F,L}
    first_pad::F
    last_pad::L

    global _Pads(f::F, l::L) where {F,L} = new{F,L}(f, l)
    function Pads(f, l)
        f < 0 && error("pads must be greater zero, got $f for first pad")
        l < 0 && error("pads must be greater zero, got $f for last pad")
        _Pads(int(f), int(l))
    end

    function Pads(; first_pad=Zero(), last_pad=Zero(), sym_pad=nothing)
        if sym_pad === nothing
            return Pads(first_pad, last_pad)
        else
            return Pads(sym_pad, sym_pad)
        end
    end
end

abstract type AxisPads{F,L} <: AxisParameter end

abstract type FillPads{F,L} <: AxisPads{F,L} end

(p::AxisPads)(x::AbstractAxis) = (check_pads(p, first(x), last(x)); _Axis(p, x))

(::Type{T})(args...) where {T<:AxisPads} = T(Pads(args...))
(::Type{T})(; kwargs...) where {T<:AxisPads} = T(Pads(; kwargs...))

"""
    ZeroPads(first_pad, last_pad)

The border elements return `zero(eltype(A))`.
"""
struct ZeroPads{F,L} <: FillPads{F,L}
    pads::Pads{F,L}
end

"""
    OnePads(first_pad, last_pad)

The border elements return `oneunit(eltype(A))`, where `A` is the parent array being padded.
""" 
struct OnePads{F,L} <: FillPads{F,L}
    pads::Pads{F,L}
end

"""
    SymmetricPads(first_pad, last_pad)

The border elements reflect relative to a position between elements. That is, the
border pixel is omitted when mirroring.

```math
\\boxed{
\\begin{array}{l|c|r}
  e\\, d\\, c\\, b  &  a \\, b \\, c \\, d \\, e \\, f & e \\, d \\, c \\, b
\\end{array}
}
```
"""
struct SymmetricPads{F,L} <: AxisPads{F,L}
    pads::Pads{F,L}
end

"""
    ReplicatePads(first_pad, last_pad)

The border elements extend beyond the image boundaries.

```math
\\boxed{
\\begin{array}{l|c|r}
  a\\, a\\, a\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, f \\, f \\, f
\\end{array}
}
```
"""
struct ReplicatePads{F,L} <: AxisPads{F,L}
    pads::Pads{F,L}
end

"""
    CircularPads(first_pad, last_pad)

The border elements wrap around. For instance, indexing beyond the left border
returns values starting from the right border.

```math
\\boxed{
\\begin{array}{l|c|r}
  c\\, d\\, e\\, f  &  a \\, b \\, c \\, d \\, e \\, f & a \\, b \\, c \\, d
\\end{array}
}
```
""" CircularPads
struct CircularPads{F,L} <: AxisPads{F,L}
    pads::Pads{F,L}
end

"""
    ReflectPads(first_pad, last_pad)

The border elements reflect relative to the edge itself.

```math
\\boxed{
\\begin{array}{l|c|r}
  d\\, c\\, b\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, e \\, d \\, c
\\end{array}
}
```
"""
struct ReflectPads{F,L} <: AxisPads{F,L}
    pads::Pads{F,L}
end

"""
    SimpleAxis(x)

Povides an `AbstractAxis` interface for any `AbstractUnitRange`, `x `.

## Examples

A `SimpleAxis` is useful for giving a standard set of indices the ability to use
the filtering syntax for indexing.
```jldoctest
julia> using AxisIndices, StaticRanges

julia> x = SimpleAxis(2:10)
SimpleAxis(2:10)

julia> x[2]
2

julia> x[==(2)]
2

julia> x[2] == x[==(2)]  # keys and values are same
true

julia> x[>(2)]
SimpleAxis(3:10)

julia> x[>(2)]
SimpleAxis(3:10)

julia> x[1]
ERROR: BoundsError: attempt to access SimpleAxis(2:10) at index [1]
[...]
```

---

    SimpleAxis(start::Integer, stop::Integer) -> SimpleAxis{UnitRange{Integer}}


Constructs a `SimpleAxis` starting at `start` and ending at `stop`.

## Examples
```jldoctest
julia> using AxisIndices

julia> SimpleAxis(1, 10)
SimpleAxis(1:10)
```

---

    SimpleAxis(stop::Integer) -> SimpleAxis{Base.OneTo{Integer}}

Constructs a `SimpleAxis` starting at `1` and ending at `stop`.

## Examples
```jldoctest
julia> using AxisIndices

julia> SimpleAxis(10)
SimpleAxis(static(1):10)

```
"""
struct SimpleParam <: AxisParameter end

const SimpleAxis = SimpleParam()

################
### AxisName ###
################
"""
    AxisName(name)

A subtype of `AxisParameter` for attaching a name to an axis.
"""
struct AxisName{S} <: AxisParameter
    name::StaticSymbol{S}

    AxisName{S}(x::StaticSymbol{S}) where {S} = new{S}(x)
    AxisName{S}() where {S} = AxisName{S}(StaticSymbol(S))
    AxisName(x::StaticSymbol{S}) where {S} = AxisName{S}(x)
    AxisName(x) = AxisName(StaticSymbol(x))
end

## has_name ##
has_name(x) = has_name(typeof(x))
has_name(::Type{Axis{P,A}}) where {P,A} = has_name(A)
has_name(::Type{Axis{AxisName{name},A}}) where {name,A} = static(true)
has_name(::Type{T}) where {T} = static(false)

## unname ##
unname(a) = _unname(has_name(a), a)
_unname(::False, a) = a
_unname(::True, a) = __unname(param(x), parent(a))
__unname(p::AxisName, a) = a
__unname(p, a) = unsafe_initialize(p, unname(a))

## strip_name ##
strip_name(a) = _strip_name(has_name(a), a)
_strip_name(::False, a) = static(:_), a
_strip_name(::True, a) = __strip_name(param(x), parent(a))
__strip_name(p::AxisName, a) = param(p), a
function __strip_name(p, a)
    name, paxis = strip_name(a)
    return name, unsafe_initialize(p, paxis)
end

"""
    AxisKeys(keys)

Subtypes of `AxisParameter` that maps keys to values.

## Examples

The value for all of these is the same.
```jldoctest axis_examples
julia> using AxisIndices: KeyedAxis

julia> x = KeyedAxis(2.0:11.0)  # when only one argument is specified assume it's the keys
Axis(2.0:1.0:11.0 => SimpleAxis(1:10))

julia> y = KeyedAxis(1:10)
Axis(1:10 => SimpleAxis(1:10))
```

Standard indexing returns the same values
```jldoctest axis_examples
julia> x[2]
2

julia> x[2] == y[2]
true

julia> x[1:2]
Axis(2.0:1.0:3.0 => SimpleAxis(1:2))

julia> y[1:2]
Axis(1:2 => SimpleAxis(1:2))

julia> x[1:2] == y[1:2]
true
```

Functions that return `true` or `false` may be used to search the keys for their
corresponding index. The following is equivalent to the previous example.
```julia
julia> x[==(3.0)]
2

julia> x[3.0] ==  # 3.0 is the 2nd key of x
       y[==(2)]   # 2 is the 2nd key of z
true

julia> x[<(4.0)]  # all keys less than 4.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => SimpleAxis(1:2))

julia> y[<=(3.0)]  # all keys less than or equal to 3.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => SimpleAxis(1:2))

julia> z[<(3)]  # all keys less than or equal to 3 are 1:2 which correspond to values 1:2
Axis(1:2 => SimpleAxis(1:2))

julia> x[<(4.0)] == y[<=(3.0)] == z[<(3)]
true
```
Notice that `==` returns a single value instead of a collection of all elements
where the key was found to be true. This is because all keys must be unique so
there can only ever be one element returned.
"""
struct AxisKeys{K} <: AxisParameter
    keys::K

    global _AxisKeys(k::K) where {K} = new{K}(k)
    function AxisKeys(k::K) where {K}
        allunique(ks) || error("All keys must be unique, got $k")
        return new{K}(k)
    end
end

"""
    AxisStruct{T}()

An axis that uses a structure `T` to form its keys.
"""
struct AxisStruct{T} <: AxisParameter

    global _AxisStruct(::Type{T}) where {T} = new{T}()
    function AxisStruct{T}() where {T}
        if typeof(T) <: DataType
            return new{T}()
        else
            throw(ArgumentError("Type must be have all field fully paramterized, got $T"))
        end
    end
end

################
### Metadata ###
################
"""
    AxisMetadata(m)

A subtype of `AxisParameter` for attaching metadata `m` to an axis.

See also: [`AxisIndices.AxisParameter`](@ref), [`Metadata.metadata`](@ref), [`Metadata.metadata!`](@ref)
"""
struct AxisMetadata{M} <: AxisParameter
    metadata::M
end

const MetaAxis{M,P} = Axis{AxisMetadata{M},P}

Metadata.attach_metadata(a::AbstractUnitRange{Int}, m=Metadata.MDict()) = AxisMetadata(m)(a)

Metadata.metadata(x::Axis) = _meta(param(x), parent(x))
_meta(p, a) = metadata(a)
_meta(p::AxisMetadata, a) = param(p)

@inline Base.getproperty(a::Axis, k::Symbol) = metadata(a, k)
@inline Base.setproperty!(a::Axis, k::Symbol, val) = metadata!(a, k, val)

Base.propertynames(a::Axis) = _property_names(param(a), parent(a))
_property_names(p::AxisMetadata, a) = keys(param(p))
_property_names(p, a) = propertynames(a)


"""
    AxisOrigin(::Integer)
    AxisOrigin() -> AxisOrigin(static(0))

A `CenteredAxis` takes `indices` and provides a user facing set of keys centered around zero.
The `CenteredAxis` is a subtype of `AbstractOffsetAxis` and its keys are treated as the predominant indexing style.
Note that the element type of a `CenteredAxis` cannot be unsigned because any instance with a length greater than 1 will begin at a negative value.

## Examples

A `CenteredAxis` sends all indexing arguments to the keys and only maps to the indices when `to_index` is called.
```jldoctest
julia> using AxisIndices

julia> axis = AxisIndices.CenteredAxis(1:10)
center(0)(SimpleAxis(1:10))

julia> axis[10]  # the indexing goes straight to keys and is centered around zero
ERROR: BoundsError: attempt to access center(0)(SimpleAxis(1:10)) at index [10]
[...]

julia> axis[-4]
-4

```
"""
struct AxisOrigin{O} <: AxisParameter
    origin::O

    AxisOrigin{Int}(x) = new{Int}(x)
    AxisOrigin{StaticInt{O}}(x) where {O} = new{StaticInt{O}}(x)
    AxisOrigin(x::Int) = new{Int}(x)
    AxisOrigin(x::StaticInt) = new{typeof(x)}(x)
    AxisOrigin() = AxisOrigin(static(0))
end

"""
    AxisOffset(::Integer)

## Examples

Users may construct an `OffsetAxis` by providing an from a set of indices.
```jldoctest offset_axis_examples
julia> using AxisIndices

julia> axis = AxisIndices.OffsetAxis(-2, 1:3)
offset(-2)(SimpleAxis(1:3))

```

In this instance the first index of the wrapped indices is 1 (`firstindex(indices(axis))`)
but adding the offset (`-2`) moves it to `-1`.
```jldoctest offset_axis_examples
julia> firstindex(axis)
-1

julia> axis[-1]
-1
```

Similarly, the last index is move by `-2`.
```jldoctest offset_axis_examples
julia> lastindex(axis)
1

julia> axis[1]
1

```

This means that traditional one based indexing no longer applies and may result in
errors.
```jldoctest offset_axis_examples
julia> axis[3]
ERROR: BoundsError: attempt to access offset(-2)(SimpleAxis(1:3)) at index [3]
[...]
```

When an `OffsetAxis` is reconstructed the offset from indices are presserved.
```jldoctest offset_axis_examples
julia> axis[0:1]  # offset of -2 still applies
offset(-2)(SimpleAxis(2:3))

```
"""
struct AxisOffset{O} <: AxisParameter
    offset::O

    AxisOffset{Int}(x) = new{Int}(x)
    AxisOffset{StaticInt{O}}(x) where {O} = new{StaticInt{O}}(x)
    AxisOffset(x::Int) = new{Int}(x)
    AxisOffset(x::StaticInt) = new{typeof(x)}(x)
end

## param ##
param(x::Axis) = getfield(x, :param)
param(x::AxisKeys) = getfield(x, :keys)
param(x::AxisOrigin) = getfield(x, :origin)
param(x::AxisOffset) = getfield(x, :offset)
param(x::AxisName) = getfield(x, :name)
param(x::AxisPads) = getfield(x, :pads)
param(x::AxisMetadata) = getfield(x, :metadata)

###############
### offsets ###
###############
## has_offset ##
has_offset(x) = has_offset(typeof(x))
has_offset(::Type{DynamicAxis}) = static(false)
has_offset(::Type{OptionallyStaticUnitRange{F,L}}) where {F,L} = static(false)
has_offset(::Type{Axis{AxisOrigin{O},A}}) where {O,A} = static(true)
has_offset(::Type{Axis{AxisOffset{O},A}}) where {O,A} = static(true)
has_offset(::Type{Axis{P,A}}) where {P,A} = has_offset(A)
has_offset(::Type{T}) where {T} = _has_offset(nstatic(Val(ndims(T))), T)
function _has_offset(dims::Tuple{StaticInt{N},Vararg{Any}}, ::Type{T}) where {N,T}
    return _has_offset(has_(axes_types(T, static(N))), tail(dims), T)
end
function _has_offset(dims::Tuple{StaticInt{N}}, ::Type{T}) where {N,T}
    return has_offset(axes_types(T, static(N)))
end
_has_offset(::False, dims::Tuple, ::Type{T}) where {T} = _has_offset(dims, T)
_has_offset(::True, dims::Tuple, ::Type{T}) where {T} = static(true)

## strip_offset - return offset and instance of x stripped of offset ##
strip_offset(a::Axis) = _strip_offset(has_offset(a), a)
_strip_offset(::False, a) = nothing, a
_strip_offset(::True, a::Axis) = __strip_offset(param(a), parent(a))
__strip_offset(p::AxisOffset, a) = p, a
__strip_offset(p::AxisOrigin, a) = p, a
function __strip_offset(p, a)
    offset, paxis = __strip_offset(param(a), parent(a))
    return offset, _initialize(p, paxis)
end

# TODO see if this can be replaced/simplified
_maybe_offset(::Nothing, ::Any) = nothing
_maybe_offset(odiff::Int, x::Axis) = OffsetAxis(odiff, x)
_maybe_offset(odiff::Int, x::AbstractVector) = _AxisArray(x, (OffsetAxis(odiff, axes(x, 1)),))
_maybe_offset(odiff::Zero, x::Axis) = x
_maybe_offset(odiff::Zero, x::AbstractVector) = x
_maybe_offset(odiff::StaticInt{O}, x::Axis) where {O} = OffsetAxis(odiff, x)
function _maybe_offset(odiff::StaticInt{O}, x::AbstractVector) where {O}
    return _AxisArray(x, (OffsetAxis(odiff, axes(x, 1)),))
end

## drop_offset(x) - return instance of x without an offset ##
drop_offset(x) = _drop_offset(has_offset(x), x)
_drop_offset(::False, a) = a
_drop_offset(::True, a) = _AxisArray(parent(x), map(drop_offset, axes(x)))
_drop_offset(::True, a::Axis) = __drop_offset(param(a), parent(a))
__drop_offset(::AxisOffset, a) = a
__drop_offset(::AxisOrigin, a) = a
__drop_offset(p, a) = _initialize(p, __drop_offset(param(a), parent(a)))

############
### keys ### FIXME
############
function Base.keys(p::AxisStruct{T}) where {T}
    return _AxisArray(Symbol[fieldnames(T)...], (SimpleAxis(static(nfields(T))),))
end

Base.keys(axis::Axis) = _keys(has_keys(axis), axis)
_keys(::False, axis) = eachindex(axis)
function _keys(::True, axis)
    pds, k = __keys(param(axis), parent(axis))
    return _offset_keys(static_first(axis), _maybe_pad(pds, k))
end
__keys(p, axis) = __keys(param(axis), parent(axis))
__keys(p::AxisPads, axis) = (last(__keys(param(axis), parent(axis))), k)
__keys(p::AxisKeys, axis) = nothing, param(p)
function __keys(::AxisStruct{NamedTuple{L,T}}, axis) where {L,T}
    return (nothing, _AxisArray(Symbol[L...], (SimpleAxis(static_length(L)),)))
end
function __keys(::AxisStruct{T}, axis) where {T}
    if isdefined(T, :names)
        k = _AxisArray(Symbol[T.names...], (SimpleAxis(static_length(nfields(T))),))
    else
        k = _AxisArray(Symbol[T.name.ames...], (SimpleAxis(static_length(nfields(T))),))
    end
    return (nothing, k)
end

_offset_keys(::StaticInt{0}, k::AbstractVector) = k
function _offset_keys(o::StaticInt{O}, k::AbstractVector) where {O}
    return _AxisArray(k, (initialize(AxisOrigin(o), SimpleAxis(eachindex(k))),))
end
function _offset_keys(o::Int, k::AbstractVector)
    return _AxisArray(k, (initialize(AxisOrigin(o), SimpleAxis(eachindex(k))),))
end

_maybe_pad(::Nothing, v::AbstractVector) = v
_maybe_pad(x::Pads, v::AbstractVector) = _maybe_pad(_maybe_pad(first_pad(x), v), last_pad(x))

_maybe_pad(x::Int,          v::AbstractVector) = LazyVCat(static(1):x, v)
_maybe_pad(x::StaticInt{N}, v::AbstractVector) where {N} = LazyVCat(static(1):x, v)
_maybe_pad(::StaticInt{0},  v::AbstractVector) = v

_maybe_pad(v::AbstractVector, x::Int) = LazyVCat(v, static(1):x)
_maybe_pad(v::AbstractVector, x::StaticInt{N}) where {N} = LazyVCat(v, static(1):x)
_maybe_pad(v::AbstractVector, ::StaticInt{0}) = v

## keytype ##
Base.keytype(::Type{Axis{P,A}}) where {P,A} = keytype(A)
Base.keytype(::Type{Axis{AxisStruct{T},A}}) where {T,A} = Symbol
Base.keytype(::Type{Axis{AxisKeys{T},A}}) where {T,A} = eltype(T)

## keys_type(::Type{T}) - returns the type of keys collection for `T` ##
#= FIXME
keys_type(::Type{Axis{AxisKeys{T},A}}) where {T,A} = K
keys_type(::Type{Axis{P,A}}) where {P,A} = _keys_type(has_keys(A), A)
_keys_type(::True, ::Type{A}) where {A} = keys_type(A)

keys_type(::Type{Axis{K,P}}) where {K,P} = K
function keys_type(::Type{Axis{AxisStruct{T},P}}) where {T,P}
    return AxisArray{Symbol,1,Vector{Symbol},Tuple{SimpleAxis{UnitSRange{1,known_length(T)}}}}
end
keys_type(::Type{MutableAxis}) = OptionallyStaticUnitRange{StaticInt{1},Int}
keys_type(::Type{OneToAxis}) = OptionallyStaticUnitRange{StaticInt{1},Int}
keys_type(::Type{StaticAxis{L}}) where {L} = UnitSRange{1,L}
keys_type(::Type{T}) where {T<:AbstractAxis} = _keys_type(has_offset(T), T)
keys_type(::False, ::Type{T}) where {T} = keys_type(parent_type(T))
function keys_type(::True, ::Type{T}) where {T}
    return _offset_keys_type(known_offset1(T), keys_type(parent_type(T)))
end
_offset_keys_type(::Nothing, ::Type{T}) where {T}  = OffsetAxis{Int,T}
_offset_keys_type(::StaticInt{O}, ::Type{T}) where {O,T} = OffsetAxis{StaticInt{O},T}
=#

#= has_keys - do we have StructAxis or Axis in a parent field?=#
has_keys(x) = has_keys(typeof(x))
has_keys(::Type{DynamicAxis}) = static(false)
has_keys(::Type{OptionallyStaticUnitRange{F,L}}) where {F,L} = static(false)
has_keys(::Type{Axis{P,A}}) where {P,A} = has_keys(A)
has_keys(::Type{Axis{AxisStruct{T},A}}) where {T,A} = static(true)
has_keys(::Type{Axis{AxisKeys{T},A}}) where {T,A} = static(true)
has_keys(::Type{T}) where {T} = _has_keys(nstatic(Val(ndims(T))), T)
function _has_keys(dims::Tuple{StaticInt{N},Vararg{Any}}, ::Type{T}) where {N,T}
    return _has_keys(has_keys(axes_types(T, static(N))), tail(dims), T)
end
_has_keys(dims::Tuple{StaticInt{N}}, ::Type{T}) where {N,T} = has_keys(axes_types(T, static(N)))
_has_keys(::False, dims::Tuple, ::Type{T}) where {T} = _has_keys(dims, T)
_has_keys(::True, dims::Tuple, ::Type{T}) where {T} = static(true)


#= strip_keys(x) - return keys and instance of x stripped of keys =#
strip_keys(a::Axis) = _strip_keys(has_keys(a), a)
_strip_keys(::False, a) = nothing, a
_strip_keys(::True, a::Axis) = __strip_keys(param(a), parent(a))
__strip_keys(p::AxisKeys, a) = p, a
__strip_keys(p::AxisStruct, a) = p, a
function __strip_keys(p, a)
    offset, paxis = __strip_keys(param(a), parent(a))
    return offset, _initialize(p, paxis)
end

#= drop_keys(x) - return instance of x without keys =#
drop_keys(x) = _drop_keys(has_keys(x), x)
_drop_keys(::False, a) = a
_drop_keys(::True, a) = _AxisArray(parent(x), map(drop_keys, axes(x)))
_drop_keys(::True, a::Axis) = __drop_keys(param(a), parent(a))
__drop_keys(::AxisKeys, a) = a
__drop_keys(::AxisStruct, a) = a
__drop_keys(p, a) = _initialize(p, __drop_keys(param(a), parent(a)))

############
### Pads ###
############
## pads(x) ##
pads(axis::Axis) = _pads(param(axis), parent(axis))
pads(axis::AxisPads) = getfield(axis, :pads)
_pads(p::AxisPads, ::Axis) = pads(p)
_pads(::AxisParameter, axis::Axis) = pads(axis)
_pads(::AxisParameter, axis) = Pads(static(0), static(0))

## first_pad ##
first_pad(p::Pads) = getfield(p, :first_pad)
first_pad(p::AxisPads) = first_pad(pads(p))
first_pad(axis) = first_pad(pads(axis))

## last_pad =#
last_pad(p::Pads) = getfield(p, :last_pad)
last_pad(p::AxisPads) = last_pad(pads(p))
last_pad(axis) = last_pad(pads(axis))

## drop_pads(x) - return instance of x without an offset ##
drop_pads(x::Axis) = parent(x)
drop_pads(x) = _drop_offset(has_offset(x), x)
_drop_pads(::True, x::Axis) = initialize(x, param(x), drop_offset(parent(x)))
_drop_pads(::False, x::Axis) = x
_drop_pads(::True, x) = _AxisArray(parent(x), map(drop_offset, axes(x)))

## has_pads ##
has_pads(x) = has_pads(typeof(x))
has_pads(::Type{Axis{P,A}}) where {P,A} = has_pads(A)
has_pads(::Type{Axis{P,A}}) where {P<:AxisPads,A} = static(true)
has_pads(::Type{DynamicAxis}) = static(false)
has_pads(::Type{OptionallyStaticUnitRange{F,L}}) where {F,L} = static(false)
has_pads(::Type{T}) where {T} = _has_pads(nstatic(Val(ndims(T))), T)
function _has_pads(dims::Tuple{StaticInt{N},Vararg{Any}}, ::Type{T}) where {N,T}
    return _has_pads(has_pads(axes_types(T, static(N))), tail(dims), T)
end
function _has_pads(dims::Tuple{StaticInt{N}}, ::Type{T}) where {N,T}
    return has_pads(axes_types(T, static(N)))
end
_has_pads(::False, dims::Tuple, ::Type{T}) where {T} = _has_pads(dims, T)
_has_pads(::True, dims::Tuple, ::Type{T}) where {T} = static(true)

## strip_pads - return offset and instance of x stripped of offset ##
function strip_pads(x::Axis{<:AxisPads,A}) where {A}
    p = pads(x)
    return p, _grow_to_pads(p, parent(x))
end
strip_pads(x) = _strip_pads(has_pads(x), x)
function _strip_pads(::True, x)
    p, axis = strip_pads(parent(x))
    return p, initialize(param(x), axis)
end
_strip_pads(::False, x) = nothing, x

########################
### struct - methods ###
########################
has_struct(x) = has_struct(typeof(x))
has_struct(::Type{Axis{P,A}}) where {P,A} = has_struct(A)
has_struct(::Type{DynamicAxis}) = static(false)
has_struct(::Type{OptionallyStaticUnitRange{F,L}}) where {F,L} = static(false)
has_struct(::Type{Axis{AxisStruct{T},A}}) where {T,A} = static(true)
has_struct(::Type{T}) where {T} = Static.ne(structdim(T),static(0))

## structdim ##
structdim(x) = structdim(typeof(x))
function structdim(::Type{T}) where {T}
    return _structdim(has_struct(axes_types(T, static(N))), tail(dims), T)
end
function _structdim(dims::Tuple{StaticInt{N},Vararg{Any}}, ::Type{T}) where {N,T}
    dim_i = static(N)
    return _structdim(has_struct(axes_types(T, dim_i)), dim_i, tail(dims), T)
end
function _structdim(dims::Tuple{StaticInt{N}}, ::Type{T}) where {N,T}
    dim_i = static(N)
    return _structdim(has_struct(axes_types(T, dim_i)), dim_i)
end
_structdim(::False, dim_i::StaticInt{N}, dims::Tuple, ::Type{T}) where {N,T} = _structdim(dims, T)
_structdim(::True, dim_i::StaticInt{N}, dims::Tuple, ::Type{T}) where {N,T} = dim_i
_structdim(::False, dim_i::StaticInt{N}) where {N} = static(0)
_structdim(::True, dim_i::StaticInt{N}) where {N} = dim_i

"""
    struct_view(x)

Creates a `MappedArray` whose element type is derived from the first `AxisStruct` found as
an axis of `x`.
"""
struct_view(x) = _struct_view(x, structdim(x))
@inline function _struct_view(x, d)
    indicators = dims_indicators(d, nstatic(Val(ndims(x))))
    axis = axes(x, d)
    axs = _drop_axes(axes(x), indicators)
    data = _tuple_of_views(parent(x), static_first(axis), static_last(axis), indicators)
    return __struct_view(param(axis), data, axs)
end
function __struct_view(::AxisStruct{T}, data, axs) where {T}
    return _AxisArray(
        ReadonlyMultiMappedArray{T,ndims(first(data)),typeof(data),Type{T}}(T, data),
        axs
    )
end
function __struct_view(::AxisStruct{T}, data, axs) where {T<:NamedTuple}
    f = (args...) -> T(args)
    return _AxisArray(
        ReadonlyMultiMappedArray{T,ndims(first(data)),typeof(data),typeof(f)}(f, data),
        axs
    )
end

@inline function _tuple_of_views(x, start::StaticInt{L}, stop::StaticInt{L}, indicators::Tuple) where {L}
    return (view(x, _indicators_to_slices(indicators, start)...),)
end

@inline function _tuple_of_views(x, start::StaticInt{F}, stop::StaticInt{L}, indicators::Tuple) where {F,L}
    return (
        view(x, _indicators_to_slices(indicators, start)...),
        _tuple_of_views(x, _add1(start), stop, indicators)...
    )
end

@inline function _indicators_to_slices(x::Tuple{False,Vararg{Any}}, i::StaticInt{I}) where {I}
    return (:, _indicators_to_slices(tail(x), i)...)
end
@inline function _indicators_to_slices(x::Tuple{True,Vararg{Any}}, i::StaticInt{I}) where {I}
    return (i, _indicators_to_slices(tail(x), i)...)
end
_indicators_to_slices(x::Tuple{False}, i::StaticInt{I}) where {I} = (:,)
_indicators_to_slices(x::Tuple{True}, i::StaticInt{I}) where {I} = (i,)

