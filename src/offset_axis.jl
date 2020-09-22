
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

julia> axis[-4]
-4

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

    function CenteredAxis{I}(inds::AbstractUnitRange) where {I}
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
struct IdentityAxis{I,F<:Integer,Inds} <: AbstractOffsetAxis{I}
    offsets::F
    parent_indices::Inds

    @inline function IdentityAxis{I,F,Inds}(f::Integer, inds::AbstractUnitRange) where {I,F,Inds}
        if f isa F
            if inds isa Inds
                return new{I,F,Inds}(f, inds)
            else
                return IdentityAxis{I}(f, Inds(inds))
            end
        else
            if inds isa Inds
                return IdentityAxis{I}(F(f), inds)
            else
                return IdentityAxis{I}(F(f), Inds(inds))
            end
        end
    end
    function IdentityAxis{I,F,Inds}(f::AbstractUnitRange, inds::AbstractUnitRange) where {I,F,Inds}
        return IdentityAxis{I,F,Inds}(static_first(ks) - static_first(inds), inds)
    end
    function IdentityAxis{I,F,Inds}(ks::AbstractUnitRange) where {I,F,Inds}
        if can_change_size(ks)
            inds = OneToMRange(length(ks))
        else
            inds = OneTo(static_length(ks))
        end
        f = static_first(ks) - one(F)
        return IdentityAxis{eltype(inds),typeof(f),typeof(inds)}(f, inds)
    end

    function IdentityAxis{I}(f::Integer, inds::AbstractUnitRange{<:Integer}) where {I}
        return IdentityAxis{I,typeof(f),typeof(inds)}(f, inds)
    end

    function IdentityAxis{I}(ks::AbstractUnitRange{<:Integer}) where {I}
        return IdentityAxis{I}(ks, OneTo{I}(length(ks)))
    end

    function IdentityAxis{I}(start::Integer, stop::Integer) where {I}
        return IdentityAxis{I}(UnitRange{I}(start, stop))
    end

    function IdentityAxis{I}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I}
        return IdentityAxis{I}(static_first(ks) - static_first(inds), inds)
    end
    function IdentityAxis(f::Integer, inds::AbstractUnitRange)
        return IdentityAxis{eltype(inds)}(f, inds)
    end

    function IdentityAxis(ks::AbstractUnitRange, inds::AbstractUnitRange)
        return IdentityAxis(static_first(ks) - static_first(inds), inds)
    end

    IdentityAxis(start::Integer, stop::Integer) = IdentityAxis(start:stop)

    function IdentityAxis(ks::Ks) where {Ks}
        if can_change_size(ks)
            inds = OneToMRange(length(ks))
        else
            inds = OneTo(static_length(ks))
        end
        f = static_first(ks)
        f = f - one(f)
        return new{eltype(inds),typeof(f),typeof(inds)}(f, inds)
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
        return OffsetAxis{I,F,Inds}(f - one(f), OneTo(static_length(ks)))
    end

    function OffsetAxis{I,F,Inds}(f::AbstractUnitRange, inds::AbstractUnitRange) where {I,F,Inds}
        return OffsetAxis{I,F,Inds}(static_first(f) - static_first(inds), inds)
    end

    # OffsetAxis{I,F}
    @inline function OffsetAxis{I,F}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I,F}
        return OffsetAxis{I,F}(static_first(ks) - static_first(inds), inds)
    end

    @inline function OffsetAxis{I,F}(ks::AbstractUnitRange) where {I,F}
        f = static_first(ks)
        return OffsetAxis{I}(f - one(f), OneTo(static_length(ks)))
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
        return OffsetAxis{I}(f - one(f), OneTo(static_length(ks)))
    end

    # OffsetAxis
    function OffsetAxis(ks::AbstractUnitRange, inds::AbstractUnitRange)
        return OffsetAxis(static_first(ks) - static_first(inds), inds)
    end
    function OffsetAxis(ks::Ks) where {Ks}
        fst = static_first(ks)
        return OffsetAxis(fst - one(fst), OneTo(static_length(ks)))
    end

    OffsetAxis(offset::Integer, inds::AbstractUnitRange) = OffsetAxis{eltype(inds)}(offset, inds)

    OffsetAxis(axis::OffsetAxis) = axis
end


_centered_first(::Nothing) = nothing
_centered_first(len::Integer) = -div(len, 2one(len))

_centered_last(::Nothing) = nothing
_centered_last(len::Integer) = -div(len, 2one(len)) + len - one(len)
_centered_offsets(::Nothing, stop::Integer) = nothing
_centered_offsets(::Nothing, stop::Nothing) = nothing
_centered_offsets(::Integer, stop::Nothing) = nothing
function _centered_offsets(start::Integer, stop::Integer)
    len = stop - start + one(stop)
    return -div(len, 2one(len)) - start
end

