
"""
    CoreIndexing
"""
module CoreIndexing

#=
@inline function Base.getindex(iter::CartesianIndices{N,R}, I::Vararg{Int, N}) where {N,R}
    @boundscheck checkbounds(iter, I...)
    CartesianIndex(I .- first.(Base.axes1.(iter.indices)) .+ first.(iter.indices))
end

CartesianIndices{N,NTuple{N,<:AbstractAxis}} where N
=#

#=

"""
    LinearAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> linaxes = LinearAxes((Axis(2.0:5.0), Axis(1:4)));

julia> lininds = LinearIndices((1:4, 1:4));

julia> linaxes[2, 2]
6

julia> lininds[2, 2]
6
```
"""
const LinearAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = LinearIndices{N,R}

LinearAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = LinearIndices(map(to_axis, ks))

Base.axes(A::LinearAxes) = getfield(A, :indices)

@boundscheck function Base.getindex(iter::LinearAxes, i::Int)
    @boundscheck if !in(i, eachindex(iter))
        throw(BoundsError(iter, i))
    end
    return i
end

@propagate_inbounds function Base.getindex(A::LinearAxes, inds...)
    return Base._getindex(IndexStyle(A), A, Interface.to_indices(A, Tuple(inds))...)
end


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

_cartesian_axes(axs::Tuple{}) = ()
_cartesian_axes(axs::Tuple) = (to_axis(first(axs)), _cartesian_axes(tail(axs))...)

CartesianAxes(axs::Tuple{Vararg{Any,N}}) where {N} = CartesianIndices(_cartesian_axes(axs))

Base.axes(A::CartesianAxes) = getfield(A, :indices)

@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}},
    inds::Vararg{Int}
) where {N}

    return CartesianIndex(map(getindex, axes(A), inds))
end

Base.getindex(A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}}, ::Ellipsis) where {N} = A

@propagate_inbounds function Base.getindex(
    A::CartesianAxes{N,<:NTuple{N,<:AbstractAxis}},
    inds...
) where {N}

    return Base._getindex(IndexStyle(A), A, Interface.to_indices(A, Tuple(inds))...)
end

@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}},
    inds::Vararg{Int,N}
) where {N}

    return CartesianIndex(Interface.to_indices(A, Tuple(inds)))
end
=#

end

