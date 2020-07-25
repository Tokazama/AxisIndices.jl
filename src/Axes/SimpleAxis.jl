
"""
    SimpleAxis(v)

Povides an `AbstractAxis` interface for any `AbstractUnitRange`, `v `. `v` will
be considered both the `values` and `keys` of the return instance. 

## Examples

A `SimpleAxis` is useful for giving a standard set of indices the ability to use
the filtering syntax for indexing.
```jldoctest
julia> using AxisIndices, StaticRanges

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
ERROR: BoundsError: attempt to access 9-element SimpleAxis(2:10 => 2:10) at index [1]
[...]
```
"""
struct SimpleAxis{I,Inds<:AbstractUnitRange{I}} <: AbstractAxis{I,I,Inds,Inds}
    values::Inds

    SimpleAxis{I,Inds}(inds::Inds) where {I,Inds<:AbstractUnitRange{I}} = new{I,Inds}(inds)

    SimpleAxis{I}(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I,typeof(inds)}(inds)

    SimpleAxis{I}(inds::AbstractUnitRange) where {I} = SimpleAxis{I}(AbstractUnitRange{I}(inds))

    SimpleAxis(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I}(inds)

    SimpleAxis() = new{Int,OneToMRange{Int}}(OneToMRange(0))
end

Base.keys(axis::SimpleAxis) = getfield(axis, :values)

Base.values(axis::SimpleAxis) = getfield(axis, :values)

Interface.is_indices_axis(::Type{<:SimpleAxis}) = true

function StaticRanges.similar_type(
    ::Type{SimpleAxis{I,Inds}},
    ks_type::Type=Inds,
    vs_type::Type=ks_type
) where {I,Inds}

    return SimpleAxis{eltype(vs_type),vs_type}
end

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

