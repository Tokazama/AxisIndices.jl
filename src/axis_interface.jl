
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
struct SimpleAxis{I,Inds<:AbstractUnitRange{I}} <: AbstractAxis{I,I}
    parent_indices::Inds

    function SimpleAxis{I,Inds}(inds::AbstractUnitRange) where {I,Inds}
        if inds isa Inds
            return new{I,Inds}(inds)
        else
            return SimpleAxis{I,Inds}(Inds(inds))
        end
    end

    SimpleAxis{I}(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I,typeof(inds)}(inds)

    SimpleAxis{I}(inds::AbstractUnitRange) where {I} = SimpleAxis{I}(AbstractUnitRange{I}(inds))

    SimpleAxis(inds::AbstractUnitRange{I}) where {I} = SimpleAxis{I}(inds)

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
    SimpleAxis(stop::Integer) = SimpleAxis(OneTo(stop))
end

# Axis interface
Base.parentindices(axis::SimpleAxis) = getfield(axis, :parent_indices)

ArrayInterface.parent_type(::Type{T}) where {Inds,T<:SimpleAxis{<:Any,Inds}} = Inds

Base.keys(axis::SimpleAxis) = parentindices(axis)

# :resize_first!, :resize_last! don't need to define these ones b/c non mutating ones are only
# defined to avoid ambiguities with methods that pass AbstractUnitRange{<:Integer} instead of Integer
for f in (:grow_last!, :grow_first!, :shrink_last!, :shrink_first!)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            can_set_length(axis) ||  throw(MethodError($f, (axis, n)))
            StaticRanges.$f(parentindices(axis), n)
            return axis
        end

        function StaticRanges.$f(axis::Axis, n::Integer)
            can_set_length(axis) ||  throw(MethodError($f, (axis, n)))
            StaticRanges.$f(keys(axis), n)
            StaticRanges.$f(parentindices(axis), n)
            return axis
        end
    end
end

for f in (:grow_last, :grow_first, :shrink_last, :shrink_first, :resize_first, :resize_last)
    @eval begin
        @inline function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            return unsafe_reconstruct(axis, StaticRanges.$f(parentindices(axis), n))
        end

        @inline function StaticRanges.$f(axis::Axis, n::Integer)
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), n),
                StaticRanges.$f(parentindices(axis), n)
            )
        end

    end
end

for f in (:shrink_last, :shrink_first)
    @eval begin
        @inline function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        @inline function StaticRanges.$f(axis::Axis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), length(axis) - length(n)),
                n
            )
        end
    end
end

for f in (:grow_last, :grow_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        function StaticRanges.$f(axis::Axis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), length(n) - length(axis)),
                n
            )
        end
    end
end

