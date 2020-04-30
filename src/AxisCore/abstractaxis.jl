
# We can't specify Vs<:AbstractUnitRange b/c it does some really bizarre things
# to internal inferrence code on some versions of Julia. It ends up spitting out
# a bunch of references to "intersect"/"intersect_all"/"intersect_asied"/etc in "subtype.c"
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,V<:Integer,Ks,Vs} <: AbstractUnitRange{V} end

"""
    AbstractSimpleAxis{V,Vs}

A subtype of `AbstractAxis` where the keys and values are represented by a single collection.
"""
abstract type AbstractSimpleAxis{V,Vs} <: AbstractAxis{V,V,Vs,Vs} end

Base.keytype(::Type{<:AbstractAxis{K}}) where {K} = K

Base.haskey(a::AbstractAxis{K}, key::K) where {K} = key in keys(a)

"""
    keys_type(x)

Retrieves the type of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys_type(Axis(1:2))
UnitRange{Int64}

julia> keys_type(typeof(Axis(1:2)))
UnitRange{Int64}

julia> keys_type(UnitRange{Int})
Base.OneTo{Int64}
```
"""
keys_type(::T) where {T} = keys_type(T)
keys_type(::Type{T}) where {T} = OneTo{Int}  # default for things is usually LinearIndices{1}
keys_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Ks


Base.valtype(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = V

"""
    values_type(x)

Retrieves the type of the values of `x`. This should be functionally equivalent
to `typeof(values(x))`.

## Examples
```jldoctest
julia> using AxisIndices

julia>  values_type(Axis(1:2))
Base.OneTo{Int64}

julia> values_type(typeof(Axis(1:2)))
Base.OneTo{Int64}

julia> values_type(typeof(1:2))
UnitRange{Int64}
```
"""
values_type(::T) where {T} = values_type(T)
# if it's not a subtype of AbstractAxis assume it is the collection of values
values_type(::Type{T}) where {T} = T  
values_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Vs

"""
    indices(x::AbstractAxis)

Returns the indices `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x::AbstractAxis) = values(x)
indices(x::CartesianIndex) = getfield(x, :I)

### first
###
Base.first(a::AbstractAxis) = first(values(a))
function StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis}
    return StaticRanges.can_set_first(keys_type(T))
end
function StaticRanges.set_first!(x::AbstractAxis{K,V}, val::V) where {K,V}
    StaticRanges.can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    StaticRanges.resize_first!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_first(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_first(values(x), val)
    return unsafe_reconstruct(x, StaticRanges.resize_first(keys(x), length(vs)), vs)
end

function StaticRanges.set_first(x::AbstractSimpleAxis{V}, val::V) where {V}
    return unsafe_reconstruct(x, set_first(values(x), val))
end
function StaticRanges.set_first!(x::AbstractSimpleAxis{V}, val::V) where {V}
    StaticRanges.can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    return x
end

Base.firstindex(a::AbstractAxis) = first(values(a))

"""
    first_key(x)

Returns the first key of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> first_key(Axis(2:10))
2
```
"""
first_key(x) = first(keys(x))

###
### last
###
Base.last(a::AbstractAxis) = last(values(a))
function StaticRanges.can_set_last(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs}
    return StaticRanges.can_set_last(Ks) & StaticRanges.can_set_last(Vs)
end
function StaticRanges.set_last!(x::AbstractAxis{K,V}, val::V) where {K,V}
    StaticRanges.can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    StaticRanges.resize_last!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_last(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_last(values(x), val)
    return unsafe_reconstruct(x, StaticRanges.resize_last(keys(x), length(vs)), vs)
end

function StaticRanges.set_last!(x::AbstractSimpleAxis{V}, val::V) where {V}
    StaticRanges.can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    return x
end

function StaticRanges.set_last(x::AbstractSimpleAxis{K}, val::K) where {K}
    return unsafe_reconstruct(x, set_last(values(x), val))
end

Base.lastindex(a::AbstractAxis) = last(values(a))

"""
    last_key(x)

Returns the last key of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> last_key(Axis(2:10))
10
```
"""
last_key(x) = last(keys(x))

###
### length
###
Base.length(a::AbstractAxis) = length(values(a))

function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return StaticRanges.can_set_length(keys_type(T)) & StaticRanges.can_set_length(values_type(T))
end

function StaticRanges.set_length!(a::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    StaticRanges.can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    set_length!(keys(a), len)
    set_length!(values(a), len)
    return a
end
#function StaticRanges.can_set_length(::Type{<:AbstractSimpleAxis{V,Vs}}) where {V,Vs}
#    return can_set_length(Vs)
#end
function StaticRanges.set_length!(a::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    StaticRanges.can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    StaticRanges.set_length!(values(a), len)
    return a
end

function StaticRanges.set_length(a::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    return unsafe_reconstruct(a, set_length(keys(a), len), set_length(values(a), len))
end

function StaticRanges.set_length(x::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    return unsafe_reconstruct(x, StaticRanges.set_length(values(x), len))
end

###
### step
###
Base.step(a::AbstractAxis) = step(values(a))

Base.step_hp(a::AbstractAxis) = Base.step_hp(values(a))

"""
    step_key(x)

Returns the step size of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.step_key(Axis(1:2:10))
2

julia> AxisIndices.step_key(rand(2))
1

julia> AxisIndices.step_key([1])  # LinearIndices are treate like unit ranges
1
```
"""
@inline step_key(x::AbstractVector) = _step_keys(keys(x))
_step_keys(ks) = step(ks)
_step_keys(ks::LinearIndices) = 1

###
### staticness
###
function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:AbstractUnitRange}
    return true
end

function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:OneToUnion}
    return false
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

StaticRanges.Size(::Type{T}) where {T<:AbstractAxis} = StaticRanges.Size(values_type(T))

Base.size(a::AbstractAxis) = (length(a),)

"""
    unsafe_reconstruct(axis::AbstractAxis, keys::Ks, values::Vs)

Reconstructs an `AbstractAxis` of the same type as `axis` but with keys of type `Ks` and values of type `Vs`.
This method is considered unsafe because it bypasses checks  to ensure that `keys` and `values` have the same length and the all `keys` are unique.
"""
function unsafe_reconstruct(a::AbstractAxis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs)
end

"""
    unsafe_reconstruct(axis::AbstractSimpleAxis, values::Vs)

Reconstructs an `AbstractSimpleAxis` of the same type as `axis` but values of type `Vs`.
"""
unsafe_reconstruct(a::AbstractSimpleAxis, vs::Vs) where {Vs} = similar_type(a, Vs)(vs)

###
### similar
###

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
) where {A<:AbstractAxis}

    return similar_type(A, ks_type, vs_type)
end

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
) where {A<:AbstractSimpleAxis}

    return similar_type(A, vs_type)
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two])
Axis([:one, :two] => 1:2)
```
"""
function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractUnitRange{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector, new_indices::AbstractUnitRange{Integer} [, check_length::Bool=true] ) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`
and indices `new_indices`. If `check_length` is `true` then the lengths of `new_keys`
and `new_indices` are checked to ensure they have the same length before construction.

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(2))
Axis([:one, :two] => 0x0000000000000001:0x0000000000000002)

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(3))
ERROR: DimensionMismatch("keys and indices must have same length, got length(keys) = 2 and length(indices) = 3.")
[...]
```
"""
function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    check_length && check_axis_length(new_keys, new_indices)
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys), as_static(new_indices))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys), as_fixed(new_indices))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys), as_dynamic(new_indices))
    end
