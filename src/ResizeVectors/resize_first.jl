
"""
    resize_first(x, n::Integer)

Returns a collection similar to `x` that grows or shrinks from the first index
to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> AxisIndices.resize_first(x, 2)
2-element Array{Int64,1}:
 4
 5

julia> AxisIndices.resize_first(x, 7)
7-element Array{Int64,1}:
 -1
  0
  1
  2
  3
  4
  5

julia> AxisIndices.resize_first(x, 5)
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
    resize_first!(x, n::Integer)

Returns the collection `x` after growing or shrinking the first index to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> AxisIndices.resize_first!(x, 2);

julia> x
2-element Array{Int64,1}:
 4
 5

julia> AxisIndices.resize_first!(x, 6);

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

