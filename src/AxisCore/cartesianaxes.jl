
"""
    CartesianAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> cartaxes = CartesianAxes((Axis(2.0:5.0), Axis(1:4)));

julia> cartinds = CartesianIndices((1:4, 1:4));

julia> cartaxes[2, 2]
CartesianIndex(2, 2)

julia> cartinds[2, 2]
CartesianIndex(2, 2)
```
"""
const CartesianAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = CartesianIndices{N,R}

function CartesianAxes(ks::Tuple{Vararg{<:Integer,N}}) where {N}
    return CartesianIndices(map(SimpleAxis, ks))
end

function CartesianAxes(ks::Tuple{Vararg{<:Any,N}}) where {N}
    return CartesianIndices(ntuple(i -> to_axis(getfield(ks, i), false), Val(N)))
end

CartesianAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = CartesianIndices(ks)

Base.axes(A::CartesianAxes) = getfield(A, :indices)

function Base.getindex(A::CartesianAxes, inds::Vararg{Int})
    Base.@_propagate_inbounds_meta
    return CartesianIndex(map(getindex, axes(A), inds))
end

function Base.getindex(A::CartesianAxes, inds...)
    Base.@_propagate_inbounds_meta
    return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end

