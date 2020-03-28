
"""
    grow_first(x, n)

Returns a collection similar to `x` that grows by `n` elements from the first index.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> AxisIndices.grow_first(mr, 2)
UnitMRange(-1:10)
```
"""
function grow_first(x::AbstractVector, n::Integer)
    i = first(x)
    return vcat(reverse!([i = prev_type(i) for _ in 1:n]), x)
end
grow_first(x::AbstractRange, n::Integer) = set_first(x, first(x) - step(x) * n)

"""
    grow_first!(x, n)

Returns the collection `x` after growing from the first index by `n` elements.

## Examples
```jldoctest
julia> using AxisIndices

julia> mr = UnitMRange(1, 10)
UnitMRange(1:10)

julia> AxisIndices.grow_first!(mr, 2);

julia> mr
UnitMRange(-1:10)
```
"""
function grow_first!(x::AbstractVector, n::Integer)
    i = first(x)
    return prepend!(x, reverse!([i = prev_type(i) for _ in 1:n]))
end
grow_first!(x::AbstractRange, n::Integer) = set_first!(x, first(x) - step(x) * n)