function known_offsets(::Type{T}) where {T<:AbstractUnitRange}
    if known_first(T) === nothing
        return nothing
    else
        f = known_first(T)
        return  f - one(f)
    end
end
known_offsets(::Type{T}) where {T<:AbstractAxis} = known_offsets(parent_type(T))
known_offsets(::Type{T}) where {F,T<:OffsetAxis{<:Any,StaticInt{F}}} = F
known_offsets(::Type{T}) where {T<:OffsetAxis{<:Any,<:Any}} = nothing
known_offsets(::Type{T}) where {F,T<:IdentityAxis{<:Any,StaticInt{F}}} = F
known_offsets(::Type{T}) where {T<:IdentityAxis{<:Any,<:Any}} = nothing
@inline function known_offsets(::Type{T}) where {T<:CenteredAxis}
    P = parent_type(T)
    if known_length(P) === nothing
        return nothing
    else
        return _centered_offsets(known_length(P))
    end
end

ArrayInterface.offsets(axis::AbstractAxis) = offsets(parentindices(axis))
ArrayInterface.offsets(axis::OffsetAxis) = getfield(axis, :offsets)
ArrayInterface.offsets(axis::IdentityAxis) = getfield(axis, :offsets)
function ArrayInterface.offsets(axis::CenteredAxis)
    p = parentindices(axis)
    return _centered_offsets(first(p), last(p))
end

@inline function ArrayInterface.known_first(::Type{T}) where {T<:AbstractOffsetAxis}
    if known_first(parent_type(T)) === nothing || known_offsets(T) === nothing
        return nothing
    else
        return known_first(parent_type(T)) + known_offsets(T)
    end
end

@inline function ArrayInterface.known_last(::Type{T}) where {T<:AbstractOffsetAxis}
    if known_last(parent_type(T)) === nothing || known_offsets(T) === nothing
        return nothing
    else
        return known_last(parent_type(T)) + known_offsets(T)
    end
end

Base.keys(axis::AbstractOffsetAxis) = eachindex(axis)
Base.last(axis::AbstractOffsetAxis) = last(parentindices(axis)) + offsets(axis)
Base.first(axis::AbstractOffsetAxis) = first(parentindices(axis)) .+ offsets(axis)

function ArrayInterface.known_first(::Type{T}) where {T<:CenteredAxis}
    return _centered_first(known_length(parent_type(T)))
end
function ArrayInterface.known_last(::Type{T}) where {T<:CenteredAxis}
    return _centered_last(known_length(parent_type(T)))
end

Base.first(axis::CenteredAxis) = _centered_first(static_length(axis))
Base.last(axis::CenteredAxis) = _centered_last(static_length(axis))


###
### Axis interface
###
"""
    IndexOffsetStyle

Index style where the user provided index must be offset before passing to internal
functions that return stored value.
"""
abstract type IndexOffsetStyle <: IndexStyle end

struct IndexOffset <: IndexOffsetStyle end

"""
    IndexCentered

Index style where the indices are centered around zero.
"""
struct IndexCentered <: IndexOffsetStyle end

# TODO document IndexIdentity
struct IndexIdentity <: IndexOffsetStyle end

@propagate_inbounds function to_index(S::IndexOffsetStyle, axis, arg::Integer)
    return to_index(parentindices(axis), arg - offsets(axis))
end

@propagate_inbounds function to_index(S::IndexOffsetStyle, axis, arg::AbstractArray{I}) where {I<:Integer}
    return to_index(parentindices(axis), arg .- offsets(axis))
end

Base.IndexStyle(::Type{T}) where {T<:OffsetAxis} = IndexOffset()
Base.IndexStyle(::Type{T}) where {T<:CenteredAxis} = IndexCentered()
Base.IndexStyle(::Type{T}) where {T<:IdentityAxis} = IndexIdentity()

Base.parentindices(axis::OffsetAxis) = getfield(axis, :parent_indices)
Base.parentindices(axis::CenteredAxis) = getfield(axis, :parent_indices)
Base.parentindices(axis::IdentityAxis) = getfield(axis, :parent_indices)

ArrayInterface.parent_type(::Type{T}) where {Inds,T<:CenteredAxis{<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:OffsetAxis{<:Any,<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:IdentityAxis{<:Any,<:Any,Inds}} = Inds

function unsafe_reconstruct(S::IndexOffsetStyle, axis, arg, inds)
    return unsafe_reconstruct(S, axis, inds)
end

unsafe_reconstruct(::IndexOffset, axis, inds) = OffsetAxis(offsets(axis), inds)
unsafe_reconstruct(::IndexIdentity, axis, inds) = IdentityAxis(offsets(axis), inds)
unsafe_reconstruct(::IndexCentered, axis, inds) = CenteredAxis(inds)

Base.eachindex(axis::AbstractOffsetAxis) = static_first(axis):static_last(axis)

