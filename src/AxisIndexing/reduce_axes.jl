
"""
    reduce_axes(a, dims)

Returns the appropriate axes for a measure that reduces dimensions along the
dimensions `dims`.

## Example
```jldoctest
julia> using AxisIndices

julia> AxisIndices.reduce_axes(rand(2, 4), 2)
(Base.OneTo(2), Base.OneTo(1))

julia> AxisIndices.reduce_axes(rand(2, 4), (1,2))
(Base.OneTo(1), Base.OneTo(1))

julia> AxisIndices.reduce_axes(rand(2, 4), :)
()

julia> AxisIndices.reduce_axes((Axis(1:4), Axis(1:4)), 2)
(Axis(1:4 => Base.OneTo(4)), Axis(1:1 => Base.OneTo(1)))
```
"""
reduce_axes(x::AbstractArray, dims) = reduce_axes(axes(x), dims)
reduce_axes(x::Tuple, dims) = _reduce_axes(x, dims)
reduce_axes(x::Tuple, dims::Colon) = ()
_reduce_axes(x::Tuple{Vararg{Any,D}}, dims::Int) where {D} = _reduce_axes(x, (dims,))
function _reduce_axes(x::Tuple{Vararg{Any,D}}, dims::Tuple{Vararg{Int}}) where {D}
    Tuple(map(i -> ifelse(in(i, dims), reduce_axis(x[i]), x[i]), 1:D))
end

"""
    reduce_axis(a)

Reduces axis `a` to single value. Allows custom index types to have custom
behavior throughout reduction methods (e.g., sum, prod, etc.)

See also: [`reduce_axes`](@ref)

## Example
```jldoctest
julia> using AxisIndices

julia> AxisIndices.reduce_axis(Axis(1:4))
Axis(1:1 => Base.OneTo(1))

julia> AxisIndices.reduce_axis(1:4)
1:1
```
"""
function reduce_axis(x)
    if isempty(x)
        error("Cannot reduce empty index.")
    else
        return set_length(x, 1)
    end
end

