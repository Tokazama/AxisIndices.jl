
"""
    rowaxis(x) -> axis

Returns the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowaxis(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis(["a", "b"] => Base.OneTo(2))

```
"""
rowaxis(x) = axes(x, 1)

"""
    rowkeys(x) -> axis

Returns the keys corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowkeys(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{String,1}:
 "a"
 "b"

```
"""
rowkeys(x) = keys(axes(x, 1))

"""
    rowtype(x)

Returns the type of the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowtype(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{String,Int64,Array{String,1},Base.OneTo{Int64}}
```
"""
rowtype(::T) where {T} = rowtype(T)
rowtype(::Type{T}) where {T} = axes_type(T, 1)

