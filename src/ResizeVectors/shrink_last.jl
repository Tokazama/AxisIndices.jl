
"""
    shrink_last!(x, n)

Returns the collection `x` after shrinking from the last index by `n` elements.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> AxisIndices.shrink_last!(mr, 2);

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
    shrink_last(x, n)

Returns a collection similar to `x` that shrinks by `n` elements from the last index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> AxisIndices.shrink_last(mr, 2)
UnitMRange(1:8)
```
"""
@propagate_inbounds shrink_last(x::AbstractVector, n::Integer) = x[firstindex(x):end - n]
shrink_last(x::AbstractRange, n::Integer) = set_last(x, last(x) - step(x) * n)

