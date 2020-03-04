
"""
    AbstractAxisIndices

`AbstractAxisIndices` is a subtype of `AbstractArray` that offers integration with the `AbstractAxis` interface.
The only methods that absolutely needs to be defined for a subtype of `AbstractAxisIndices` are `axes`, `parent`, `similar_type`, and `similar`.
Most users should find the provided [`AxisIndicesArray`](@ref) subtype is sufficient for the majority of use cases.
Although custom behavior may be accomplished through a new subtype of `AbstractAxisIndices`, customizing the behavior of many methods described herein can be accomplished through a unique subtype of `AbstractAxis`.

This implementation is meant to be basic, well documented, and have sane defaults that can be overridden as necessary.
In other words, default methods for manipulating arrays that return an `AxisIndicesArray` should not cause unexpected downstream behavior for users;
and developers should be able to freely customize the behavior of `AbstractAxisIndices` subtypes with minimal effort. 
"""
abstract type AbstractAxisIndices{T,N,P,AI} <: AbstractArray{T,N} end


# TODO this should all derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

const AbstractAxisIndicesMatrix{T,P<:AbstractMatrix{T},A1,A2} = AbstractAxisIndices{T,2,P,Tuple{A1,A2}}

const AbstractAxisIndicesVector{T,P<:AbstractVector{T},A1} = AbstractAxisIndices{T,1,P,Tuple{A1}}

const AbstractAxisIndicesVecOrMat{T} = Union{<:AbstractAxisIndicesMatrix{T},<:AbstractAxisIndicesVector{T}}

"""
    AxisIndicesArray(parent_array, tuple_of_keys) -> AxisIndicesArray(parent_array, Axis.(tuple_of_keys))
    AxisIndicesArray(parent_array, tuple_of_axis) -> AxisIndicesArray

An array struct that wraps any parent array and assigns it an `AbstractAxis` for
each dimension. The first argument is the parent array and the second argument is
a tuple of subtypes to `AbstractAxis` or keys that will be converted to subtypes
of `AbstractAxis` with the provided keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = AxisIndicesArray(reshape(1:9, 3,3), (2:4, 3.0:5.0));

julia> A[1, 1]
1

julia> A[==(2), ==(3.0)]
1

julia> A[1:2, 1:2] == [1 4; 2 5]
true

julia> A[<(4), <(5.0)] == [1 4; 2 5]
true
```
"""
struct AxisIndicesArray{T,N,P<:AbstractArray{T,N},AI<:Tuple{Vararg{<:AbstractAxis,N}}} <: AbstractAxisIndices{T,N,P,AI}
    parent::P
    axes::AI

    function AxisIndicesArray{T,N,P,A}(p::P, axs::A, check_length::Bool=true) where {T,N,P,A}
        if check_length
            for (i, axs_i) in enumerate(axs)
                if size(p, i) != length(axs_i)
                    error("All keys and values must have the same length as the respective axes of the parent array, got size(parent, $i) = $(size(p, i)) and length(key_i) = $(length(axs_i))")
                else
                    continue
                end
            end
        end
        return new{T,N,P,A}(p, axs)
    end
end

function AxisIndicesArray(x::AbstractArray{T,N}, axs::Tuple=axes(x), check_length::Bool=true) where {T,N}
    axs = map(as_axis, axs)
    return AxisIndicesArray{T,N,typeof(x),typeof(axs)}(x, axs, check_length)
end

###
### values
###
function values_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI}
    return map(valtype, AI.parameters)
end

"""
    indices(x)

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(Base.OneTo(2), Base.OneTo(2))
```
"""
indices(x) = map(values, axes(x))

"""
    indices(x, i)

Returns the indices corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
Base.OneTo(2)
```
"""
indices(x, i) = values(axes(x, i))

function keys_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI}
    return map(keytype, AI.parameters)
end


"""
    keys(x::AbstractAxisIndices)

Returns the keys corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(2:3, 3:4)
"""
Base.keys(x::AbstractAxisIndices) = map(keys, axes(x))

"""
    keys(x::AbstractAxisIndices, i)

Returns the keys corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
2:3
```
"""
Base.keys(x::AbstractAxisIndices, i) = keys(axes(x, i))

###
### length
###
Base.length(x::AbstractAxisIndices) = prod(size(x))

###
### size
###
Base.size(x::AbstractAxisIndices, i) = length(axes(x, i))

Base.size(x::AbstractAxisIndices) = map(length, axes(x))

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


CartesianAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = CartesianIndices(as_axis.(ks))
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

LinearAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = LinearIndices(as_axis.(ks))
LinearAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = LinearIndices(ks)


function Base.getindex(iter::LinearAxes, i::Int)
    Base.@_inline_meta
    @boundscheck checkbounds(iter, i)
    return i
end

function Base.getindex(A::LinearAxes, inds...)
    Base.@_propagate_inbounds_meta
    return Base._getindex(IndexStyle(A), A, to_indices(A, axes(A), Tuple(inds))...)
end

###
### axes
###

StaticRanges.axes_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI} = AI

Base.axes(x::AxisIndicesArray) = getfield(x, :axes)

Base.axes(x::AbstractAxisIndices, i::Integer) = getfield(axes(x), i)

Base.axes(A::LinearAxes) = getfield(A, :indices)

Base.axes(A::CartesianAxes) = getfield(A, :indices)

###
### parent
###

StaticRanges.parent_type(::Type{<:AbstractAxisIndices{T,N,P}}) where {T,N,P} = P

Base.parentindices(x::AbstractAxisIndices) = axes(parent(x))

Base.parent(x::AxisIndicesArray) = getfield(x, :parent)

###
### similar
###

function StaticRanges.similar_type(
    ::AxisIndicesArray{T,N,P,AI},
    ptype::Type=P,
    axstype::Type=AI
) where {T,N,P,AI}

    return AxisIndicesArray{eltype(ptype), ndims(ptype), ptype, axstype}
end

function Base.similar(
    a::AxisIndicesArray{T},
    eltype::Type=T,
    dims::Tuple{Vararg{Int}}=size(a)
) where {T}

    return AxisIndicesArray(similar(parent(a), eltype, ))
end

function Base.similar(
    a::AxisIndicesArray{T},
    inds::Tuple{Vararg{<:AbstractVector,N}}
   ) where {T,N}

    return AxisIndicesArray(similar(parent(a), T, map(length, inds)), inds)
end

function Base.similar(
    a::AxisIndicesArray{T},
    eltype::Type,
    inds::Tuple{Vararg{<:AbstractVector,N}}
) where {T,N}

    return AxisIndicesArray(similar(parent(a), eltype, map(length, inds)), inds)
end

