
to_axis(x) = Axis(x)
to_axis(i::Integer) = SimpleAxis(OneTo(i))
to_axis(x::AbstractAxis) = x

to_axis(x::AbstractArray, axs::Tuple) = map(axs_i -> to_axis(x, axs_i), axs)

to_axis(::T, axis::AbstractAxis) where {T} = axis
function to_axis(::T, axis::Union{OneTo,OneToSRange,OneToMRange}) where {T}
    if is_static(T)
        return SimpleAxis(as_static(axis))
    elseif is_fixed(T)
        return SimpleAxis(as_fixed(axis))
    else
        return SimpleAxis(as_dynamic(axis))
    end
end

function to_axis(::T, axis) where T
    if is_static(T)
        return Axis(as_static(axis))
    elseif is_fixed(T)
        return Axis(as_fixed(axis))
    else
        return Axis(as_dynamic(axis))
    end
end

"""
    CartesianAxes
Alias for LinearIndices where indices are subtypes of `AbstractAxis`.
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

Base.axes(A::CartesianAxes) = getfield(A, :indices)

CartesianAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = CartesianIndices(to_axis.(ks))
CartesianAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = CartesianIndices(ks)

#=
function Base.getindex(A::CartesianAxes{N}, inds::CartesianIndex{N}) where {N}
    Base.@_propagate_inbounds_meta
    return CartesianIndex(map(getindex, axes(A), inds.I))
end
=#

function Base.getindex(A::CartesianAxes, inds::Vararg{Int})
    Base.@_propagate_inbounds_meta
    #return Base._getindex(IndexStyle(A), A, to_indices(A, A.indices, Tuple(inds))...)
    return CartesianIndex(map(getindex, axes(A), inds))
end

function Base.getindex(A::CartesianAxes, inds...)
    Base.@_propagate_inbounds_meta
    return Base._getindex(IndexStyle(A), A, to_indices(A, A.indices, Tuple(inds))...)
end

"""
    LinearAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.
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

LinearAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = LinearIndices(to_axis.(ks))
LinearAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = LinearIndices(ks)

Base.axes(A::LinearAxes) = getfield(A, :indices)

function Base.getindex(iter::LinearAxes, i::Int)
    Base.@_inline_meta
    @boundscheck checkbounds(iter, i)
    return i
end

function Base.getindex(A::LinearAxes, inds...)
    Base.@_propagate_inbounds_meta
    return Base._getindex(IndexStyle(A), A, to_indices(A, axes(A), Tuple(inds))...)
end

