
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

function CartesianAxes(axs::Tuple{Vararg{Any,N}}) where {N}
    return CartesianIndices(map(axis -> compose_axis(axis, _inds(axis)), axs))
end

# compose_axis(axis, checks) doesn't assume one based indexing in case a range is
# passed without it, but we want to assume that's what we have here unless an axplicit
# instance of AbstractAxis is passed
_inds(axis::Integer) = One():axis
_inds(axis::AbstractVector) = One():static_length(axis)
_inds(axis::AbstractAxis) = parent(axis)


Base.axes(A::CartesianAxes) = getfield(A, :indices)

@propagate_inbounds function Base.getindex(A::CartesianIndices{N,R}, args::Vararg{Int, N}) where {N,R<:Tuple{Vararg{<:AbstractAxis,N}}}
    return ArrayInterface.getindex(A, args...)
end

@propagate_inbounds function Base.getindex(A::CartesianIndices{N,R}, args...) where {N,R<:Tuple{Vararg{<:AbstractAxis,N}}}
    return ArrayInterface.getindex(A, args...)
end
Base.getindex(A::CartesianIndices{N,R}, ::Ellipsis) where {N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = A

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

function LinearAxes(axs::Tuple{Vararg{<:Any,N}}) where {N}
    return LinearIndices(map(axis -> compose_axis(axis, _inds(axis)), axs))
end

Base.axes(A::LinearAxes) = getfield(A, :indices)

@boundscheck function Base.getindex(iter::LinearAxes, i::Int)
    @boundscheck if !in(i, eachindex(iter))
        throw(BoundsError(iter, i))
    end
    return i
end

@propagate_inbounds function Base.getindex(A::LinearAxes, inds...)
    return ArrayInterface.getindex(A, inds...)
    #return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end

@propagate_inbounds function Base.getindex(A::LinearAxes, i::AbstractRange{I}) where {I<:Integer}
    return getindex(eachindex(A), i)
end

Base.getindex(A::LinearAxes, ::Ellipsis) = A

Base.eachindex(A::LinearAxes) = SimpleAxis(StaticInt(1):static_length(A))


"""
    OffsetArray

An array whose axes are all `OffsetAxis`
"""
const OffsetArray{T,N,P,A<:Tuple{Vararg{<:OffsetAxis}}} = AxisArray{T,N,P,A}

"""
    OffsetVector

A vector whose axis is `OffsetAxis`
"""
const OffsetVector{T,P<:AbstractVector{T},Ax1<:OffsetAxis} = OffsetArray{T,1,P,Tuple{Ax1}}

OffsetArray(A::AbstractArray{T,N}, inds::Vararg) where {T,N} = OffsetArray(A, inds)

OffsetArray(A::AbstractArray{T,N}, inds::Tuple) where {T,N} = OffsetArray{T,N}(A, inds)

OffsetArray(A::AbstractArray{T,0}, ::Tuple{}) where {T} = AxisArray(A)
OffsetArray(A::AbstractArray) = OffsetArray(A, axes(A))

# OffsetVector constructors
OffsetVector(A::AbstractVector, arg) = OffsetArray{eltype(A)}(A, arg)

function OffsetVector{T}(init::ArrayInitializer, arg) where {T}
    return OffsetVector(Vector{T}(init, length(arg)), arg)
end
OffsetArray{T}(A, inds::Tuple) where {T} = OffsetArray{T,length(inds)}(A, inds)
OffsetArray{T}(A, inds::Vararg) where {T} = OffsetArray{T,length(inds)}(A, inds)

function OffsetArray{T,N}(init::ArrayInitializer, inds::Tuple=()) where {T,N}
    return OffsetArray{T,N}(Array{T,N}(init, map(length, inds)), inds)
end
OffsetArray{T,N}(A, inds::Vararg) where {T,N} = OffsetArray{T,N}(A, inds)
function OffsetArray{T,N}(A::AbstractArray{T,N}, inds::Tuple) where {T,N}
    return OffsetArray{T,N,typeof(A)}(A, inds)
end
function OffsetArray{T,N}(A::AbstractArray{T2,N}, inds::Tuple) where {T,T2,N}
    return OffsetArray{T,N}(copyto!(Array{T}(undef, size(A)), A), inds)
end
function OffsetArray{T,N}(A::AxisArray, inds::Tuple) where {T,N}
    return OffsetArray{T,N}(parent(A), inds)
end

function OffsetArray{T,N,P}(A::AbstractArray, inds::NTuple{M,Any}) where {T,N,P<:AbstractArray{T,N},M}
    return OffsetArray{T,N,P}(convert(P, A))
end

OffsetArray{T,N,P}(A::OffsetArray{T,N,P}) where {T,N,P} = A

function OffsetArray{T,N,P}(A::OffsetArray) where {T,N,P}
    return initialize_axis_array(convert(P, parent(A)), axes(A))
end

function OffsetArray{T,N,P}(A::P, inds::Tuple{Vararg{<:Any,N}}) where {T,N,P<:AbstractArray{T,N}}
    if N === 1
        if can_change_size(P)
            axs = (OffsetAxis(first(inds), SimpleAxis(DynamicAxis(axes(A, 1)))),)
        else
            axs = (OffsetAxis(first(inds), axes(A, 1)),)
        end
    else
        axs = map((f, axis) -> OffsetAxis(f, axis), inds, axes(A))
    end
    return initialize_axis_array(A, axs)
end

"""
    CenteredArray(A::AbstractArray)

Provides centered axes for indexing `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.CenteredArray(ones(3,3))
3×3 AxisArray(::Matrix{Float64}
  • axes:
     1 = -1:1
     2 = -1:1
)
      -1    0    1
  -1   1.0  1.0  1.0
  0    1.0  1.0  1.0
  1    1.0  1.0  1.0

```
"""
const CenteredArray{T,N,P,A<:Tuple{Vararg{<:CenteredAxis}}} = AxisArray{T,N,P,A}

CenteredArray(A::AbstractArray{T,N}) where {T,N} = CenteredArray{T,N}(A)

CenteredArray(A::AbstractArray{T,0}) where {T} = AxisArray(A)


CenteredArray{T}(A::AbstractArray) where {T} = CenteredArray{T,ndims(A)}(A)

CenteredArray{T,N}(A::AbstractArray) where {T,N} = CenteredArray{T,N,typeof(A)}(A)

CenteredArray{T,N,P}(A::CenteredArray{T,N,P}) where {T,N,P} = A
function CenteredArray{T,N,P}(A::CenteredArray) where {T,N,P}
    return CenteredArray{T,N,P}(parent(A))
end


function CenteredArray{T,N,P}(A::AbstractArray) where {T,N,P<:AbstractArray{T,N}}
    return CenteredArray{T,N,P}(convert(P, A))
end

function CenteredArray{T,N,P}(A::P) where {T,N,P<:AbstractArray{T,N}}
    axs = map(center, axes(A))
    return CenteredArray{T,N,P,typeof(axs)}(A, axs)
end

function CenteredArray{T}(init::ArrayInitializer, sz::Tuple=()) where {T}
    return CenteredArray{T,length(inds)}(init, sz)
end

function CenteredArray{T,N}(init::ArrayInitializer, sz::Tuple=()) where {T,N}
    return CenteredArray{T,N}(Array{T,N}(init, sz))
end

"""
    CenteredVector(v::AbstractVector)

Provides a centered axis for indexing `v`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.CenteredVector(ones(3))
3-element AxisArray(::Vector{Float64}
  • axes:
     1 = -1:1
)
      1
  -1  1.0
  0   1.0
  1   1.0

```
"""
const CenteredVector{T,P<:AbstractVector{T},Ax1<:CenteredAxis} = CenteredArray{T,1,P,Tuple{Ax1}}

CenteredVector(A::AbstractVector) = CenteredArray{eltype(A)}(A)
CenteredVector{T}(A::AbstractVector) where {T} = CenteredArray{T,1}(A)

"""
    CenteredVector{T}(init::ArrayInitializer, sz::Integer)

Creates a vector with elements of type `T` of size `sz` and a centered axis.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.CenteredVector{Union{Missing, Int}}(missing, 3)
3-element AxisArray(::Vector{Union{Missing, Int64}}
  • axes:
     1 = -1:1
)
      1
  -1   missing
  0    missing
  1    missing

```
"""
function CenteredVector{T}(init::ArrayInitializer, arg) where {T}
    return CenteredVector{T}(Vector{T}(init, arg))
end

