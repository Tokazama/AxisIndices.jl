# This file is for code that is only relevant to AbstractAxis
#
# * TODO list for AbstractAxis
# - Is this necessary `Base.UnitRange{T}(a::AbstractAxis) where {T} = UnitRange{T}(values(a))`
# - Should AbstractAxes be a formal type?
# - is `nothing` what we want when there isn't a step in the keys
# - specialize `collect` on first type argument

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
struct Axis{K,V,Ks,Vs<:AbstractUnitRange{V}} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs

    function Axis{K,V,Ks,Vs}(ks::Ks, vs::Vs, check_unique::Bool=true, check_length::Bool=true) where {K,V,Ks,Vs}
        if check_unique
            allunique(ks) || error("All keys must be unique.")
            allunique(vs) || error("All values must be unique.")
        end

        if check_length
            length(ks) == length(vs) || error("Length of keys and values must be equal, got length(keys) = $(length(ks)) and length(values) = $(length(vs)).")
        end

        eltype(Ks) <: K || error("keytype of keys and keytype do no match, got $(eltype(Ks)) and $K")
        eltype(Vs) <: V || error("valtype of values and valtype do no match, got $(eltype(Vs)) and $V")
        return new{K,V,Ks,Vs}(ks, vs)
    end
end

Axis(ks, vs, check_unique::Bool=true, check_length::Bool=true) = Axis{eltype(ks),eltype(vs),typeof(ks),typeof(vs)}(ks, vs, check_unique, check_length)

function Axis(ks, check_unique::Bool=true, check_length::Bool=false)
    if is_static(ks)
        return Axis(ks, OneToSRange(length(ks)))
    elseif is_fixed(ks)
        return Axis(ks, OneTo(length(ks)))
    else  # is_dynamic
        return Axis(ks, OneToMRange(length(ks)))
    end
end

Axis(x::Pair) = Axis(x.first, x.second)

Axis(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs} = Axis{K,V,Ks,Vs}(keys(a), values(a))

Axis{K,V,Ks,Vs}(a::AbstractAxis) where {K,V,Ks,Vs} = Axis{K,V,Ks,Vs}(Ks(keys(a)), Vs(values(a)))

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

###
### SimpleAxis
###
"""
    SimpleAxis(v)

Povides an `AbstractAxis` interface for any `AbstractUnitRange`, `v `. `v` will
be considered both the `values` and `keys` of the return instance. 

## Examples

A `SimpleAxis` is useful for giving a standard set of indices the ability to use
the filtering syntax for indexing.
```jldoctest
julia> using AxisIndices

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
```
"""
struct SimpleAxis{V,Vs<:AbstractUnitRange{V}} <: AbstractSimpleAxis{V,Vs}
    values::Vs

    function SimpleAxis{V,Vs}(vs::Vs) where {V,Vs<:AbstractUnitRange}
        eltype(vs) <: V || error("keytype of keys and keytype do no match, got $(eltype(Vs)) and $K")
        return new{V,Vs}(vs)
    end
end

Base.values(si::SimpleAxis) = getfield(si, :values)

SimpleAxis(vs) = SimpleAxis{eltype(vs),typeof(vs)}(vs)

function SimpleAxis{V,Vs1}(x::Vs2) where {V,Vs1,Vs2<:AbstractUnitRange}
    return SimpleAxis{V,Vs1}(Vs1(values(x)))
end

###
### as_axis
###

as_axis(x) = Axis(x)
as_axis(i::Integer) = SimpleAxis(OneTo(i))
as_axis(x::AbstractAxis) = x

as_axis(x::AbstractArray, axs::Tuple) = map(axs_i -> as_axis(x, axs_i), axs)

as_axis(::T, axis::AbstractAxis) where {T} = axis

function as_axis(::T, i::Integer) where {T}
    if is_static(T)
        return SimpleAxis(OneToSRange(i))
    elseif is_fixed(T)
        return SimpleAxis(OneTo(i))
    else
        return SimpleAxis(OneToMRange(i))
    end
end

function as_axis(array::A, axis::StaticRanges.OneToUnion, check_length::Bool=true) where {A}
    if is_static(A)
        return SimpleAxis(as_static(axis))
    elseif is_fixed(A)
        return SimpleAxis(as_fixed(axis))
    else
        return SimpleAxis(as_dynamic(axis))
    end
end

function as_axis(::T, axis, check_length::Bool=true) where {T}
    if is_static(T)
        return Axis(as_static(axis), check_length)
    elseif is_fixed(T)
        return Axis(as_fixed(axis), check_length)
    else
        return Axis(as_dynamic(axis), check_length)
    end
end

