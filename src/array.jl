
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

StaticRanges.parent_type(::Type{<:AbstractAxisIndices{T,N,P}}) where {T,N,P} = P
StaticRanges.axes_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI} = AI

Base.parentindices(x::AbstractAxisIndices) = axes(parent(x))

Base.axes(x::AbstractAxisIndices, i::Integer) = getfield(axes(x), i)

Base.size(x::AbstractAxisIndices, i) = length(axes(x, i))

Base.size(x::AbstractAxisIndices) = map(length, axes(x))

Base.length(x::AbstractAxisIndices) = prod(size(x))

# TODO this should all derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

const AbstractAxisIndicesMatrix{T,P<:AbstractMatrix{T},A1,A2} = AbstractAxisIndices{T,2,P,Tuple{A1,A2}}

const AbstractAxisIndicesVector{T,P<:AbstractVector{T},A1} = AbstractAxisIndices{T,1,P,Tuple{A1}}

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

Base.parent(x::AxisIndicesArray) = getfield(x, :parent)

Base.axes(x::AxisIndicesArray) = getfield(x, :axes)

function AxisIndicesArray(x::AbstractArray{T,N}, axs::Tuple=axes(x), check_length::Bool=true) where {T,N}
    axs = map(to_axis, axs)
    return AxisIndicesArray{T,N,typeof(x),typeof(axs)}(x, axs, check_length)
end

function StaticRanges.similar_type(::AxisIndicesArray{T,N,P,AI}, ptype::Type=P, axstype::Type=AI) where {T,N,P,AI}
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

