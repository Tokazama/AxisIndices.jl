
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

julia> x[1]
ERROR: BoundsError: attempt to access 9-elment SimpleAxis(2:10)) at index [1]
[...]
```
"""
struct SimpleAxis{V,Vs<:AbstractUnitRange{V}} <: AbstractSimpleAxis{V,Vs}
    values::Vs

    function SimpleAxis{V,Vs}(vs::Vs) where {V,Vs<:AbstractUnitRange}
        eltype(vs) <: V || error("keytype of keys and keytype do no match, got $(eltype(Vs)) and $K")
        return new{V,Vs}(vs)
    end
end

Base.keys(si::SimpleAxis) = getfield(si, :values)

Base.values(si::SimpleAxis) = getfield(si, :values)

function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
   ) where {A<:SimpleAxis}
    return SimpleAxis{eltype(vs_type),vs_type}
end

SimpleAxis(vs) = SimpleAxis{eltype(vs),typeof(vs)}(vs)

function SimpleAxis{V,Vs1}(x::Vs2) where {V,Vs1,Vs2<:AbstractUnitRange}
    return SimpleAxis{V,Vs1}(Vs1(values(x)))
end

"""
    SimpleAxis(start::Integer, stop::Integer) -> SimpleAxis{UnitRange{Integer}}

Passes `start` and `stop` arguments to `UnitRange` to construct the values of `SimpleAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> SimpleAxis(1, 10)
SimpleAxis(1:10)
```
"""
SimpleAxis(start::Integer, stop::Integer) = SimpleAxis(UnitRange(start, stop))

"""
    SimpleAxis(stop::Integer) -> SimpleAxis{Base.OneTo{Integer}}

Passes `stop` `Base.OneTo` to construct the values of `SimpleAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> SimpleAxis(10)
SimpleAxis(Base.OneTo(10))
```
"""
SimpleAxis(stop::Integer) = SimpleAxis(Base.OneTo(stop))

