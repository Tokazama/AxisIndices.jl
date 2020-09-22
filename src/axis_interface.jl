
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
struct Axis{K,I,Ks,Inds<:AbstractUnitRange{I}} <: AbstractAxis{K,I}
    keys::Ks
    parent_indices::Inds

    function Axis{K,I,Ks,Inds}(
        ks::Ks,
        inds::Inds,
        check_unique::Bool=true,
        check_length::Bool=true
    ) where {K,I,Ks<:AbstractVector{K},Inds<:AbstractUnitRange{I}}
        check_unique && check_axis_unique(ks, inds)
        check_length && check_axis_length(ks, inds)
        return new{K,I,Ks,Inds}(ks, inds)
    end

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

    # Axis{K,I}
    function Axis{K,I}() where {K,I}
        return new{K,I,Vector{K},OneToMRange{I}}(Vector{K}(),OneToMRange{I}(0))
    end

    function Axis{K,I,Ks,Inds}(axis::AbstractAxis) where {K,I,Ks,Inds}
        return Axis{K,I,Ks,Inds}(Ks(keys(axis)), Inds(parentindices(axis)), false, false)
    end

    function Axis{K,I,Ks,Inds}(axis::Axis{K,I,Ks,Inds}) where {K,I,Ks,Inds}
        if can_change_size(axis)
            return copy(axis)
        else
            return axis
        end
    end

    function Axis(axis::AbstractAxis)
        if can_change_size(axis)
            return axis
        else
            return copy(axis)
        end
    end

    Axis{K}() where {K} = Axis{K,Int}()

    Axis() = Axis{Any}()

    Axis(x::Pair) = Axis(x.first, x.second)

    function Axis(ks, inds, check_unique::Bool=true, check_length::Bool=true)
        return Axis{eltype(ks),eltype(inds),typeof(ks),typeof(inds)}(ks, inds, check_unique, check_length)
    end

    function Axis(ks, check_unique::Bool=true)
        if can_change_size(ks)
            return Axis(ks, OneToMRange(length(ks)), check_unique, false)
        else
            len = known_length(ks)
            if len isa Nothing
                return return Axis(ks, OneTo(length(ks)), check_unique, false)
            else
                return Axis(ks, OneToSRange(len), false)
            end
        end
    end
end

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

Base.IndexStyle(::Type{T}) where {T<:Axis} = IndexAxis()
function unsafe_reconstruct(::IndexAxis, axis, arg, inds)
    if is_key(axis, arg) && (arg isa AbstractVector)
        ks = arg
    else
        ks = @inbounds(getindex(keys(axis), inds))
    end
    return Axis(ks, unsafe_reconstruct(parentindices(axis), arg, inds), false, false)
end

function unsafe_reconstruct(::IndexAxis, axis, inds)
    return Axis(
        @inbounds(getindex(keys(axis), inds)),
        unsafe_reconstruct(parentindices(axis), arg, inds),
        false,
        false
    )
end

# Axis interface
Base.parentindices(axis::Axis) = getfield(axis, :parent_indices)
Base.parentindices(axis::SimpleAxis) = getfield(axis, :parent_indices)

ArrayInterface.parent_type(::Type{T}) where {Inds,T<:Axis{<:Any,<:Any,<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:SimpleAxis{<:Any,Inds}} = Inds

Base.keys(axis::Axis) = getfield(axis, :keys)
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

#= TODO implement this when part of ArrayInterface
function StaticRanges.popfirst(axis::AbstractAxis)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, popfirst(indices(axis)))
    else
        return unsafe_reconstruct(axis, popfirst(keys(axis)), popfirst(indices(axis)))
    end
end

function StaticRanges.pop(axis::AbstractAxis)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, pop(indices(axis)))
    else
        return unsafe_reconstruct(axis, pop(keys(axis)), pop(indices(axis)))
    end
end
=#

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

#=
function reverse_keys(axis::AbstractAxis, newinds::AbstractUnitRange)
    if is_indices_axis(axis)
        return unsafe_reconstruct(reverse(keys(axis)), newinds, false)
    else
        return similar(axis, reverse(keys(axis)), newinds, false)
    end
end
=#
function reverse_keys(axis::AbstractAxis, newinds::AbstractUnitRange)
    return Axis(reverse(keys(axis)), newinds, false, false)
end

