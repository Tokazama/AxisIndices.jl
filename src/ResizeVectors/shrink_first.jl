
"""
    shrink_first(x, n)

Returns a collection similar to `x` that shrinks by `n` elements from the first index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> AxisIndices.shrink_first(mr, 2)
UnitMRange(3:10)
```
"""
@propagate_inbounds shrink_first(x::AbstractVector, n::Integer) = x[(firstindex(x) + n):end]
shrink_first(x::AbstractRange, n::Integer) = set_first(x, first(x) + step(x) * n)

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

