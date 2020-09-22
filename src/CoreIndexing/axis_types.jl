
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,I<:Integer} <: AbstractUnitRange{I} end

Base.valtype(::Type{T}) where {K,I,T<:AbstractAxis{K,I}} = I

Base.keytype(::Type{T}) where {K,I,T<:AbstractAxis{K,I}} = K

"""
    Axis(k[, v=OneTo(length(k))])

Subtypes of `AbstractAxis` that maps keys to values. The first argument specifies
the keys and the second specifies the values. If only one argument is specified
then the values span from 1 to the length of `k`.

## Examples

The value for all of these is the same.
```jldoctest axis_examples
julia> using AxisIndices

julia> x = Axis(2.0:11.0, 1:10)
Axis(2.0:1.0:11.0 => 1:10)

julia> y = Axis(2.0:11.0)  # when only one argument is specified assume it's the keys
Axis(2.0:1.0:11.0 => Base.OneTo(10))

julia> z = Axis(1:10)
Axis(1:10 => Base.OneTo(10))
```

Standard indexing returns the same values
```jldoctest axis_examples
julia> x[2]
2

julia> x[2] == y[2] == z[2]
true

julia> x[1:2]
Axis(2.0:1.0:3.0 => 1:2)

julia> y[1:2]
Axis(2.0:1.0:3.0 => 1:2)

julia> z[1:2]
Axis(1:2 => 1:2)

julia> x[1:2] == y[1:2] == z[1:2]
true
```

Functions that return `true` or `false` may be used to search the keys for their
corresponding index. The following is equivalent to the previous example.
```jldoctest axis_examples
julia> x[==(3.0)]
2

julia> x[==(3.0)] ==       # 3.0 is the 2nd key of x
       y[isequal(3.0)] ==  # 3.0 is the 2nd key of y
       z[==(2)]            # 2 is the 2nd key of z
true

julia> x[<(4.0)]  # all keys less than 4.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => 1:2)

julia> y[<=(3.0)]  # all keys less than or equal to 3.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => 1:2)

julia> z[<(3)]  # all keys less than or equal to 3 are 1:2 which correspond to values 1:2
Axis(1:2 => 1:2)

julia> x[<(4.0)] == y[<=(3.0)] == z[<(3)]
true
```
Notice that `==` returns a single value instead of a collection of all elements
where the key was found to be true. This is because all keys must be unique so
there can only ever be one element returned.
"""
struct Axis{K,I,Ks,Inds<:AbstractUnitRange{I}} <: AbstractAxis{K,I}
    keys::Ks
    parent_indices::Inds

    function Axis{K,I,Ks,Inds}(
        ks::Ks,
        inds::Inds,
        check_unique::Bool=true,
        check_length::Bool=true
    ) where {K,I,Ks<:AbstractVector{K},Inds<:AbstractUnitRange{I}}
        check_unique && check_axis_unique(ks, inds)
        check_length && check_axis_length(ks, inds)
        return new{K,I,Ks,Inds}(ks, inds)
    end

    function Axis{K,V,Ks,Vs}(x::AbstractUnitRange{<:Integer}) where {K,V,Ks,Vs}
        if x isa Ks
            if x isa Vs
                return Axis{K,V,Ks,Vs}(x, x)
            else
                return  Axis{K,V,Ks,Vs}(x, Vs(x))
            end
        else
            if x isa Vs
                return Axis{K,V,Ks,Vs}(Ks(x), x)
            else
                return  Axis{K,V,Ks,Vs}(Ks(x), Vs(x))
            end
        end
    end

    # Axis{K,I}
    function Axis{K,I}() where {K,I}
        return new{K,I,Vector{K},OneToMRange{I}}(Vector{K}(),OneToMRange{I}(0))
    end

    function Axis{K,I,Ks,Inds}(axis::AbstractAxis) where {K,I,Ks,Inds}
        return Axis{K,I,Ks,Inds}(Ks(keys(axis)), Inds(parentindices(axis)), false, false)
    end

    function Axis{K,I,Ks,Inds}(axis::Axis{K,I,Ks,Inds}) where {K,I,Ks,Inds}
        if can_change_size(axis)
            return copy(axis)
        else
            return axis
        end
    end

    function Axis(axis::AbstractAxis)
        if can_change_size(axis)
            return axis
        else
            return copy(axis)
        end
    end

    Axis{K}() where {K} = Axis{K,Int}()

    Axis() = Axis{Any}()

    Axis(x::Pair) = Axis(x.first, x.second)

    function Axis(ks, inds, check_unique::Bool=true, check_length::Bool=true)
        return Axis{eltype(ks),eltype(inds),typeof(ks),typeof(inds)}(ks, inds, check_unique, check_length)
    end

    function Axis(ks, check_unique::Bool=true)
        if can_change_size(ks)
            return Axis(ks, OneToMRange(length(ks)), check_unique, false)
        else
            len = known_length(ks)
            if len isa Nothing
                return return Axis(ks, OneTo(length(ks)), check_unique, false)
            else
                return Axis(ks, OneToSRange(len), false)
            end
        end
    end