for f in (:resize_last, :resize_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        function StaticRanges.$f(axis::Axis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, StaticRanges.$f(keys(axis), length(n)), n)
        end
    end
end

function Base.pop!(axis::AbstractAxis)
    StaticRanges.can_set_last(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    return _pop!(axis)
end

function _pop!(axis::Axis)
    pop!(keys(axis))
    return pop!(parentindices(axis))
end

_pop!(axis::AbstractAxis) = pop!(parentindices(axis))

function Base.popfirst!(axis::AbstractAxis)
    StaticRanges.can_set_first(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    return _popfirst!(axis)
end


function _popfirst!(axis::Axis)
    popfirst!(keys(axis))
    return popfirst!(parentindices(axis))
end

_popfirst!(axis::AbstractAxis) = popfirst!(parentindices(axis))

# TODO check for existing key first
function push_key!(axis::AbstractAxis, key)
    grow_last!(iparentndices(axis), 1)
    return nothing
end

function push_key!(axis::Axis, key)
    push!(keys(axis), key)
    grow_last!(iparentndices(axis), 1)
    return nothing
end

function pushfirst_axis!(axis::AbstractAxis)
    grow_last!(iparentndices(axis), 1)
    return nothing
end

function pushfirst_axis!(axis::Axis)
    grow_first!(keys(axis), 1)
    grow_last!(parentindices(axis), 1)
    return nothing
end

function popfirst_axis!(axis::Axis)
    if StaticRanges.can_set_first(axis)
        StaticRanges.shrink_first!(keys(axis), 1)
    else
        shrink_last!(keys(axis), 1)
    end
    shrink_last!(parentindices(axis), 1)
    return nothing
end

function popfirst_axis!(axis::AbstractAxis)
    shrink_last!(parentindices(axis), 1)
    return nothing
end

###
### length
###
function StaticRanges.set_length!(axis::AbstractAxis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(parentindices(axis), len)
    return axis
end

@inline function Base.length(axis::Axis{K,I,Ks,Inds}) where {K,I,Ks,Inds}
    if known_length(Ks) === nothing
        return length(parentindices(axis))
    else
        return known_length(Ks)
    end
end

function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return can_set_length(parent_type(T))
end

function StaticRanges.can_set_length(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_length(Ks) & can_set_length(Inds)
end

function StaticRanges.set_length!(axis::Axis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(parentindices(axis), len)
    set_length!(keys(axis), len)
    return axis
end

function StaticRanges.set_length(axis::AbstractAxis, len)
    return unsafe_reconstruct(axis, set_length(indices(axis), len))
end

function StaticRanges.set_length(axis::Axis, len)
    return unsafe_reconstruct(
        axis,
        set_length(keys(axis), len),
        set_length(parentindices(axis), len)
    )
end

###
### last
###
Base.last(axis::AbstractAxis) = last(parentindices(axis))
Base.lastindex(a::AbstractAxis) = last(a)

StaticRanges.can_set_last(::Type{T}) where {T<:AbstractAxis} = can_set_last(parent_type(T))
function StaticRanges.can_set_last(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_last(Ks) & can_set_last(Inds)
end

function StaticRanges.set_last!(axis::Axis, val)
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(parentindices(axis), val)
    resize_last!(keys(axis), length(parentindices(axis)))
    return axis
end

function StaticRanges.set_last!(axis::AbstractAxis, val)
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(parentindices(axis), val)
    return axis
end

function StaticRanges.set_last(axis::AbstractAxis, val)
    return unsafe_reconstruct(axis, set_last(parentindices(axis), val))
end

function StaticRanges.set_last(axis::Axis, val)
    vs = set_last(parentindices(axis), val)
    return unsafe_reconstruct(axis, resize_last(keys(axis), length(vs)), vs)
end

function ArrayInterface.known_last(::Type{T}) where {T<:AbstractAxis}
    return known_last(parent_type(T))
end

###
### first
###
ArrayInterface.known_first(::Type{T}) where {T<:AbstractAxis} = known_first(parent_type(T))
Base.first(axis::AbstractAxis) = first(parentindices(axis))
Base.firstindex(axis::AbstractAxis) = first(axis)

function StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis}
    return can_set_first(parent_type(T))
end
function StaticRanges.can_set_first(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_first(Ks) & can_set_first(Inds)
end

function StaticRanges.set_first(axis::AbstractAxis, val)
    return unsafe_reconstruct(axis, set_first(parentindices(axis), val))
end
function StaticRanges.set_first(axis::Axis, val)
    vs = set_first(parentindices(axis), val)
    return unsafe_reconstruct(axis, resize_first(keys(axis), length(vs)), vs)
end

function StaticRanges.set_first!(axis::AbstractAxis, val)
    can_set_first(axis) || throw(MethodError(set_first!, (axis, val)))
    set_first!(parentindices(axis), val)
    return axis
end

function StaticRanges.set_first!(axis::Axis, val)
    can_set_first(axis) || throw(MethodError(set_first!, (axis, val)))
    set_first!(parentindices(axis), val)
    resize_first!(keys(axis), length(parentindices(axis)))
    return axis
end

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function reverse_keys(axis::AbstractAxis, newinds::AbstractUnitRange)
    return Axis(reverse(keys(axis)), newinds, false, false)
end

