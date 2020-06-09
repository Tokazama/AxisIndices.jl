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


Interface.is_indices_axis(::Type{<:OffsetAxis}) = true

#=
function OffsetAxis{K,V}(ks::AbstractUnitRange{K}, vs::AbstractUnitRange{V}, check_length::Bool=true) where {K<:Integer,V<:Integer}
    check_length && check_axis_length(ks, vs)
    return OffsetAxis{K,V,typeof(ks),typeof(vs)}(compute_offset(ks, vs), vs)
end

function OffsetAxis{K,V}(ks::AbstractUnitRange, vs::AbstractUnitRange{V}, check_length::Bool=true) where {K<:Integer,V<:Integer}
    return OffsetAxis{K,V}(AbstractUnitRange{K}(ks), vs, check_length)
end

function OffsetAxis{K,V}(ks::AbstractUnitRange{K}, vs::AbstractUnitRange, check_length::Bool=true) where {K<:Integer,V<:Integer}
    return OffsetAxis{K,V}(ks, AbstractUnitRange{V}(vs), check_length)
end

   function OffsetAxis{V,Vs}(ks::AbstractUnitRange, vs::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}}
        check_axis_length(ks, vs)
        f = compute_offset(vs, ks)
        if is_static(rc)
            return OffsetAxis{V,Vs,OneToSRange{V,f}}(f, vs)
        else
            return OffsetAxis{V,Vs,OneTo{V}}(f, vs)
        end
    end

    function OffsetAxis{V,Vs}(r::AbstractOffsetAxis) where {V<:Integer,Vs<:AbstractUnitRange{V}}
        return OffsetAxis{V,Vs}(offset(r), values(r))
    end
=#

## more readily available user faces constructors


#=



# args: range
OffsetAxis(vs::AbstractUnitRange) = OffsetAxis(0, vs)
OffsetAxis{V}(vs::AbstractUnitRange) where {V} = OffsetAxis{V}(zero(V), vs)
OffsetAxis{V,Vs}(vs::AbstractUnitRange) where {V,Vs} = OffsetAxis{V,Vs}(zero(V), vs)
function OffsetAxis{V}(r::OffsetAxis) where V<:Integer
    return OffsetAxis(offset(r), convert(AbstractUnitRange{V}, values(r)))
end
OffsetAxis(r::OffsetAxis) = r

# args: 2xrange
OffsetAxis(ks::AbstractUnitRange, vs::AbstractUnitRange{V}) where {V} = OffsetAxis{V}(ks, vs)
function OffsetAxis{V}(ks::AbstractUnitRange, vs::AbstractUnitRange{V}) where {V}
    return OffsetAxis{V,typeof(vs)}(ks, vs)
end
function OffsetAxis{V}(ks::AbstractUnitRange, vs::AbstractUnitRange) where {V}
    return OffsetAxis{V}(ks, convert(AbstractUnitRange{V}, vs))
end
# args: offset, range
function OffsetAxis{V}(offset::Integer, r::AbstractUnitRange) where V<:Integer
    rc = convert(AbstractUnitRange{V}, r)::AbstractUnitRange{V}
    return OffsetAxis{V,typeof(rc)}(convert(V, offset), rc)
end
function OffsetAxis(offset::Integer, r::AbstractUnitRange{V}) where V<:Integer
    return OffsetAxis{V,typeof(r)}(convert(V, offset), r)
end
function OffsetAxis(f::Integer, r::AbstractAxis{K,V}) where {K,V<:Integer}
    return OffsetAxis{V}(convert(V, f + (first(r) - 1)), values(r))
end


offset(r::OffsetAxis) = last(getfield(r, :offset))

function offset_coerce(::Type{Base.OneTo{V}}, r::AbstractUnitRange) where V<:Integer
    o = first(r) - 1
    return o, Base.OneTo{V}(last(r) - o)
end

function offset_coerce(::Type{Base.OneTo{V}}, r::Base.OneTo) where V<:Integer
    return 0, convert(Base.OneTo{V}, r)
end

# function offset_coerce(::Type{Base.OneTo{T}}, r::OffsetAxis) where T<:Integer
#     rc, o = offset_coerce(Base.OneTo{T}, r.parent)

# Fallback, specialze this method if `convert(I, r)` doesn't do what you need
function offset_coerce(::Type{Vs}, r::AbstractUnitRange) where Vs<:AbstractUnitRange{V} where V
    return 0, convert(Vs, r)
end
=#

# TODO: uncomment these when Julia is ready
# # Conversion preserves both the values and the indexes, throwing an InexactError if this
# # is not possible.
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::OffsetAxis{V,Vs}) where {V<:Integer,Vs<:AbstractUnitRange{V}} = r
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::OffsetAxis) where {V<:Integer,Vs<:AbstractUnitRange{V}} =
#     OffsetAxis{V,Vs}(convert(Vs, r.parent), r.offset)
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}} =
#     OffsetAxis{V,Vs}(convert(Vs, r), 0)

#=
function Interface.assign_indices(axis::OffsetAxis{K,I,Ks}, inds) where {K,I,Ks}
    return OffsetAxis{K,eltype(inds),Ks,typeof(inds)}(keys(axis), inds, false)
end
=#

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

@inline function Interface.assign_indices(axis::OffsetAxis, inds::AbstractIndices)
    return OffsetAxis{keytype(axis),eltype(inds),keys_type(axis),typeof(inds)}(keys(axis), inds)
end

function StaticRanges.set_length!(axis::OffsetAxis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(indices(axis), len)
    set_length!(keys(axis), len)
    return axis
end

function StaticRanges.set_last!(axis::OffsetAxis{K,I}, val::I) where {K,I}
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(indices(axis), val)
    resize_last!(keys(axis), length(indices(axis)))
    return axis
end

function Base.pop!(axis::OffsetAxis)
    StaticRanges.can_set_last(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    pop!(keys(axis))
    return pop!(indices(axis))
end

function Base.popfirst!(axis::OffsetAxis)
    StaticRanges.can_set_first(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    pop!(keys(axis))
    return popfirst!(indices(axis))
end

# TODO check for existing key first
push_key!(axis::OffsetAxis, key) = grow_last!(axis, 1)

pushfirst_key!(axis::OffsetAxis, key) = grow_last!(axis, 1)

function StaticRanges.grow_last!(axis::OffsetAxis, n::Integer)
    can_set_length(axis) ||  throw(MethodError(grow_last!, (axis, n)))
    StaticRanges.grow_last!(keys(axis), n)
    StaticRanges.grow_last!(indices(axis), n)
    return nothing
end

function StaticRanges.shrink_last!(axis::OffsetAxis, n::Integer)
    can_set_length(axis) ||  throw(MethodError(shrink_last!, (axis, n)))
    StaticRanges.shrink_last!(keys(axis), n)
    StaticRanges.shrink_last!(indices(axis), n)
    return nothing
end

