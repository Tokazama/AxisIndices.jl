
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
ERROR: BoundsError: attempt to access SimpleAxis(2:10) at index [1]
[...]
```
"""
struct SimpleAxis{I,Inds<:AbstractUnitRange{I}} <: AbstractAxis{I,Inds}
    parent::Inds

    function SimpleAxis{I,Inds}(inds::AbstractUnitRange) where {I,Inds}
        if inds isa Inds
            return new{I,Inds}(inds)
        else
            return SimpleAxis{I,Inds}(Inds(inds))
        end
    end

    SimpleAxis{I}(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I,typeof(inds)}(inds)
    SimpleAxis{I}(inds::AbstractUnitRange) where {I} = SimpleAxis{I}(AbstractUnitRange{I}(inds))
    function SimpleAxis{I}(inds::SimpleAxis) where {I}
        if eltype(inds) <: I
            return inds
        else
            return SimpleAxis{I}(parent(inds))
        end
    end


    SimpleAxis(inds::SimpleAxis) = inds
    SimpleAxis(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I}(inds)
    SimpleAxis(inds::IdentityUnitRange) = SimpleAxis(inds.indices)
    SimpleAxis() = new{Int,OneToMRange{Int}}(OneToMRange(0))

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
    SimpleAxis(start::Integer, stop::Integer) = SimpleAxis(start:stop)

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
    SimpleAxis(stop::Integer) = SimpleAxis(StaticInt(1):stop)
end

ArrayInterface.unsafe_reconstruct(axis::SimpleAxis, inds; kwargs...) = SimpleAxis(inds)

# FIXME this should be deleted once https://github.com/SciML/ArrayInterface.jl/issues/79 is resolved
@propagate_inbounds function Base.getindex(axis::SimpleAxis, arg::StepRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    return maybe_unsafe_reconstruct(axis, arg)
end
