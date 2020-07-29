
"""
    row_axis(x) -> axis

Returns the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> row_axis(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis(["a", "b"] => Base.OneTo(2))

```
"""
row_axis(x) = axes(x, 1)

"""
    row_keys(x) -> axis

Returns the keys corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> row_keys(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{String,1}:
 "a"
 "b"

```
"""
row_keys(x) = keys(axes(x, 1))

"""
    row_type(x)

Returns the type of the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> row_type(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{String,Int64,Array{String,1},Base.OneTo{Int64}}
```
"""
row_type(::T) where {T} = row_type(T)
row_type(::Type{T}) where {T} = axes_type(T, 1)