function as_axis(array::A, axis_keys::Ks, axis_values::Vs, check_length::Bool=true) where {A,Ks<:StaticRanges.OneToUnion,Vs<:StaticRanges.OneToUnion}
    if is_static(A)
        return SimpleAxis(as_static(axis_keys))
    elseif is_fixed(A)
        return SimpleAxis(as_fixed(axis_keys))
    else
        return SimpleAxis(as_dynamic(axis_keys))
    end
end

function as_axis(array::A, axis_keys::Ks, axis_values::Vs, check_length::Bool=true) where {A,Ks,Vs}
    if Ks <: AbstractAxis
        if check_length
            if length(axis_values) == length(axis_keys)
                return axis_keys
            else
                error("All keys and values must have the same length as the respective axes of the parent array, got parent axis length = $(length(axis_values)) and keys length = $(length(axis_keys))")
            end
        else
            return axis_keys
        end
    else
        if is_static(A)
            return Axis(as_static(axis_keys), as_static(axis_values), check_length)
        elseif is_fixed(A)
            return Axis(as_fixed(axis_keys), as_fixed(axis_values), check_length)
        else  # is_dynamic(A)
            if can_set_first(Ks)
                return Axis(as_dynamic(axis_keys), as_dynamic(axis_values), check_length)
            else
                return Axis(as_dynamic(axis_keys), UnitMRange(axis_values), check_length)
            end
        end
    end
end

function as_axes(array, axis_keys::Tuple{Vararg{<:Any,M}}, axis_values::Tuple{Vararg{<:Any,N}}, check_length::Bool=true) where {N,M}
    newaxs = ntuple(N) do i
        if i > M
            as_axis(array, getfield(axis_values, i), check_length)
        else
            as_axis(array, getfield(axis_keys, i), getfield(axis_values, i), check_length)
        end
    end
    return newaxs
end

###
### keys
###

Base.keys(idx::Axis) = getfield(idx, :keys)

Base.keys(si::SimpleAxis) = getfield(si, :values)

Base.keytype(::Type{<:AbstractAxis{K}}) where {K} = K

Base.haskey(a::AbstractAxis{K}, key::K) where {K} = key in keys(a)

"""
    keys_type(x)

Retrieves the type of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia>  keys_type(Axis(1:2))
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

"""
    axes_keys(x)

Returns the keys corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(UnitMRange(2:3), UnitMRange(3:4))

julia> axes_keys(Axis(1:2))
(1:2,)
```
"""
axes_keys(x) = map(keys, axes(x))
axes_keys(x::AbstractAxis) = (keys(x),)

"""
    axes_keys(x, i)

Returns the keys corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
UnitMRange(2:3)
```
"""
axes_keys(x, i) = keys(axes(x, i))

###
### similar
###
function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
   ) where {A<:Axis}
    return Axis{eltype(ks_type),eltype(vs_type),ks_type,vs_type}
end

function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
   ) where {A<:SimpleAxis}
    return SimpleAxis{eltype(vs_type),vs_type}
end

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

###
### unsafe_reconstruct
###
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

function unsafe_reconstruct(a::Axis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs, false, false)
end

maybe_unsafe_reconstruct(a::AbstractAxis, inds) = @inbounds(values(a)[inds])
function maybe_unsafe_reconstruct(a::AbstractAxis, inds::AbstractUnitRange)
    unsafe_reconstruct(a, @inbounds(keys(a)[inds]), @inbounds(values(a)[inds]))
end

maybe_unsafe_reconstruct(a::AbstractSimpleAxis, inds) = @inbounds(values(a)[inds])
function maybe_unsafe_reconstruct(a::AbstractSimpleAxis, inds::AbstractUnitRange)
    return unsafe_reconstruct(a, @inbounds(values(a)[inds]))
end

# This is required for performing `similar` on arrays
Base.to_shape(r::AbstractAxis) = length(r)

###
### values
###

Base.valtype(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = V

Base.values(idx::Axis) = getfield(idx, :values)

Base.allunique(a::AbstractAxis) = true

Base.in(x::Integer, a::AbstractAxis) = in(x, values(a))

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

###
### length
###

Base.length(a::AbstractAxis) = length(values(a))
function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return can_set_length(keys_type(T)) & can_set_length(values_type(T))
end
function StaticRanges.set_length!(a::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    set_length!(keys(a), len)
    set_length!(values(a), len)
    return a
end
#function StaticRanges.can_set_length(::Type{<:AbstractSimpleAxis{V,Vs}}) where {V,Vs}
#    return can_set_length(Vs)
#end
function StaticRanges.set_length!(a::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
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
### size
###

StaticRanges.Size(::Type{T}) where {T<:AbstractAxis} = StaticRanges.Size(values_type(T))

Base.size(a::AbstractAxis) = (length(a),)

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
```
"""
@inline step_key(x::AbstractArray) = map(step_key, axes(x))
@inline step_key(x::AbstractVector) = _step_keys(keys(x))
@inline step_key(x) = _step_keys(keys(x))
function _step_keys(ks)
    if StaticRanges.has_step(ks)
        return step(ks)
    else
        # TODO is `nothing` what we want when there isn't a step
        return nothing
    end