end

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
ERROR: BoundsError: attempt to access 9-element SimpleAxis(2:10 => 2:10) at index [1]
[...]
```
"""
struct SimpleAxis{I,Inds<:AbstractUnitRange{I}} <: AbstractAxis{I,I}
    parent_indices::Inds

    function SimpleAxis{I,Inds}(inds::AbstractUnitRange) where {I,Inds}
        if inds isa Inds
            return new{I,Inds}(inds)
        else
            return SimpleAxis{I,Inds}(Inds(inds))
        end
    end

    SimpleAxis{I}(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I,typeof(inds)}(inds)

    SimpleAxis{I}(inds::AbstractUnitRange) where {I} = SimpleAxis{I}(AbstractUnitRange{I}(inds))

    SimpleAxis(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I}(inds)

    SimpleAxis() = new{Int,OneToMRange{Int}}(OneToMRange(0))

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
	SimpleAxis(stop::Integer) = SimpleAxis(OneTo(stop))
end

"""
    AbstractOffsetAxis{I,Ks,Inds}

Supertype for axes that begin indexing offset from one. All subtypes of `AbstractOffsetAxis`
use the keys for indexing and only convert to the underlying indices when
`to_index(::OffsetAxis, ::Integer)` is called (i.e. when indexing the an array
with an `AbstractOffsetAxis`. See [`OffsetAxis`](@ref), [`CenteredAxis`](@ref),
and [`IdentityAxis`](@ref) for more details and examples.
"""
abstract type AbstractOffsetAxis{I} <: AbstractAxis{I,I} end

"""
    CenteredAxis(indices)

A `CenteredAxis` takes `indices` and provides a user facing set of keys centered around zero.
The `CenteredAxis` is a subtype of `AbstractOffsetAxis` and its keys are treated as the predominant indexing style.
Note that the element type of a `CenteredAxis` cannot be unsigned because any instance with a length greater than 1 will begin at a negative value.

## Examples

A `CenteredAxis` sends all indexing arguments to the keys and only maps to the indices when `to_index` is called.
```jldoctest
julia> using AxisIndices

julia> axis = CenteredAxis(1:10)
CenteredAxis(-5:4 => 1:10)

julia> axis[10]  # the indexing goes straight to keys and is centered around zero
ERROR: BoundsError: attempt to access 10-element CenteredAxis(-5:4 => 1:10) at index [10]
[...]

julia> axis[-5]
-5

julia> AxisIndices.to_index(axis, -5)
1

```
"""
struct CenteredAxis{I,Inds} <: AbstractOffsetAxis{I}
    parent_indices::Inds

    function CenteredAxis{I,Inds}(inds::AbstractUnitRange) where {I,Inds}
        if inds isa Inds
            return new{I,Inds}(inds)
        else
            return CenteredAxis{I}(convert(Inds, inds))
        end
    end

    function CenteredAxis{I}(inds::AbstractUnitRange) where {I,Inds}
        if eltype(inds) <: I
            return new{I,typeof(inds)}(inds)
        else
            return CenteredAxis{I}(convert(AbstractUnitRange{I}, inds))
        end
    end

    CenteredAxis(inds::AbstractUnitRange{I}) where {I} = CenteredAxis{I}(inds)
end

"""
    IdentityAxis(start, stop) -> axis
    IdentityAxis(keys::AbstractUnitRange) -> axis
    IdentityAxis(keys::AbstractUnitRange, indices::AbstractUnitRange) -> axis


These are particularly useful for creating `view`s of arrays that
preserve the supplied axes:
```julia
julia> a = rand(8);

