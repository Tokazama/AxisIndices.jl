
###
### AbstractAxisIndicesa interface
###
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

"""
    indices(x, i)

Returns the indices corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
UnitMRange(1:2)
```
"""
indices(x, i) = values(axes(x, i))

function keys_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI}
    return map(keytype, AI.parameters)
end

"""
    indices(x)

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(UnitMRange(1:2), UnitMRange(1:2))
```
"""
indices(x) = map(values, axes(x))
indices(x::AbstractAxis) = values(x)

## return axes even when they are permuted
function Base.axes(a::PermutedDimsArray{T,N,permin,permout,<:AbstractAxisIndices}) where {T,N,permin,permout}
    return permute_axes(parent(a), permin)
end


###
### similar
###

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

###
### AxisIndicesArray
###
"""
    AxisIndicesArray{T,N,P,AI}

An array struct that wraps any parent array and assigns it an `AbstractAxis` for
each dimension. The first argument is the parent array and the second argument is
a tuple of subtypes to `AbstractAxis` or keys that will be converted to subtypes
of `AbstractAxis` with the provided keys.
"""
struct AxisIndicesArray{T,N,P<:AbstractArray{T,N},AI<:AbstractAxes{N}} <: AbstractAxisIndices{T,N,P,AI}
    parent::P
    axes::AI

    function AxisIndicesArray{T,N,P,A}(p::P, axs::A, check_length::Bool=true) where {T,N,P,A}
       return new{T,N,P,A}(p, axs)
    end
end

"""
    AxisIndicesArray(parent::AbstractArray, axes::Tuple{Vararg{AbstractAxis}}[, check_length=true])

Construct an `AxisIndicesArray` using `parent` and explicit subtypes of `AbstractAxis`.
If `check_length` is `true` then each dimension of parent's length is checked to match
the length of the corresponding axis (e.g., `size(parent 1) == length(axes[1])`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndicesArray(ones(2,2), (SimpleAxis(2), SimpleAxis(2)))
2-dimensional AxisIndicesArray{Float64,2,Array{Float64,2}...}
        1     2
  1   1.0   1.0
  2   1.0   1.0


```
"""
function AxisIndicesArray(x::AbstractArray{T,N}, axs::AbstractAxes{N}, check_length::Bool=true) where {T,N}
    return AxisIndicesArray{T,N,typeof(x),typeof(axs)}(x, axs, check_length)
end

# minimum interface
Base.parent(x::AxisIndicesArray) = getfield(x, :parent)

Base.axes(x::AxisIndicesArray) = getfield(x, :axes)

function StaticRanges.similar_type(
    ::AxisIndicesArray{T,N,P,AI},
    ptype::Type=P,
    axstype::Type=AI
) where {T,N,P,AI}

    return AxisIndicesArray{eltype(ptype), ndims(ptype), ptype, axstype}
end

"""
    AxisIndicesArray(parent::AbstractArray, keys::Tuple[, values=axes(parent), check_length=true])

Given an the some array `parent` and a tuple of vectors `keys` corresponding to
each dimension of `parent` constructs an `AxisIndicesArray`. Each element of `keys`
is paired with an element of `values` to compose a subtype of `AbstractAxis`.
`values` map the `keys` to the indices of `parent`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndicesArray(ones(2,2), (["a", "b"], ["one", "two"]))
2-dimensional AxisIndicesArray{Float64,2,Array{Float64,2}...}
      one   two
  a   1.0   1.0
  b   1.0   1.0


```
"""
function AxisIndicesArray(x::AbstractArray{T,N}, axis_keys::Tuple, axis_values::Tuple=axes(x), check_length::Bool=true) where {T,N}
    axs = as_axes(x, axis_keys, axis_values, check_length)
    return AxisIndicesArray{T,N,typeof(x),typeof(axs)}(x, axs, check_length)
end

"""
    AxisIndicesArray(parent::AbstractArray, args...) -> AxisIndicesArray(parent, tuple(args))

Passes `args` to a tuple for constructing an `AxisIndicesArray`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = AxisIndicesArray(reshape(1:9, 3,3), 2:4, 3.0:5.0);

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
AxisIndicesArray(x::AbstractArray, args...) = AxisIndicesArray(x, args)

###
### LinearAxes
###
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

LinearAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = LinearIndices(as_axis.(ks))
LinearAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = LinearIndices(ks)

Base.axes(A::LinearAxes) = getfield(A, :indices)

function Base.getindex(iter::LinearAxes, i::Int)
    Base.@_inline_meta
    @boundscheck checkbounds(iter, i)
    return i
end

function Base.getindex(A::LinearAxes, inds...)
    Base.@_propagate_inbounds_meta
    return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end

###
### CartesianAxes
###
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


CartesianAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = CartesianIndices(as_axis.(ks))
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