end
_step_keys(ks::LinearIndices) = 1

###
#Base.convert(::Type{T}, a::T) where {T<:AbstractAxis} = a
#Base.convert(::Type{T}, a) where {T<:AbstractAxis} = T(a)
Base.sum(x::AbstractAxis) = sum(values(x))

###
### static traits
###
for f in (:is_static, :is_fixed, :is_dynamic)
    @eval begin
        function StaticRanges.$f(::Type{<:AxisIndices.AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs}
            return StaticRanges.$f(Vs) & StaticRanges.$f(Ks)
        end
    end
end

for f in (:as_static, :as_fixed, :as_dynamic)
    @eval begin
        function StaticRanges.$f(x::AxisIndices.AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
            return unsafe_reconstruct(x, StaticRanges.$f(keys(x)), StaticRanges.$f(values(x)))
        end
    end
end

for f in (:is_static, :is_fixed, :is_dynamic)
    @eval begin
        function StaticRanges.$f(::Type{<:AxisIndices.AbstractSimpleAxis{V,Vs}}) where {V,Vs}
            return StaticRanges.$f(Vs)
        end
    end
end

for f in (:as_static, :as_fixed, :as_dynamic)
    @eval begin
        function StaticRanges.$f(x::AxisIndices.AbstractSimpleAxis{V,Vs}) where {V,Vs}
            return unsafe_reconstruct(x, StaticRanges.$f(values(x)))
        end
    end
end

# for when we want the same underlying memory layout but reversed keys
reverse_keys(a::AbstractAxis) = unsafe_reconstruct(a, reverse(keys(a)), values(a))
reverse_keys(a::AbstractSimpleAxis) = Axis(reverse(keys(a)), values(a))

# TODO should this be a formal abstract type?
const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}

function StaticRanges._findin(x::AbstractAxis{K,<:Integer}, xo, y::AbstractUnitRange{<:Integer}, yo) where {K}
    return StaticRanges._findin(values(x), xo, y, yo)
end
function StaticRanges._findin(x::AbstractUnitRange{<:Integer}, xo, y::AbstractSimpleAxis{K,<:Integer}, yo) where {K}
    return StaticRanges._findin(x, xo, values(y), yo)
end
function StaticRanges._findin(x::AbstractAxis{K1,<:Integer}, xo, y::AbstractAxis{K2,<:Integer}, yo) where {K1,K2}
    return StaticRanges._findin(values(x), xo, values(y), yo)
end

###
### Iterators
###
Base.eachindex(a::AbstractAxis) = values(a)

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

# TODO specialize on types
Base.collect(a::AbstractAxis) = collect(values(a))

function Base.map(f, x::AbstractAxis...)
    return maybe_unsafe_reconstruct(broadcast_axis(x), map(values.(x)...))
end

###
### first
###
Base.first(a::AbstractAxis) = first(values(a))
function StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis}
    return can_set_first(keys_type(T))
end
function StaticRanges.set_first!(x::AbstractAxis{K,V}, val::V) where {K,V}
    can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    resize_first!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_first(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_first(values(x), val)
    return unsafe_reconstruct(x, resize_first(keys(x), length(vs)), vs)
end

function StaticRanges.set_first(x::AbstractSimpleAxis{V}, val::V) where {V}
    return unsafe_reconstruct(x, set_first(values(x), val))
end
function StaticRanges.set_first!(x::AbstractSimpleAxis{V}, val::V) where {K,V}
    can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    return x
end

Base.firstindex(a::AbstractAxis) = firstindex(values(a))

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
    can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    resize_last!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_last(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_last(values(x), val)
    return unsafe_reconstruct(x, resize_last(keys(x), length(vs)), vs)
end

function StaticRanges.set_last!(x::AbstractSimpleAxis{V}, val::V) where {V}
    can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    return x
end

function StaticRanges.set_last(x::AbstractSimpleAxis{K}, val::K) where {K}
    return unsafe_reconstruct(x, set_last(values(x), val))
end

Base.lastindex(a::AbstractAxis) = lastindex(values(a))

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



