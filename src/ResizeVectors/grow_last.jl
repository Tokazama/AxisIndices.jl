
"""
    grow_last(x, n)

Returns a collection similar to `x` that grows by `n` elements from the last index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> AxisIndices.grow_last(mr, 2)
UnitMRange(1:12)
```
"""
function grow_last(x::AbstractVector, n::Integer)
    i = last(x)
    return vcat(x, [i = next_type(i) for _ in 1:n])
end
grow_last(x::AbstractRange, n::Integer) = set_last(x, last(x) + step(x) * n)

"""
    grow_last!(x, n)

Returns the collection `x` after growing from the last index by `n` elements.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> AxisIndices.grow_last!(mr, 2);

julia> mr
UnitMRange(1:12)
```
"""
function grow_last!(x::AbstractVector, n::Integer)
    i = last(x)
    return append!(x, [i = next_type(i) for _ in 1:n])
end
grow_last!(x::AbstractRange, n::Integer) = set_last!(x, last(x) + step(x) * n)

