
"""
    diagonal_axes(x::Tuple{<:AbstractAxis,<:AbstractAxis}) -> collection

Determines the appropriate axis for the resulting vector from a call to
`diag(::AxisIndicesMatrix)`. The default behavior is to place the smallest axis
at the beginning of a call to `combine` (e.g., `broadcast_axis(small_axis, big_axis)`).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.diagonal_axes((Axis(string.(2:5)), SimpleAxis(1:2)))
Axis(["1", "2"] => UnitMRange(1:2))

julia> AxisIndices.diagonal_axes((SimpleAxis(1:3), Axis(string.(2:5))))
Axis(["1", "2", "3"] => UnitMRange(1:3))
```
"""
function diagonal_axes(x::NTuple{2,Any})
    m, n = length(first(x)), length(last(x))
    if m > n
        return broadcast_axis(last(x), first(x))
    else
        return broadcast_axis(first(x), last(x))
    end
end

