
"""
    resize_last(x, n::Integer)

Returns a collection similar to `x` that grows or shrinks from the last index
to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> AxisIndices.resize_last(x, 2)
2-element Array{Int64,1}:
 1
 2

julia> AxisIndices.resize_last(x, 7)
7-element Array{Int64,1}:
 1
 2
 3
 4
 5
 6
 7

julia>  AxisIndices.resize_last(x, 5)
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

"""
    resize_last!(x, n::Integer)

Returns the collection `x` after growing or shrinking the last index to be of size `n`.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = collect(1:5);

julia> AxisIndices.resize_last!(x, 2);

julia> x
2-element Array{Int64,1}:
 1
 2

julia> AxisIndices.resize_last!(x, 5);

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

