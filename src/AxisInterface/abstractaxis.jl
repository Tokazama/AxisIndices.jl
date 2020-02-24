
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,V<:Integer,Ks,Vs} <: AbstractUnitRange{V} end

const AbstractSimpleAxis{V,Vs} = AbstractAxis{V,V,Vs,Vs}

Base.valtype(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = V

# This is required for performing `similar` on arrays
Base.to_shape(r::AbstractAxis) = length(r)

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

Base.keytype(::Type{<:AbstractAxis{K}}) where {K} = K

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
    step_keys(x)

Returns the step size of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.step_keys(Axis(1:2:10))
2

julia> AxisIndices.step_keys(rand(2))
1
```
"""
@inline step_keys(x) = _step_keys(keys(x))
_step_keys(ks::AbstractRange) = step(ks)
_step_keys(ks::LinearIndices) = 1


Base.size(a::AbstractAxis) = (length(a),)

###
### first
###
Base.first(a::AbstractAxis) = first(values(a))
StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis} = is_dynamic(T)
function StaticRanges.set_first!(x::AbstractAxis{K,V}, val::V) where {K,V}
    can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    resize_first!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_first(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_first(values(x), val)
    return similar_type(x)(resize_first(keys(x), length(vs)), vs)
end

###
### last
###
Base.last(a::AbstractAxis) = last(values(a))
StaticRanges.can_set_last(::Type{T}) where {T<:AbstractAxis} = is_dynamic(T)
function StaticRanges.set_last!(x::AbstractAxis{K,V}, val::V) where {K,V}
    can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    resize_last!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_last(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_last(values(x), val)
    return similar_type(x)(resize_last(keys(x), length(vs)), vs)
end

###
### length
###
Base.length(a::AbstractAxis) = length(values(a))
function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return can_set_length(keys_type(T)) & can_set_length(values_type(T))
end
function StaticRanges.set_length!(a::AbstractAxis, len)
    can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    set_length!(keys(a), len)
    set_length!(values(a), len)
    return a
end
function StaticRanges.set_length(a::AbstractAxis, len)
    return similar_type(a)(set_length(keys(a), len), set_length(values(a), len))
end

Base.step(a::AbstractAxis) = step(values(a))

Base.step_hp(a::AbstractAxis) = Base.step_hp(values(a))

Base.firstindex(a::AbstractAxis) = firstindex(values(a))

Base.lastindex(a::AbstractAxis) = lastindex(values(a))

Base.haskey(a::AbstractAxis{K}, key::K) where {K} = key in keys(a)

Base.allunique(a::AbstractAxis) = true

Base.isempty(a::AbstractAxis) = isempty(values(a))

Base.in(x::Integer, a::AbstractAxis) = in(x, values(a))

Base.eachindex(a::AbstractAxis) = eachindex(values(a))

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
   ) where {A<:AbstractAxis}
    return similar_type(A, ks_type, vs_type)
end

#Base.convert(::Type{T}, a::T) where {T<:AbstractAxis} = a
#Base.convert(::Type{T}, a) where {T<:AbstractAxis} = T(a)

###
### pop
###
StaticRanges.pop(x::AbstractAxis) = similar_type(typeof(x))(pop(keys(x)), pop(values(x)))

StaticRanges.popfirst(x::AbstractAxis) = similar_type(typeof(x))(popfirst(keys(x)), popfirst(values(x)))

function Base.pop!(a::AbstractAxis)
    can_set_last(a) || error("Cannot change size of index of type $(typeof(a)).")
    pop!(keys(a))
    return pop!(values(a))
end

function Base.popfirst!(a::AbstractAxis)
    can_set_first(a) || error("Cannot change size of index of type $(typeof(a)).")
    popfirst!(keys(a))
    return popfirst!(values(a))
end

###
### show
###
function Base.show(io::IO, ::MIME"text/plain", a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.show(io::IO, a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

###
### operators
###

Base.sum(x::AbstractAxis) = sum(values(x))

###
### iterators
###
Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

StaticRanges.check_iterate(r::AbstractAxis, i) = check_iterate(values(r), last(i))

Base.collect(a::AbstractAxis) = collect(values(a))

# TODO does this make sense with vector values
Base.UnitRange(a::AbstractAxis) = UnitRange(values(a))
#Base.UnitRange{T}(a::AbstractAxis) where {T} = UnitRange{T}(values(a))

###
### StaticRanges Interface
###

StaticRanges.Size(::Type{T}) where {T<:AbstractAxis} = StaticRanges.Size(values_type(T))

function StaticRanges.is_dynamic(::Type{T}) where {T<:AbstractAxis}
    return is_dynamic(values_type(T)) & is_dynamic(keys_type(T))
end

function StaticRanges.is_static(::Type{T}) where {T<:AbstractAxis}
    return is_static(values_type(T)) & is_static(keys_type(T))
end

function StaticRanges.is_fixed(::Type{T}) where {T<:AbstractAxis}
    return is_fixed(values_type(T)) & is_fixed(keys_type(T))
end

StaticRanges.as_dynamic(x::AbstractAxis) = Axis(as_dynamic(keys(x)), as_dynamic(values(x)))

StaticRanges.as_fixed(x::AbstractAxis) = Axis(as_fixed(keys(x)), as_fixed(values(x)))

StaticRanges.as_static(x::AbstractAxis) = Axis(as_static(keys(x)), as_static(values(x)))

