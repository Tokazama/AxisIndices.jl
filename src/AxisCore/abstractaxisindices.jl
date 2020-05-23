
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

const AbstractAxisIndicesMatrix{T,P<:AbstractMatrix{T},A1,A2} = AbstractAxisIndices{T,2,P,Tuple{A1,A2}}

const AbstractAxisIndicesVector{T,P<:AbstractVector{T},A1} = AbstractAxisIndices{T,1,P,Tuple{A1}}

const AbstractAxisIndicesVecOrMat{T} = Union{<:AbstractAxisIndicesMatrix{T},<:AbstractAxisIndicesVector{T}}

StaticRanges.parent_type(::Type{<:AbstractAxisIndices{T,N,P}}) where {T,N,P} = P

Base.IndexStyle(::Type{<:AbstractAxisIndices{T,N,A,AI}}) where {T,N,A,AI} = IndexStyle(A)

Base.parentindices(x::AbstractAxisIndices) = axes(parent(x))

Base.length(x::AbstractAxisIndices) = prod(size(x))

Base.size(x::AbstractAxisIndices) = map(length, axes(x))

StaticRanges.axes_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI} = AI

function Base.axes(x::AbstractAxisIndices{T,N}, i::Integer) where {T,N}
    if i > N
        return SimpleAxis(1)
    else
        return getfield(axes(x), i)
    end
end

# this only works if the axes are the same size
function unsafe_reconstruct(A::AbstractAxisIndices{T1,N}, p::AbstractArray{T2,N}) where {T1,T2,N}
    return unsafe_reconstruct(A, p, map(assign_indices,  axes(A), axes(p)))
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
function unsafe_reconstruct(A::AbstractAxisIndices, p::AbstractArray, axs::Tuple)
    return similar_type(A, typeof(p), typeof(axs))(p, axs)
end

###
### similar
###
@inline function Base.similar(A::AbstractAxisIndices{T}, dims::NTuple{N,Int}) where {T,N}
    return similar(A, T, dims)
end

@inline function Base.similar(A::AbstractAxisIndices{T}, ks::Tuple{Vararg{<:AbstractVector,N}}) where {T,N}
    return similar(A, T, ks)
end

@inline function Base.similar(A::AbstractAxisIndices, ::Type{T}, ks::Tuple{Vararg{<:AbstractVector,N}}) where {T,N}
    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false))
end

# Necessary to avoid ambiguities with OffsetArrays
@inline function Base.similar(A::AbstractAxisIndices, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    p = similar(parent(A), T, dims)
    return unsafe_reconstruct(A, p, to_axes(axes(A), (), axes(p)))
end

function Base.similar(A::AbstractAxisIndices, ::Type{T}) where {T}
    p = similar(parent(A), T)
    return unsafe_reconstruct(A, p, map(assign_indices, axes(A), axes(p)))
end

function Base.similar(
    A::AbstractAxisIndices,
    ::Type{T},
    ks::Tuple{Union{Base.IdentityUnitRange, OneTo, UnitRange},Vararg{Union{Base.IdentityUnitRange, OneTo, UnitRange},N}}
) where {T, N}

    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false))
end

function Base.similar(A::AbstractAxisIndices, ::Type{T}, ks::Tuple{OneTo,Vararg{OneTo,N}}) where {T, N}
    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false))
end

function Base.similar(::Type{T}, ks::AbstractAxes{N}) where {T<:AbstractArray, N}
    p = similar(T, map(length, ks))
    axs = to_axes((), ks, axes(p), false)
    return AxisIndicesArray{eltype(T),N,typeof(p),typeof(axs)}(p, axs)
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

function Base.reverse(x::AbstractAxisIndices{T,1}) where {T}
    p = reverse(parent(x))
    return unsafe_reconstruct(x, p, (reverse_keys(axes(x, 1), axes(p, 1)),))
end

function Base.reverse(x::AbstractAxisIndices{T,N}; dims::Integer) where {T,N}
    p = reverse(parent(x), dims=dims)
    axs = ntuple(Val(N)) do i
        if i in dims
            reverse_keys(axes(x, i), axes(p, i))
        else
            assign_indices(axes(x, i), axes(p, i))
        end
    end
    return unsafe_reconstruct(x, p, axs)
end
