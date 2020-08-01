
"""
    is_indices_axis(x) -> Bool

If `true` then `x` is an axis type where the only field parameterizing the axis
is a field for the values.
"""
is_indices_axis(x) = is_indices_axis(typeof(x))
is_indices_axis(::Type{T}) where {T<:AbstractUnitRange{<:Integer}} = true
is_indices_axis(::Type{T}) where {T} = false

"""
    indices_type(x, i)

Retrieves axis values of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices_type([1], 1)
Base.OneTo{Int64}

julia> indices_type(typeof([1]), 1)
Base.OneTo{Int64}
```
"""
indices_type(::T, i) where {T} = indices_type(T, i)
indices_type(::Type{T}, i) where {T} = indices_type(axes_type(T, i))

"""
    indices(x::AbstractUnitRange)

Returns the indices `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x::AbstractUnitRange) = values(x)
indices(x::CartesianIndex) = getfield(x, :I)

"""
    indices(x, i)

Returns the indices corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisArray(ones(2,2), (2:3, 3:4)), 1)
Base.OneTo(2)
```
"""
indices(x, i) = values(axes(x, i))

"""
    indices(x) -> Tuple

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisArray(ones(2,2), (2:3, 3:4)))
(Base.OneTo(2), Base.OneTo(2))

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x) = map(values, axes(x))

"""
    indices_type(x)

Retrieves the type of the values of `x`. This should be functionally equivalent
to `typeof(values(x))`.

## Examples
```jldoctest
julia> using AxisIndices

julia>  indices_type(Axis(1:2))
Base.OneTo{Int64}

julia> indices_type(typeof(Axis(1:2)))
Base.OneTo{Int64}

julia> indices_type(typeof(1:2))
UnitRange{Int64}
```
"""
indices_type(::T) where {T} = indices_type(T)
indices_type(::Type{T}) where {T} = T  

#= assign_indices(axis, indices)

Reconstructs `axis` but with `indices` replacing the indices/values.
There shouldn't be any change in size of the indices.
=#
function assign_indices(axis, inds)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, keys(axis), inds)
    end
end

