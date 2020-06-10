# TODO OffsetAxis
# - impliment similar_type
# - implement constructors that use Val for static offset
# 

@inline function _construct_offset_keys(offset::T, inds::AbstractIndices) where {T}
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
struct OffsetAxis{K<:Integer,I,Ks<:AbstractIndices{K},Inds} <: AbstractOffsetAxis{K,I,Ks,Inds}
    keys::Ks
    indices::Inds


    # OffsetAxis{K,V,Ks,Vs}
    @inline function OffsetAxis{K,I,Ks,Inds}(ks::AbstractIndices, inds::AbstractIndices, check_length::Bool=true) where {K,I,Ks,Inds}
        check_length && check_axis_length(ks, inds)
        return new{K,I,Ks,Inds}(ks, inds)
        #=
        if ks isa Ks
            if inds isa Inds
                check_length && check_axis_length(ks, inds)
                return new{K,I,Ks,Inds}(ks, inds)
            else
                return OffsetAxis{K,I,Ks,Inds}(ks, Inds(inds), check_length)
            end
        else
            return OffsetAxis{K,I,Ks,Inds}(Ks(ks), inds, check_length)
        end
        =#
    end

    function OffsetAxis{K,I,Ks,Inds}(axis::OffsetAxis) where {K,I,Ks,Inds}
        return new{K,I,Ks,Inds}(Ks(keys(axis)), Inds(indices(axis)))
    end

    function OffsetAxis{K,I,Ks,Inds}(ks::AbstractIndices) where {K,I,Ks,Inds}
        if Inds <: OneToUnion
            return OffsetAxis{K,I,Ks,Inds}(ks, Inds(length(ks)), false)
        else
            return OffsetAxis{K,I,Ks,Inds}(ks, Inds(1, length(ks)), false)
        end
    end

    function OffsetAxis{K,I,Ks,Inds}(offset::Integer, inds::AbstractIndices) where {K,I,Ks,Inds}
        return OffsetAxis{K,I,Ks,Inds}(Ks(first(inds) + offset, last(inds) + offset), inds, false)
    end

    # OffsetAxis{K,I}}(::AbstractUnitRange, ::AbstractUnitRange)
    @inline function OffsetAxis{K,I}(ks::AbstractIndices, inds::AbstractIndices, cl::Bool=true) where {K,I}
        if eltype(ks) <: K
            if eltype(inds) <: I
                return OffsetAxis{K,I,typeof(ks),typeof(inds)}(ks, inds, cl)
            else
                return OffsetAxis{K,I}(ks, AbstractIndices{I}(inds), cl)
            end
        else
            return OffsetAxis{K,I}(AbstractIndices{K}(ks), inds, cl)
        end
    end

    @inline function OffsetAxis{K,I}(axis::OffsetAxis) where {K,I}
        return OffsetAxis{K,I}(keys(axis), indices(axis), false)
    end

    @inline function OffsetAxis{K,I}(ks::AbstractIndices) where {K,I}
        return OffsetAxis{K,I}(ks, OneTo{I}(length(ks)), false)
    end

    function OffsetAxis{K,I}(offset::Integer, inds::AbstractIndices) where {K,I}
        return OffsetAxis{K,I}(_construct_offset_keys(I(offset), inds), inds, false)
    end

    # OffsetAxis{K}
    function OffsetAxis{K}(ks::AbstractIndices, inds::AbstractIndices, check_length::Bool=true) where {K}
        return OffsetAxis{K,eltype(inds)}(ks, inds, check_length)
    end

    function OffsetAxis{K}(offset::Integer, inds::AbstractIndices) where {K}
        return OffsetAxis{K}(_construct_offset_keys(K(offset), inds), inds, false)
    end

    OffsetAxis{K}(axis::OffsetAxis) where {K} = OffsetAxis{K}(keys(axis), indices(axis), false)

    OffsetAxis{K}(axis::AbstractIndices) where {K} = OffsetAxis(AbstractUnitRange{K}(axis))

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
    function OffsetAxis(offset::Integer, inds::AbstractIndices)
        return OffsetAxis(_construct_offset_keys(offset, inds), inds, false)
    end

    OffsetAxis(axis::OffsetAxis) = axis
end

Base.keys(axis::OffsetAxis) = getfield(axis, :keys)

Base.values(axis::OffsetAxis) = getfield(axis, :indices)

function StaticRanges.similar_type(::Type{A}, ks_type::Type, inds_type::Type) where {A<:OffsetAxis}
    return OffsetAxis{eltype(ks_type),eltype(inds_type),ks_type,inds_type}
end

function StaticRanges.similar_type(::Type{A}, inds_type::Type) where {A<:OffsetAxis}
    return OffsetAxis{keytype(A),eltype(inds_type),keys_type(A),inds_type}
end

function Interface.unsafe_reconstruct(axis::OffsetAxis{K,I,Ks}, inds::Inds) where {K,I,Ks,Inds}
    return similar_type(axis, Ks, Inds)(
        Ks(first(inds) + first(axis) - first(indices(axis)), last(inds) + last(axis) - last(indices(axis))),
        inds
    )
end

#@inline function Interface.assign_indices(axis::OffsetAxis, inds::AbstractIndices)
#    return OffsetAxis{keytype(axis),eltype(inds),keys_type(axis),typeof(inds)}(keys(axis), inds)
#end


function _reset_keys!(axis::OffsetAxis{K,I,Ks,Inds}, len) where {K,I,Ks,Inds}
    ks = keys(axis)
    set_length!(ks, len)
end

