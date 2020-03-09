
###
### iterators
###
# TODO does this make sense with vector values
#Base.UnitRange{T}(a::AbstractAxis) where {T} = UnitRange{T}(values(a))

###
### Types
###
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
    return 
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
3

julia> x[==(2)]
2

julia> x[2] == x[==(3)]
true

julia> x[>(2)]
SimpleAxis(3:10)

julia> x[>(2)]
SimpleAxis(3:10)
```
"""
struct SimpleAxis{V,Vs<:AbstractUnitRange{V}} <: AbstractSimpleAxis{V,Vs}
    values::Vs

    function SimpleAxis{V,Vs}(vs::Vs, check_unique::Bool=true) where {V,Vs<:AbstractUnitRange}
        if check_unique
            allunique(vs) || error("All values must be unique.")
        end
        eltype(vs) <: V || error("keytype of keys and keytype do no match, got $(eltype(Vs)) and $K")
        return new{V,Vs}(vs)
    end
end

Base.values(si::SimpleAxis) = getfield(si, :values)

function SimpleAxis(vs, check_unique::Bool=true)
    return SimpleAxis{eltype(vs),typeof(vs)}(vs, check_unique)
end

SimpleAxis{V,Vs}(idx::AbstractAxis) where {V,Vs} = SimpleAxis{V,Vs}(Vs(values(idx)))

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

function as_axis(::T, axis::Union{OneTo,OneToSRange,OneToMRange}) where {T}
    if is_static(T)
        return SimpleAxis(as_static(axis))
    elseif is_fixed(T)
        return SimpleAxis(as_fixed(axis))
    else
        return SimpleAxis(as_dynamic(axis))
    end
end

function as_axis(::T, axis) where T
    if is_static(T)
        return Axis(as_static(axis))
    elseif is_fixed(T)
        return Axis(as_fixed(axis))
    else
        return Axis(as_dynamic(axis))
    end
end

function as_axes(A::AbstractArray{T,N}, axs::Tuple{Vararg{<:Any,M}}) where {T,N,M}
    newaxs = ntuple(N) do i
        if i > M
            as_axis(A, OneTo(size(A, i)))
        else
            as_axis(A, getfield(axs, i))
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
    ks = set_length(keys(a), len)
    vs = set_length(values(a), len)
    return similar_type(a, typeof(ks), typeof(vs))(ks, vs)
end

function StaticRanges.set_length(x::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    vs = StaticRanges.set_length(values(x), len)
    return similar_type(x, typeof(vs))(vs)
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
            vs = StaticRanges.$f(values(x))
            ks = StaticRanges.$f(keys(x))
            return similar_type(x, typeof(ks), typeof(vs))(vs, ks)
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
            vs = StaticRanges.$f(values(x))
            return similar_type(x, typeof(vs))(vs)
        end
    end
end

