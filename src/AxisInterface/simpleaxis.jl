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

    function SimpleAxis{V,Vs}(vs::Vs, check_unique::Bool=true) where {V,Vs}
        if check_unique
            allunique(vs) || error("All values must be unique.")
        end
        eltype(vs) <: V || error("keytype of keys and keytype do no match, got $(eltype(Vs)) and $K")
        return new{V,Vs}(vs)
    end
end

Base.values(si::SimpleAxis) = getfield(si, :values)
Base.keys(si::SimpleAxis) = getfield(si, :values)

SimpleAxis(vs, check_unique::Bool=true) = SimpleAxis{eltype(vs),typeof(vs)}(vs, check_unique)

SimpleAxis{V,Vs}(idx::AbstractAxis) where {V,Vs} = SimpleAxis{V,Vs}(Vs(values(idx)))

# This is a bit tricky b/c it requires that we permit both the keys and vals
# to be set in order to have the same format as other AbstractAxis constructors
function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
   ) where {A<:SimpleAxis}
    return SimpleAxis{eltype(vs_type),vs_type}
end

function StaticRanges.set_first(x::SimpleAxis{V}, val::V) where {V}
    return SimpleAxis(set_first(values(x), val))
end


function StaticRanges.set_first!(x::SimpleAxis{V}, val::V) where {K,V}
    can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    return x
end

function StaticRanges.set_last!(x::SimpleAxis{V}, val::V) where {V}
    can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    return x
end

StaticRanges.set_last(x::SimpleAxis{K}, val::K) where {K} = SimpleAxis(set_last(values(x), val))


StaticRanges.can_set_length(::Type{T}) where {T<:SimpleAxis} = can_set_length(keys_type(T))
function StaticRanges.set_length!(a::SimpleAxis, len)
    can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    StaticRanges.set_length!(values(a), len)
    return a
end

StaticRanges.set_length(a::SimpleAxis, len) = SimpleAxis(StaticRanges.set_length(values(a), len))

StaticRanges.pop(x::SimpleAxis) = SimpleAxis(pop(values(x)))

StaticRanges.popfirst(x::SimpleAxis) = SimpleAxis(popfirst(values(x)))

Base.pop!(si::SimpleAxis) = pop!(values(si))

Base.popfirst!(si::SimpleAxis) = popfirst!(values(si))

function Base.show(io::IO, ::MIME"text/plain", a::SimpleAxis)
    print(io, "SimpleAxis($(values(a)))")
end

function Base.show(io::IO, a::SimpleAxis)
    print(io, "SimpleAxis($(values(a)))")
end

check_iterate(r::SimpleAxis, i) = check_iterate(values(r), i)

StaticRanges.is_dynamic(::Type{T}) where {T<:SimpleAxis} = is_dynamic(keys_type(T))

StaticRanges.is_static(::Type{T}) where {T<:SimpleAxis} = is_static(keys_type(T))

StaticRanges.is_fixed(::Type{T}) where {T<:SimpleAxis} = is_fixed(keys_type(T))

StaticRanges.as_dynamic(x::SimpleAxis) = SimpleAxis(as_dynamic(values(x)))

StaticRanges.as_fixed(x::SimpleAxis) = SimpleAxis(as_fixed(values(x)))

StaticRanges.as_static(x::SimpleAxis) = SimpleAxis(as_static(values(x)))

function Base.empty!(a::SimpleAxis)
    empty!(values(a))
    return a
end