end

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractUnitRange{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    check_length && check_axis_length(new_keys, new_indices)
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys), as_static(new_indices))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys), as_fixed(new_indices))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys), as_dynamic(new_indices))
    end
end

"""
    similar(axis::AbstractSimpleAxis, new_indices::AbstractUnitRange{Integer}) -> AbstractSimpleAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(SimpleAxis(1:10), 1:3)
SimpleAxis(1:3)
```
"""
function Base.similar(
    axis::AbstractSimpleAxis{V,Vs},
    new_keys::AbstractUnitRange{T}
) where {V<:Integer,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys))
    end
end

const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}

#= assign_indices(axis, indices)

Reconstructs `axis` but with `indices` replacing the indices/values
Useful for reconstructing an AbstractAxisIndices when the parent array may change
types after udergoing some algorithm.
=#
assign_indices(axs::AbstractSimpleAxis, inds) = similar(axs, inds)
function assign_indices(axs::AbstractAxis, inds)
    return similar(axs, StaticRanges.shrink_last(keys(axs), length(axs) - length(inds)), inds)
end

# Vectors should have a mutable axis
true_axes(x::Vector) = (OneToMRange(length(x)),)
true_axes(x) = axes(x)
true_axes(x::Vector, i) = (OneToMRange(length(x)),)
true_axes(x, i) = axes(x, i)

