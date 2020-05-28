
"""
    colaxis(x) -> axis

Returns the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> colaxis(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis([:one, :two] => Base.OneTo(2))

```
"""
colaxis(x) = axes(x, 2)

"""
    coltype(x)

Returns the type of the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> coltype(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{Symbol,Int64,Array{Symbol,1},Base.OneTo{Int64}}
```
"""
coltype(::T) where {T} = coltype(T)
coltype(::Type{T}) where {T} = axes_type(T, 2)

"""
    colkeys(x) -> axis

Returns the keys corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> colkeys(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{Symbol,1}:
 :one
 :two

```
"""
colkeys(x) = keys(axes(x, 2))

