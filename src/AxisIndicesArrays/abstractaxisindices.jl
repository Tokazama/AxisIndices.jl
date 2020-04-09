
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

Base.has_offset_axes(A::AbstractAxisIndices) = Base.has_offset_axes(parent(A))

# axes
StaticRanges.axes_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI} = AI

function Base.axes(x::AbstractAxisIndices{T,N}, i::Integer) where {T,N}
    if i > N
        return SimpleAxis(1)
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

## return axes even when they are permuted
function Base.axes(a::PermutedDimsArray{T,N,permin,permout,<:AbstractAxisIndices}) where {T,N,permin,permout}
    return permute_axes(parent(a), permin)
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
function AxisIndexing.unsafe_reconstruct(A::AbstractAxisIndices, p::P, axs::Ax) where {P,Ax}
    return similar_type(A, P, Ax)(p, axs)
end

# FIXME
# When I use Val(N) on the tuple the it spits out many lines of extra code.
# But without it it loses inferrence
function Base.reinterpret(::Type{Tnew}, A::AbstractAxisIndices{Told,N}) where {Tnew,Told,N}
    p = reinterpret(Tnew, parent(A))
    axs = ntuple(N) do i
        resize_last(axes(A, i), size(p, i))
    end
    return unsafe_reconstruct(A, p, axs)
end

function Base.resize!(x::AbstractAxisIndices{T,1}, n::Integer) where {T}
    resize!(parent(x), n)
    resize_last!(axes(x, 1), n)
    return x
end

function Base.similar(a::AbstractAxisIndices, dims::Tuple{Vararg{Int}})
    p = similar(parent(a), dims)
    axs = AxisIndexing.similar_axes(axes(a), (), axes(p))
    return unsafe_reconstruct(a, p, axs)
end

function Base.similar(
    a::AbstractAxisIndices{T},
    new_keys::Tuple{Vararg{<:AbstractVector,N}}
) where {T,N}

    p = similar(parent(a), T, map(length, new_keys))
    axs = AxisIndexing.similar_axes(axes(a), new_keys, axes(p))
    return unsafe_reconstruct(a, p, axs)
end

function Base.similar(
    a::AbstractAxisIndices,
    ::Type{T},
    new_keys::Tuple{Vararg{<:AbstractVector,N}}
) where {T,N}

    p = similar(parent(a), T, map(length, new_keys))
    axs = AxisIndexing.similar_axes(axes(a), new_keys, axes(p))
    return unsafe_reconstruct(a, p, axs)
end

###
### Necessary to avoid ambiguities with OffsetArrays
###

function Base.similar(a::AbstractAxisIndices, ::Type{T}, dims::Tuple{Vararg{Int}}) where {T}
    p = similar(parent(a), T, dims)
    axs = AxisIndexing.similar_axes(axes(a), (), axes(p))
    return unsafe_reconstruct(a, p, axs)
end

function Base.similar(a::AbstractAxisIndices, ::Type{T}) where {T,N,M}
    p = similar(parent(a), T)
    axs = AxisIndexing.similar_axes(axes(a), (), axes(p))
    return unsafe_reconstruct(a, p, axs)
end

function Base.similar(
    a::AbstractAxisIndices,
    ::Type{T},
    new_keys::Tuple{Union{Base.IdentityUnitRange, OneTo, UnitRange},Vararg{Union{Base.IdentityUnitRange, OneTo, UnitRange},N}}
) where {T, N}

    p = similar(parent(a), T, map(length, new_keys))
    axs = AxisIndexing.similar_axes(axes(a), new_keys, axes(p))
    return unsafe_reconstruct(a, p, axs)
end

function Base.similar(
    A::AbstractAxisIndices,
    ::Type{T},
    new_keys::Tuple{OneTo,Vararg{OneTo,N}}
) where {T, N}

    p = similar(parent(A), T, map(length, new_keys))
    axs = AxisIndexing.similar_axes(axes(A), new_keys, axes(p))
    return unsafe_reconstruct(A, p, axs)
end

#= TODO delet if we can just be explicit about this
function Base.similar(
    a::AbstractAxisIndices{T,N},
    t::Type=T,
    dims::Tuple{Vararg{Int,M}}=size(a)
) where {T,N,M}

    return similar(a, t, ntuple(OneTo, Val(M)))
end
=#
