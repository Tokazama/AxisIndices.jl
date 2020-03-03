# Methods that mutate the axes of an AbstractAxisIndices

###
### push
###
function Base.push!(A::AbstractAxisIndices{T,1}, items...) where {T}
    grow_last!(axes(A, 1), length(items))
    push!(parent(A), items...)
    return A
end

function Base.pushfirst!(A::AbstractAxisIndices{T,1}, items...) where {T}
    grow_first!(axes(A, 1), length(items))
    pushfirst!(parent(A), items...)
    return A
end

###
### pop
###
function StaticRanges.pop(x::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    ks = pop(keys(x))
    vs = pop(values(x))
    return similar_type(x, typeof(ks), typeof(vs))(ks, vs)
end

function StaticRanges.pop(x::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    vs = pop(values(x))
    return similar_type(x, typeof(vs))(vs)
end

function Base.pop!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    can_set_last(a) || error("Cannot change size of index of type $(typeof(a)).")
    pop!(keys(a))
    return pop!(values(a))
end

Base.pop!(si::AbstractSimpleAxis{V,Vs}) where {V,Vs} = pop!(values(si))

function Base.pop!(A::AbstractAxisIndices{T,1}) where {T}
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end

###
### popfirst
###
function StaticRanges.popfirst(x::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    ks = popfirst(keys(x))
    vs = popfirst(values(x))
    return similar_type(x, typeof(ks), typeof(vs))(ks, vs)
end

function StaticRanges.popfirst(x::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    vs = popfirst(values(x))
    return similar_type(x, typeof(vs))(vs)
end

function Base.popfirst!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    can_set_first(a) || error("Cannot change size of index of type $(typeof(a)).")
    popfirst!(keys(a))
    return popfirst!(values(a))
end

Base.popfirst!(si::AbstractSimpleAxis{V,Vs}) where {V,Vs} = popfirst!(values(si))

function Base.popfirst!(A::AbstractAxisIndices{T,1}) where {T}
    shrink_first!(axes(A, 1), 1)
    return popfirst!(parent(A))
end

###
### empty
###
function Base.empty!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    empty!(keys(a))
    empty!(values(a))
    return a
end

function Base.empty!(a::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    empty!(values(a))
    return a
end

function Base.empty!(a::AbstractAxisIndices)
    for ax_i in axes(a)
        if !can_set_length(ax_i)
            error("Cannot perform `empty!` on AbstractAxisIndices that has an axis with a fixed size.")
        end
    end

    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end

Base.isempty(a::AbstractAxis) = isempty(values(a))

###
###
###

"""
    append_axis(x, y)

Returns the appended axes `x` and `y`. New subtypes of `AbstractAxis` must
implement a unique `append_axis` method.

## Examples
```jldoctest
julia> using AxisIndices

julia> append_axis(Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
Axis(UnitMRange(1:20) => UnitMRange(1:20))

julia> append_axis(SimpleAxis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
SimpleAxis(UnitMRange(1:20))
```
"""
function append_axis(x::AbstractAxis, y::AbstractAxis)
    return Axis(append_keys(keys(x), keys(y)), append_values(values(y), values(y)))
end
function append_axis(x::AbstractSimpleAxis, y::AbstractAxis)
    return Axis(append_keys(keys(x), keys(y)), append_values(values(y), values(y)))
end
function append_axis(x::AbstractAxis, y::AbstractSimpleAxis)
    return Axis(append_keys(keys(x), keys(y)), append_values(values(y), values(y)))
end
function append_axis(x::AbstractSimpleAxis, y::AbstractSimpleAxis)
    return SimpleAxis(append_values(values(y), values(y)))
end

function append_axis(x, y)
    if same_type(x, y)
        return append_values(x, y)
    else
        return append_axis(promote(x, y)...)
    end
end

"""
    append_keys(x, y)

Returns the appropriate keys of and index within the operation `append_axis(x, y)`

See also: [`append_axis`](@ref)
"""
append_keys(x, y) = cat_keys(x, y)

"""
    append_values(x, y)

Returns the appropriate values of and index within the operation `append_axis(x, y)`

See also: [`append_axis`](@ref)
"""
append_values(x, y) = cat_values(x, y)

"""
    append_axis!(x, y)

Returns the appended axes `x` and `y`. New subtypes of `AbstractAxis` must
implement a unique `append_axis!` method.

## Examples
```jldoctest
julia> using AxisIndices

julia> x, y = Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10));

julia> append_axis!(x, y);

julia> length(x)
20

julia> append_axis!(y, x);

julia> length(y)
30
```
"""
function append_axis!(x::AbstractAxis{K,V,Ks,Vs}, y) where {K,V,Ks,Vs}
    _append_keys!(keys(x), y)
    set_length!(values(x), length(x) + length(y))
    return x
end
function append_axis!(x::AbstractSimpleAxis{V,Vs}, y) where {V,Vs}
    set_length!(x, length(x) + length(y))
    return x
end

_append_keys!(x, y) = __append_keys!(StaticRanges.Continuity(x), x, y)
__append_keys!(::StaticRanges.ContinuousTrait, x, y) = set_length!(x, length(x) + length(y))
__append_keys!(::StaticRanges.DiscreteTrait, x, y) = make_unique!(x, keys(y))

function Base.append!(A::AbstractAxisIndices{T,1}, collection) where {T}
    append_axis!(axes(A, 1), axes(collection, 1))
    append!(parent(A), collection)
    return A
end

###
### resize
###
"""
    next_type(x::T)

Returns the immediately greater value of type `T`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.next_type("b")
"c"

julia> AxisIndices.next_type(:b)
:c

julia> AxisIndices.next_type('a')
'b': ASCII/Unicode U+0062 (category Ll: Letter, lowercase)

julia> AxisIndices.next_type(1)
2

julia> AxisIndices.next_type(2.0)
2.0000000000000004

julia> AxisIndices.next_type("")
""
```
"""
function next_type(x::AbstractString)
    isempty(x) && return ""
    return x[1:prevind(x, lastindex(x))] * (last(x) + 1)
end
next_type(x::Symbol) = Symbol(next_type(string(x)))
next_type(x::AbstractChar) = x + 1
next_type(x::T) where {T<:AbstractFloat} = nextfloat(x)
next_type(x::T) where {T} = x + one(T)

"""
    prev_type(x::T)

Returns the immediately lesser value of type `T`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.prev_type("b")
"a"

julia> AxisIndices.prev_type(:b)
:a

julia> AxisIndices.prev_type('b')
'a': ASCII/Unicode U+0061 (category Ll: Letter, lowercase)

julia> AxisIndices.prev_type(1)
0

julia> AxisIndices.prev_type(1.0)
0.9999999999999999

julia> AxisIndices.prev_type("")
""
```
"""
function prev_type(x::AbstractString)
    isempty(x) && return ""
    return x[1:prevind(x, lastindex(x))] * (last(x) - 1)
end
prev_type(x::Symbol) = Symbol(prev_type(string(x)))
prev_type(x::AbstractChar) = x - 1
prev_type(x::T) where {T<:AbstractFloat} = prevfloat(x)
prev_type(x::T) where {T} = x - one(T)

### TODO: all documentation below this
"""
    resize_first!(x, n::Integer)

Returns the collection `x` after growing or shrinking the first index to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> resize_first!(x, 2);

julia> x
2-element Array{Int64,1}:
 4
 5

julia> resize_first!(x, 6);

julia> x
6-element Array{Int64,1}:
 0
 1
 2
 3
 4
 5

```
"""
function resize_first!(x, n::Integer)
    d = n - length(x)
    if d > 0
        return grow_first!(x, d)
    elseif d < 0
        return shrink_first!(x, abs(d))
    else  # d == 0
        return x
    end
end

"""
    resize_last!(x, n::Integer)

Returns the collection `x` after growing or shrinking the last index to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> resize_last!(x, 2);

julia> x
2-element Array{Int64,1}:
 1
 2

julia> resize_last!(x, 5);

julia> x
5-element Array{Int64,1}:
 1
 2
 3
 4
 5

```
"""
function resize_last!(x, n::Integer)
    d = n - length(x)
    if d > 0
        return grow_last!(x, d)
    elseif d < 0
        return shrink_last!(x, abs(d))
    else  # d == 0
        return x
    end
end

"""
    resize_first(x, n::Integer)

Returns a collection similar to `x` that grows or shrinks from the first index
to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> resize_first(x, 2)
2-element Array{Int64,1}:
 4
 5

julia> resize_first(x, 7)
7-element Array{Int64,1}:
 -1
  0
  1
  2
  3
  4
  5

julia> resize_first(x, 5)
5-element Array{Int64,1}:
 1
 2
 3
 4
 5
```
"""
function resize_first(x, n::Integer)
    d = n - length(x)
    if d > 0
        return grow_first(x, d)
    elseif d < 0
        return shrink_first(x, abs(d))
    else  # d == 0
        return copy(x)
    end
end

"""
    resize_last(x, n::Integer)

Returns a collection similar to `x` that grows or shrinks from the last index
to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> resize_last(x, 2)
2-element Array{Int64,1}:
 1
 2

julia> resize_last(x, 7)
7-element Array{Int64,1}:
 1
 2
 3
 4
 5
 6
 7

julia>  resize_last(x, 5)
5-element Array{Int64,1}:
 1
 2
 3
 4
 5

```
"""
function resize_last(x, n::Integer)
    d = n - length(x)
    if d > 0
        return grow_last(x, d)
    elseif d < 0
        return shrink_last(x, abs(d))
    else  # d == 0
        return x
    end
end

# Note that all `grow_*`/`shrink_*` functions ignore the possibility that `d` is
# negative. Although these are documented, they should probably be considered
# unsafe and only used internally.
"""
    grow_first!(x, n)

Returns the collection `x` after growing from the first index by `n` elements.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> grow_first!(mr, 2);

julia> mr
UnitMRange(-1:10)
```
"""
function grow_first!(x::AbstractVector, n::Integer)
    i = first(x)
    return prepend!(x, reverse!([i = prev_type(i) for _ in 1:n]))
end
grow_first!(x::AbstractRange, n::Integer) = set_first!(x, first(x) - step(x) * n)

"""
    grow_last!(x, n)

Returns the collection `x` after growing from the last index by `n` elements.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> grow_last!(mr, 2);

julia> mr
UnitMRange(1:12)
```
"""
function grow_last!(x::AbstractVector, n::Integer)
    i = last(x)
    return append!(x, [i = next_type(i) for _ in 1:n])
end
grow_last!(x::AbstractRange, n::Integer) = set_last!(x, last(x) + step(x) * n)

"""
    grow_first(x, n)

Returns a collection similar to `x` that grows by `n` elements from the first index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> grow_first(mr, 2)
UnitMRange(-1:10)
```
"""
function grow_first(x::AbstractVector, n::Integer)
    i = first(x)
    return vcat(reverse!([i = prev_type(i) for _ in 1:n]), x)
end
grow_first(x::AbstractRange, n::Integer) = set_first(x, first(x) - step(x) * n)

"""
    grow_last(x, n)

Returns a collection similar to `x` that grows by `n` elements from the last index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> grow_last(mr, 2)
UnitMRange(1:12)
```
"""
function grow_last(x::AbstractVector, n::Integer)
    i = last(x)
    return vcat(x, [i = next_type(i) for _ in 1:n])
end
grow_last(x::AbstractRange, n::Integer) = set_last(x, last(x) + step(x) * n)

"""
    shrink_first!(x, n)

Returns the collection `x` after shrinking from the first index by `n` elements.
"""
function shrink_first!(x::AbstractVector, n::Integer)
    for _ in 1:n
        popfirst!(x)
    end
    return x
end
shrink_first!(x::AbstractRange, n::Integer) = set_first!(x, first(x) + step(x) * n)

"""
    shrink_last!(x, n)

Returns the collection `x` after shrinking from the last index by `n` elements.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> shrink_last!(mr, 2);

julia> mr
UnitMRange(1:8)
```
"""
function shrink_last!(x::AbstractVector, n::Integer)
    for _ in 1:n
        pop!(x)
    end
    return x
end
shrink_last!(x::AbstractRange, n::Integer) = set_last!(x, last(x) - step(x) * n)

"""
    shrink_first(x, n)

Returns a collection similar to `x` that shrinks by `n` elements from the first index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> shrink_first(mr, 2)
UnitMRange(3:10)
```
"""
@propagate_inbounds shrink_first(x::AbstractVector, n::Integer) = x[(firstindex(x) + n):end]
shrink_first(x::AbstractRange, n::Integer) = set_first(x, first(x) + step(x) * n)

"""
    shrink_last(x, n)

Returns a collection similar to `x` that shrinks by `n` elements from the last index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> shrink_last(mr, 2)
UnitMRange(1:8)
```
"""
@propagate_inbounds shrink_last(x::AbstractVector, n::Integer) = x[firstindex(x):end - n]
shrink_last(x::AbstractRange, n::Integer) = set_last(x, last(x) - step(x) * n)