julia> v1 = view(a, 3:5);

julia> axes(v1, 1)
Base.OneTo(3)

julia> idr = IdentityAxis(3:5)
IdentityAxis(3:5 => Base.OneTo(3))

julia> v2 = view(a, idr);

julia> axes(v2, 1)
3:5
```
"""
struct IdentityAxis{I,F,Inds} <: AbstractOffsetAxis{I}
    offset::F
    parent_indices::Inds

    @inline function IdentityAxis{I,Ks,Inds}(
        ks::AbstractUnitRange,
        inds::AbstractUnitRange,
        check_length::Bool=true
    ) where {I,Ks,Inds}
        check_length && check_axis_length(ks, inds)
        if ks isa Ks
            if inds isa Inds
                check_length && check_axis_length(ks, inds)
                return new{I,Ks,Inds}(ks, inds)
            else
                return IdentityAxis{I}(ks, Inds(inds), check_length)
            end
        else
            if inds isa Inds
                return IdentityAxis{I}(Ks(ks), inds, check_length)
            else
                return IdentityAxis{I}(Ks(ks), Inds(inds), check_length)
            end
        end
    end

    function IdentityAxis{I}(ks::AbstractUnitRange{<:Integer}) where {I}
        return IdentityAxis{I}(ks, OneTo{I}(length(ks)), false)
    end

    function IdentityAxis{I}(start::Integer, stop::Integer) where {I}
        return IdentityAxis{I}(UnitRange{I}(start, stop))
    end

    function IdentityAxis{I}(
        ks::AbstractUnitRange{<:Integer},
        inds::AbstractUnitRange{<:Integer},
        check_length::Bool=true
    ) where {I}

        return IdentityAxis{I,typeof(ks),typeof(inds)}(ks, inds, check_length)
    end

    function IdentityAxis(
        ks::AbstractUnitRange{<:Integer},
        inds::AbstractUnitRange{<:Integer},
        check_length::Bool=true
    )

        return IdentityAxis{eltype(inds),typeof(ks),typeof(inds)}(ks, inds, check_length)
    end

    IdentityAxis(start::Integer, stop::Integer) = IdentityAxis(start:stop)

    function IdentityAxis(ks::Ks) where {Ks}
        if is_static(ks)
            return IdentityAxis(ks, OneToSRange(length(ks)))
        elseif is_fixed(ks)
            return IdentityAxis(ks, OneTo(length(ks)))
        else  # is_dynamic
            return IdentityAxis(ks, OneToMRange(length(ks)))
        end
    end
end

"""
    OffsetAxis(keys::AbstractUnitRange{<:Integer}, indices::AbstractUnitRange{<:Integer}[, check_length::Bool=true])
    OffsetAxis(offset::Integer, indices::AbstractUnitRange{<:Integer})

An axis that has the indexing behavior of an [`AbstractOffsetAxis`](@ref) and retains an
offset from its underlying indices in its keys.

## Examples

Users may construct an `OffsetAxis` by providing an from a set of indices.
```jldoctest offset_axis_examples
julia> using AxisIndices

julia> axis = OffsetAxis(-2, 1:3)
OffsetAxis(-1:1 => 1:3)
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
ERROR: BoundsError: attempt to access 3-element OffsetAxis(-1:1 => 1:3) at index [3]
[...]
```

When an `OffsetAxis` is reconstructed the offset from indices are presserved.
```jldoctest offset_axis_examples
julia> axis[0:1]  # offset of -2 still applies
OffsetAxis(0:1 => 2:3)

