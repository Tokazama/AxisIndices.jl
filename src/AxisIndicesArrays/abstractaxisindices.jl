
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


# TODO this should all be derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

const AbstractAxisIndicesMatrix{T,P<:AbstractMatrix{T},A1,A2} = AbstractAxisIndices{T,2,P,Tuple{A1,A2}}

const AbstractAxisIndicesVector{T,P<:AbstractVector{T},A1} = AbstractAxisIndices{T,1,P,Tuple{A1}}

const AbstractAxisIndicesVecOrMat{T} = Union{<:AbstractAxisIndicesMatrix{T},<:AbstractAxisIndicesVector{T}}

function values_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI}
    return map(valtype, AI.parameters)
end

Base.has_offset_axes(A::AbstractAxisIndices) = Base.has_offset_axes(parent(A))

# axes
StaticRanges.axes_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI} = AI

function Base.axes(x::AbstractAxisIndices{T,N}, i::Integer) where {T,N}
    if i > N
        return as_axis(x, 1)
    else
        return getfield(axes(x), i)
    end
end

# size
Base.size(x::AbstractAxisIndices, i) = length(axes(x, i))

Base.size(x::AbstractAxisIndices) = map(length, axes(x))

# parent
StaticRanges.parent_type(::Type{<:AbstractAxisIndices{T,N,P}}) where {T,N,P} = P

Base.parentindices(x::AbstractAxisIndices) = axes(parent(x))

# length
Base.length(x::AbstractAxisIndices) = prod(size(x))

function keys_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI}
    return map(keytype, AI.parameters)
end

## return axes even when they are permuted
function Base.axes(a::PermutedDimsArray{T,N,permin,permout,<:AbstractAxisIndices}) where {T,N,permin,permout}
    return permute_axes(parent(a), permin)
end

function Base.similar(
    a::AbstractAxisIndices{T,N},
    eltype::Type=T,
    dims::Tuple{Vararg{Int,M}}=size(a)
) where {T,N,M}

    return unsafe_reconstruct(
        a,
        similar(parent(a), eltype, dims),
        ntuple(i -> resize_last(axes(a, i), getfield(dims, i)), M)
    )
end

function Base.similar(
    a::AbstractAxisIndices{T},
    inds::Tuple{Vararg{<:AbstractVector,N}}
) where {T,N}

    p = similar(parent(a), T, map(length, inds))
    axs = as_axes(p, inds, axes(p))
    return unsafe_reconstruct(a, p, axs)
end

function Base.similar(
    a::AbstractAxisIndices,
    ::Type{T},
    inds::Tuple{Vararg{<:AbstractVector,N}}
) where {T,N}

    p = similar(parent(a), T, map(length, inds))
    axs = as_axes(a, inds, axes(p))
    return unsafe_reconstruct(a, p, axs)
end

"""
    unsafe_reconstruct(A::AbstractAxisIndices, parent, axes)

Reconstructs an `AbstractAxisIndices` of the same type as `A` but with the parent
array `parent` and axes `axes`. This method depends on an underlying call to
`similar_types`. It is considered unsafe because it bypasses safety checks to
ensure the keys of each axis are unique and match the length of each dimension of
`parent`. Therefore, this is not intended for interactive use and should only be
used when it is clear all arguments are composed correctly.
"""
function unsafe_reconstruct(A::AbstractAxisIndices, p::P, axs::Axs) where {P,Axs}
    return similar_type(A, P, Axs)(p, axs)
end

function Base.reinterpret(::Type{T}, A::AbstractAxisIndices) where {T}
    p = reinterpret(T, parent(A))
    axs = map(resize_last, axes(A), size(p))
    return unsafe_reconstruct(A, p, axs)
end

