
#=

"""
    reshape(A::AxisArray, shape)

Reshape the array and axes of `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = reshape(AxisArray(Vector(1:8), [:a, :b, :c, :d, :e, :f, :g, :h]), 4, 2);

julia> axes(A)
(Axis([:a, :b, :c, :d] => SimpleAxis(1:4)), SimpleAxis(1:2))

julia> axes(reshape(A, 2, :))
(Axis([:a, :b] => SimpleAxis(1:2)), SimpleAxis(1:4))

```
"""
function Base.reshape(A::AxisArray, shp::NTuple{N,Int}) where {N}
    p = reshape(parent(A), shp)
    return AxisArray(p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

function Base.reshape(A::AxisArray, shp::Tuple{Vararg{Union{Int,Colon},N}}) where {N}
    p = reshape(parent(A), shp)
    return AxisArray(p, reshape_axes(naxes(A, Val(N)), axes(p)))
end
=#

