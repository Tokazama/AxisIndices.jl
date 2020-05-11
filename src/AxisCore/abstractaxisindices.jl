
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

"""
    axes_keys(x::AbstractArray)

Returns the keys corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(2:3, 3:4)

julia> axes_keys(Axis(1:2))
(1:2,)
```
"""
axes_keys(x) = map(keys, axes(x))
axes_keys(x::AbstractAxis) = (keys(x),)

"""
    axes_keys(x, i)

Returns the axis keys corresponding of ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
2:3
```
"""
axes_keys(x, i) = axes_keys(x)[i]

"""
    keys_type(x, i)

Retrieves axis keys of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys_type(AxisIndicesArray([1], ["a"]), 1)
Array{String,1}
```
"""
keys_type(::T, i) where {T} = keys_type(T, i)
keys_type(::Type{T}, i) where {T} = keys_type(axes_type(T, i))

"""
    values_type(x, i)

Retrieves axis values of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> values_type([1], 1)
Base.OneTo{Int64}

julia> values_type(typeof([1]), 1)
Base.OneTo{Int64}
```
"""
values_type(::T, i) where {T} = values_type(T, i)
values_type(::Type{T}, i) where {T} = values_type(axes_type(T, i))

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

"""
    indices(x)

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(Base.OneTo(2), Base.OneTo(2))

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x) = map(values, axes(x))

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
### similar_axes
###
#=
We assume that if the user provide a subtype of AbstractAxis as the keys argument
that they intended to fully replace the corresponding axis with the new type
=#
# similar_axes iterates over old axes and new indices with provided keys to try
# to reach an agreement
function similar_axes(old_axes::Tuple, new_keys::Tuple, new_indices::Tuple, check_length::Bool=true)
    return (to_axis(first(old_axes), first(new_keys), first(new_indices), check_length),
            similar_axes(tail(old_axes), tail(new_keys), tail(new_indices), check_length)...)
end

function similar_axes(old_axes::Tuple, new_keys::Tuple{}, new_indices::Tuple, check_length::Bool=true)
    return (resize_last(first(old_axes), first(new_indices)),
            similar_axes(tail(old_axes), (), tail(new_indices), check_length)...)
end

function similar_axes(old_axes::Tuple{}, new_keys::Tuple, new_indices::Tuple, check_length::Bool=true)
    return (to_axis(first(new_keys), first(new_indices)),
            similar_axes((), tail(new_keys), tail(new_indices), check_length)...)
end

function similar_axes(old_axes::Tuple{}, new_keys::Tuple{}, new_indices::Tuple, check_length::Bool=true)
    return (to_axis(nothing, first(new_indices)), similar_axes((), (), tail(new_indices), check_length)...)
end

function similar_axes(old_axes::Tuple{}, new_keys::Tuple, new_indices::Tuple{}, check_length::Bool=true)
    return (to_axis(first(new_keys)),
            #similar_axis(nothing, first(new_keys), nothing, check_length),
            similar_axes((), tail(new_keys), (), check_length)...)
end

similar_axes(::Tuple{}, ::Tuple{}, ::Tuple{}, check_length::Bool) = ()
similar_axes(::Tuple, ::Tuple{}, ::Tuple{}, check_length::Bool) = ()

###
### similar
###
function Base.similar(a::AbstractAxisIndices, dims::Tuple{Vararg{Int}})
    p = similar(parent(a), dims)
    return unsafe_reconstruct(a, p, similar_axes(axes(a), (), axes(p)))
end

function Base.similar(
    a::AbstractAxisIndices{T},
    new_keys::Tuple{Vararg{<:AbstractVector,N}}
) where {T,N}

    p = similar(parent(a), T, map(length, new_keys))
    axs = similar_axes(axes(a), new_keys, axes(p))
    return unsafe_reconstruct(a, p, axs)
end

function Base.similar(
    a::AbstractAxisIndices,
    ::Type{T},
    new_keys::Tuple{Vararg{<:AbstractVector,N}}
) where {T,N}

    p = similar(parent(a), T, map(length, new_keys))
    return unsafe_reconstruct(a, p, similar_axes(axes(a), new_keys, axes(p)))
end

# Necessary to avoid ambiguities with OffsetArrays
function Base.similar(a::AbstractAxisIndices, ::Type{T}, dims::Tuple{Vararg{Int}}) where {T}
    p = similar(parent(a), T, dims)
    return unsafe_reconstruct(a, p, similar_axes(axes(a), (), axes(p)))
end

function Base.similar(a::AbstractAxisIndices, ::Type{T}) where {T}
    p = similar(parent(a), T)
    return unsafe_reconstruct(a, p, similar_axes(axes(a), (), axes(p)))
end

function Base.similar(
    a::AbstractAxisIndices,
    ::Type{T},
    new_keys::Tuple{Union{Base.IdentityUnitRange, OneTo, UnitRange},Vararg{Union{Base.IdentityUnitRange, OneTo, UnitRange},N}}
) where {T, N}

    p = similar(parent(a), T, map(length, new_keys))
    return unsafe_reconstruct(a, p, similar_axes(axes(a), new_keys, axes(p)))
end

function Base.similar(
    A::AbstractAxisIndices,
    ::Type{T},
    new_keys::Tuple{OneTo,Vararg{OneTo,N}}
) where {T, N}

    p = similar(parent(A), T, map(length, new_keys))
    return unsafe_reconstruct(A, p, similar_axes(axes(A), new_keys, axes(p)))
end

Base.has_offset_axes(A::AbstractAxisIndices) = Base.has_offset_axes(parent(A))

