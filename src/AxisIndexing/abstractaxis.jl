
# This file is for code that is only relevant to AbstractAxis 
# * TODO list for AbstractAxis
# - Is this necessary `Base.UnitRange{T}(a::AbstractAxis) where {T} = UnitRange{T}(values(a))`
# - Should AbstractAxes be a formal type?
# - is `nothing` what we want when there isn't a step in the keys
# - specialize `collect` on first type argument


# We can't specify Vs<:AbstractUnitRange b/c it does some really bizarre things
# to internal inferrence code on some versions of Julia. It ends up spitting out
# a bunch of references to "intersect"/"intersect_all"/"intersect_asied"/etc in "subtype.c"
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,V<:Integer,Ks,Vs} <: AbstractUnitRange{V} end

#Base.axes(a::AbstractAxis) = values(a)

"""
    AbstractSimpleAxis{V,Vs}

A subtype of `AbstractAxis` where the keys and values are represented by a single collection.
"""
abstract type AbstractSimpleAxis{V,Vs} <: AbstractAxis{V,V,Vs,Vs} end

const AbstractOneToAxis{K,V,Ks,Vs<:OneToUnion} = AbstractAxis{K,V,Ks,Vs}

const AbstractOneToSimpleAxis{V,Vs<:OneToUnion} = AbstractSimpleAxis{V,Vs}

function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:AbstractUnitRange}
    return true
end

function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:OneToUnion}
    return false
end

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

maybe_unsafe_reconstruct(a::AbstractAxis, inds) = @inbounds(values(a)[inds])
function maybe_unsafe_reconstruct(a::AbstractAxis, inds::AbstractUnitRange)
    unsafe_reconstruct(a, @inbounds(keys(a)[inds]), @inbounds(values(a)[inds]))
end

maybe_unsafe_reconstruct(a::AbstractSimpleAxis, inds) = @inbounds(values(a)[inds])
function maybe_unsafe_reconstruct(a::AbstractSimpleAxis, inds::AbstractUnitRange)
    return unsafe_reconstruct(a, @inbounds(values(a)[inds]))
end

Base.isempty(a::AbstractAxis) = isempty(values(a))

function Base.empty!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    empty!(keys(a))
    empty!(values(a))
    return a
end

function Base.empty!(a::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    empty!(values(a))
    return a
end

# This is required for performing `similar` on arrays
Base.to_shape(r::AbstractAxis) = length(r)


#Base.convert(::Type{T}, a::T) where {T<:AbstractAxis} = a
#Base.convert(::Type{T}, a) where {T<:AbstractAxis} = T(a)
Base.sum(x::AbstractAxis) = sum(values(x))

###
### static traits
###
# for when we want the same underlying memory layout but reversed keys

# TODO should this be a formal abstract type?
const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}

"""
    indices(x, i)

Returns the indices corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
Base.OneTo(2)
```
"""
indices(x, i) = values(axes(x, i))

"""
    indices(x)

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(Base.OneTo(2), Base.OneTo(2))

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x) = map(values, axes(x))
indices(x::AbstractAxis) = values(x)
indices(x::CartesianIndex) = getfield(x, :I)

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

julia> AxisIndices.step_key((1,))
1

julia> AxisIndices.step_key([1])  # LinearIndices are treate like unit ranges
1
```
"""
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

StaticRanges.Size(::Type{T}) where {T<:AbstractAxis} = StaticRanges.Size(values_type(T))

Base.size(a::AbstractAxis) = (length(a),)


###
### static traits
###
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

function Base.show(io::IO, ::MIME"text/plain", a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.show(io::IO, a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.show(io::IO, ::MIME"text/plain", a::AbstractSimpleAxis)
    print(io, "$(typeof(a).name)($(values(a)))")
end

function Base.show(io::IO, a::AbstractSimpleAxis)
    print(io, "$(typeof(a).name)($(values(a)))")
end

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.summary(io::IO, a::AbstractSimpleAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(values(a))))")
end

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

