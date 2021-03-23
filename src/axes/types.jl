
"""
    SimpleAxis(v)

Povides an `AbstractAxis` interface for any `AbstractUnitRange`, `v `. `v` will
be considered both the `values` and `keys` of the return instance. 

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
"""
struct SimpleAxis{P} <: AbstractAxis{P}
    parent::P

    SimpleAxis{DynamicAxis}(x::DynamicAxis) = new{DynamicAxis}(x)
    function SimpleAxis{OptionallyStaticUnitRange{F,L}}(x::OptionallyStaticUnitRange{F,L}) where {F,L}
        return new{OptionallyStaticUnitRange{F,L}}(x)
    end
    SimpleAxis{P}(x::AbstractUnitRange) where {P} = SimpleAxis{P}(convert(P, x))

    SimpleAxis(x::DynamicAxis) = new{DynamicAxis}(x)
    SimpleAxis(x::OptionallyStaticUnitRange) = SimpleAxis{typeof(x)}(x)
    SimpleAxis(x) = SimpleAxis(OptionallyStaticUnitRange(x))

    """
        SimpleAxis(start::Integer, stop::Integer) -> SimpleAxis{UnitRange{Integer}}

    Passes `start` and `stop` arguments to `UnitRange` to construct the values of `SimpleAxis`.

    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> SimpleAxis(1, 10)
    SimpleAxis(1:10)
    ```
    """
    SimpleAxis(start::Integer, stop::Integer) = SimpleAxis(start:stop)

    """
        SimpleAxis(stop::Integer) -> SimpleAxis{Base.OneTo{Integer}}

    Passes `stop` `Base.OneTo` to construct the values of `SimpleAxis`.

    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> SimpleAxis(10)
    SimpleAxis(Base.OneTo(10))
    ```
    """
    SimpleAxis(stop::Integer) = SimpleAxis(StaticInt(1):stop)
end

const OneToAxis = SimpleAxis{OptionallyStaticUnitRange{StaticInt{1},Int}}
const MutableAxis = SimpleAxis{DynamicAxis}
const StaticAxis{N} = SimpleAxis{OptionallyStaticUnitRange{StaticInt{1},StaticInt{N}}}



"""
    Axis(k[, v=OneTo(length(k))])

Subtypes of `AbstractAxis` that maps keys to values. The first argument specifies
the keys and the second specifies the values. If only one argument is specified
then the values span from 1 to the length of `k`.

## Examples

The value for all of these is the same.
```jldoctest axis_examples
julia> using AxisIndices

julia> x = Axis(2.0:11.0)  # when only one argument is specified assume it's the keys
Axis(2.0:1.0:11.0 => SimpleAxis(1:10))

julia> y = Axis(1:10)
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
struct Axis{K,P} <: AbstractAxis{P}
    keys::K
    parent::P

    global _Axis(k::K, p::AbstractAxis) where {K} = new{K,typeof(p)}(k, p)
end
const KeyedAxis{K,P} = Axis{K,P}

"""
    StructAxis{T}

An axis that uses a structure `T` to form its keys.
"""
struct StructAxis{T,P} <: AbstractAxis{P}
    parent::P

    global _StructAxis(::Type{T}, p::P) where {T,P} = new{T,P}(p)

    function StructAxis{T,P}(p::P) where {T,P}
        if typeof(T) <: DataType
            return new{T,P}(p)
        else
            throw(ArgumentError("Type must be have all field fully paramterized, got $T"))
        end
    end

    function StructAxis{T}(inds::AbstractAxis) where {T}
        fc = _fieldcount(T)
        if known_length(inds) === fc
            return StructAxis{T,typeof(inds)}(inds)
        else
            if known_first(inds) === nothing
                throw(ArgumentError("StructAxis cannot have a parent type whose first index and last index are not known at compile time."))
            else
                f = static_first(inds)
                l = f + StaticInt(fc) - One()
                return StructAxis{T}(unsafe_reconstruct(inds, f:l))
            end
        end
    end
    StructAxis{T}(inds) where {T} = StructAxis{T}(compose_axis(inds))
    function StructAxis{T}() where {T}
        inds = SimpleAxis(One():StaticInt{_fieldcount(T)}())
        return new{T,typeof(inds)}(inds)
    end
end

"""
    OffsetAxis(keys::AbstractUnitRange{<:Integer}, parent::AbstractUnitRange{<:Integer})
    OffsetAxis(offset::Integer, parent::AbstractUnitRange{<:Integer})

An axis that has the indexing behavior of an [`AbstractOffsetAxis`](@ref) and retains an
offset from its underlying indices in its keys. Note that `offset` is only the offset from
the parent indices. If `OffsetAxis` is part of an `AxisArray`, the number returned by
`ArrayInterface.offsets` refers to the offset from zero, not the offset found in this axis.

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
struct OffsetAxis{O,P} <: AbstractOffsetAxis{O,P}
    offset::O
    parent::P

    global _OffsetAxis(offset::O, parent::P) where {O,P} = new{O,P}(offset, parent)
end

"""
    CenteredAxis(origin=0, indices)

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
struct CenteredAxis{O<:Integer,P} <: AbstractOffsetAxis{O,P}
    origin::O
    parent::P

    global _CenteredAxis(origin::O, parent::P) where {O,P} = new{O,P}(origin, parent)
end

struct PaddedAxis{I<:PadsParameter,P} <: AbstractAxis{P}
    pads::I
    parent::P

    global _PaddedAxis(i::I, p::P) where {I,P} = new{I,P}(i, p)
end
