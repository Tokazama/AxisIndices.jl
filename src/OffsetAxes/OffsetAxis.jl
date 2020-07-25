# TODO OffsetAxis
# - impliment similar_type
# - implement constructors that use Val for static offset
# 

@inline function _construct_offset_keys(offset::T, inds::Tuple{Vararg{<:AbstractUnitRange{<:Integer}}}) where {T}
    if is_static(inds)
        return UnitSRange{T}(first(inds) + offset, last(inds) + offset)
    elseif is_fixed(inds)
        return UnitRange{T}(first(inds) + offset, last(inds) + offset)
    else
        return UnitMRange{T}(first(inds) + offset, last(inds) + offset)
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
struct OffsetAxis{I,Ks<:AbstractUnitRange{I},Inds} <: AbstractOffsetAxis{I,Ks,Inds}
    keys::Ks
    indices::Inds

    @inline function OffsetAxis{I,Ks,Inds}(
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
                return OffsetAxis{I}(ks, Inds(inds), check_length)
            end
        else
            if inds isa Inds
                return OffsetAxis{I}(Ks(ks), inds, check_length)
            else
                return OffsetAxis{I}(Ks(ks), Inds(inds), check_length)
            end
        end
    end

    function OffsetAxis{I,Ks,Inds}(axis::OffsetAxis) where {I,Ks,Inds}
        return new{I,Ks,Inds}(Ks(keys(axis)), Inds(indices(axis)))
    end

    function OffsetAxis{I,Ks,Inds}(ks::AbstractUnitRange) where {I,Ks,Inds}
        if Inds <: OneToUnion
            return OffsetAxis{I,Ks,Inds}(ks, Inds(length(ks)), false)
        else
            return OffsetAxis{I,Ks,Inds}(ks, Inds(1, length(ks)), false)
        end
    end

    function OffsetAxis{I,Ks,Inds}(offset::Integer, inds::AbstractUnitRange) where {I,Ks,Inds}
        return OffsetAxis{I,Ks,Inds}(Ks(first(inds) + offset, last(inds) + offset), inds, false)
    end

    # OffsetAxis{K,I}}(::AbstractUnitRange, ::AbstractUnitRange)
    @inline function OffsetAxis{I}(ks::AbstractUnitRange, inds::AbstractUnitRange, cl::Bool=true) where {I}
        if eltype(ks) <: I
            if eltype(inds) <: I
                return OffsetAxis{I,typeof(ks),typeof(inds)}(ks, inds, cl)
            else
                return OffsetAxis{I}(ks, AbstractUnitRange{I}(inds), cl)
            end
        else
            return OffsetAxis{I}(AbstractUnitRange{I}(ks), inds, cl)
        end
    end

    @inline function OffsetAxis{I}(axis::OffsetAxis) where {I}
        return OffsetAxis{I}(keys(axis), indices(axis), false)
    end

    @inline function OffsetAxis{I}(ks::AbstractUnitRange) where {I}
        return OffsetAxis{I}(ks, OneTo{I}(length(ks)), false)
    end

    function OffsetAxis{I}(offset::Integer, inds::AbstractUnitRange) where {I}
        if is_static(inds)
            ks = UnitSRange{I}(first(inds) + offset, last(inds) + offset)
        elseif is_fixed(inds)
            ks = UnitRange{I}(first(inds) + offset, last(inds) + offset)
        else
            ks = UnitMRange{I}(first(inds) + offset, last(inds) + offset)
        end
        return OffsetAxis{I}(ks, inds, false)
    end

    # OffsetAxis(::AbstractUnitRange, ::AbstractUnitRange)
    function OffsetAxis(ks::AbstractUnitRange, inds::AbstractUnitRange, check_length::Bool=true)
        return OffsetAxis{eltype(ks)}(ks, inds, check_length)
    end

    function OffsetAxis(ks::Ks) where {Ks}
        if is_static(ks)
            return OffsetAxis(ks, OneToSRange(length(ks)))
        elseif is_fixed(ks)
            return OffsetAxis(ks, OneTo(length(ks)))
        else  # is_dynamic
            return OffsetAxis(ks, OneToMRange(length(ks)))
        end
    end

    # OffsetAxis(::Integer, ::AbstractUnitRange)
    OffsetAxis(offset::Integer, inds::AbstractUnitRange) = OffsetAxis{eltype(inds)}(offset, inds)

    OffsetAxis(axis::OffsetAxis) = axis
end

Base.keys(axis::OffsetAxis) = getfield(axis, :keys)

Base.values(axis::OffsetAxis) = getfield(axis, :indices)

# FIXME keys_type should never be included in this callTODO
function StaticRanges.similar_type(::Type{A}, ks_type::Type, inds_type::Type) where {A<:OffsetAxis}
    return OffsetAxis{eltype(inds_type),ks_type,inds_type}
end

function StaticRanges.similar_type(::Type{A}, inds_type::Type) where {A<:OffsetAxis}
    return OffsetAxis{eltype(inds_type),keys_type(A),inds_type}
end

function Interface.unsafe_reconstruct(axis::OffsetAxis{I,Ks}, inds::Inds) where {I,Ks,Inds}
    return similar_type(axis, Ks, Inds)(
        Ks(first(inds) + first(axis) - first(indices(axis)), last(inds) + last(axis) - last(indices(axis))),
        inds
    )
end

#@inline function Interface.assign_indices(axis::OffsetAxis, inds::AbstractIndices)
#    return OffsetAxis{keytype(axis),eltype(inds),keys_type(axis),typeof(inds)}(keys(axis), inds)
#end


function _reset_keys!(axis::OffsetAxis{I,Ks,Inds}, len) where {I,Ks,Inds}
    ks = keys(axis)
    set_length!(ks, len)
end


"""
    offset(x)

Shortcut for creating `OffsetAxis` where `x` is the first argument to [`OffsetAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), offset(2))
3-element AxisArray{Float64,1}
 • dim_1 - 3:5

  3   1.0
  4   1.0
  5   1.0

```
"""
offset(x) = inds -> OffsetAxis(x, inds)