```
"""
struct OffsetAxis{I,F,Inds} <: AbstractOffsetAxis{I}
    offsets::F
    parent_indices::Inds

    function OffsetAxis{I,F,Inds}(f::Integer, inds::AbstractUnitRange) where {I,F,Inds}
        if f isa F
            if inds isa Inds
                return new{I,F,Inds}(f, inds)
            else
                return OffsetAxis{I,F,Inds}(f, Inds(inds))
            end
        else
            return OffsetAxis{I,F,Inds}(F(f), inds)
        end
        return OffsetAxis{I,F,Inds}(Ks(first(inds) + offset, last(inds) + offset), inds)
    end

    function OffsetAxis{I,F,Inds}(ks::AbstractUnitRange) where {I,F,Inds}
        f = static_first(ks)
        return OffsetAxis{I,F,Inds}(f - one(f), OptionallyStaticUnitRange(StaticInt(1), static_length(ks)))
    end

    # OffsetAxis{I,F}
    @inline function OffsetAxis{I,F}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I,F}
        return OffsetAxis{I,F}(static_first(ks) - static_first(inds), inds)
    end

    @inline function OffsetAxis{I,F}(ks::AbstractUnitRange) where {I,F}
        f = static_first(ks)
        return OffsetAxis{I}(f - one(f), OptionallyStaticUnitRange(StaticInt(1), static_length(ks)))
    end

    function OffsetAxis{I,F}(f::Integer, inds::AbstractUnitRange) where {I,F}
        if eltype(inds) <: I
            return new{I,F,typeof(inds)}(f, inds)
        else
            return OffsetAxis{I,F}(f, AbstractUnitRange{I}(inds))
        end
    end

    # OffsetAxis{I}
    function OffsetAxis{I}(f::Integer, inds::AbstractUnitRange) where {I}
        return OffsetAxis{I,typeof(f)}(f, inds)
    end
    @inline function OffsetAxis{I}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I}
        return OffsetAxis{I}(static_first(ks) - static_first(inds), inds)
    end
    @inline function OffsetAxis{I}(ks::AbstractUnitRange) where {I}
        f = static_first(ks)
        return OffsetAxis{I}(f - one(f), OptionallyStaticUnitRange(StaticInt(1), static_length(ks)))
    end

    # OffsetAxis
    function OffsetAxis(ks::AbstractUnitRange, inds::AbstractUnitRange)
        return OffsetAxis(static_first(ks) - static_first(inds), inds)
    end
    function OffsetAxis(ks::Ks) where {Ks}
        fst = static_first(ks)
        return OffsetAxis(fst - one(fst), OptionallyStaticUnitRange(StaticInt(1), static_length(ks)))
    end

    OffsetAxis(offset::Integer, inds::AbstractUnitRange) = OffsetAxis{eltype(inds)}(offset, inds)

    OffsetAxis(axis::OffsetAxis) = axis
end

struct PaddedAxis{P,FP,LP,I,Inds} <: AbstractOffsetAxis{I}
    pad::P
    first_pad::FP
    last_pad::LP
    parent_indices::Inds
end

# TODO figure out how to place type inference of each field into indexing
@generated _fieldcount(::Type{T}) where {T} = fieldcount(T)

"""
    StructAxis{T}

An axis that uses a structure `T` to form its keys. the field names of
"""
struct StructAxis{T,L,V,Inds} <: AbstractAxis{Symbol,V}
    parent_indices::Inds

    function StructAxis{T,L,V,Vs}(inds::Vs) where {T,L,V,Vs}
        # FIXME should unwrap_unionall be performed earlier?
        return new{T,L,V,Vs}(inds)
    end

    StructAxis{T}() where {T} = StructAxis{T,_fieldcount(T)}()

    StructAxis{T}(vs::AbstractUnitRange) where {T} = StructAxis{T,_fieldcount(T)}(vs)

    @inline StructAxis{T,L}() where {T,L} = StructAxis{T,L}(OneToSRange{Int,L}())

    function StructAxis{T,L}(inds::I) where {I<:AbstractUnitRange{<:Integer},T,L}
        if is_static(I)
            return StructAxis{T,L,eltype(I),I}(inds)
        else
            return StructAxis{T,L}(as_static(inds))
        end
    end
end

