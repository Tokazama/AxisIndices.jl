"""
    inverse_axes(a::AbstractMatrix) = inverse_axes(axes(a))
    inverse_axes(a::Tuple{I1,I2}) -> Tuple{I2,I1}

Returns the inverted axes of `a`, corresponding to the `inv` method from the 
`LinearAlgebra` package in the standard library.

## Examples
```jldoctest
julia> using AxisIndices

julia> inverse_axes(rand(2,4))
(Base.OneTo(4), Base.OneTo(2))

julia> inverse_axes((Axis(1:2), Axis(1:4)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:2 => Base.OneTo(2)))
```
"""
inverse_axes(x::AbstractMatrix) = inverse_axes(axes(x))
inverse_axes(x::Tuple{I1,I2}) where {I1,I2} = (last(x), first(x))

Base.inv(a::AxisIndicesMatrix) = AxisIndicesArray(inv(parent(a)), inverse_axes(a))

