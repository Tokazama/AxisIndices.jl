
"""
    col_axis(x) -> axis

Returns the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> col_axis(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis([:one, :two] => Base.OneTo(2))

```
"""
col_axis(x) = axes(x, 2)

"""
    col_type(x)

Returns the type of the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> col_type(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{Symbol,Int64,Array{Symbol,1},Base.OneTo{Int64}}
```
"""
col_type(::T) where {T} = col_type(T)
col_type(::Type{T}) where {T} = axes_type(T, 2)

"""
    col_keys(x) -> axis

Returns the keys corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> col_keys(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{Symbol,1}:
 :one
 :two

```
"""
col_keys(x) = keys(axes(x, 2))

