
CenteredAxis(inds::AbstractVector) = CenteredAxis(Zero(), inds)
function CenteredAxis(origin::Integer, inds::AbstractOffsetAxis)
    return CenteredAxis(origin, parent(inds))
end
function CenteredAxis(origin::Integer, inds::AbstractArray)
    return CenteredAxis(origin, compose_axis(inds))
end
CenteredAxis(o::Integer, x::AbstractAxis) = _centered_axis(has_offset(x), o, x)
_centered_axis(::True, o, x) = _CenteredAxis(int(o), last(drop_offset(x)))
_centered_axis(::False, o, x) = _CenteredAxis(int(o), x)

@inline Base.getproperty(axis::CenteredAxis, k::Symbol) = getproperty(parent(axis), k)

function ArrayInterface.unsafe_reconstruct(axis::CenteredAxis, inds; kwargs...)
    return CenteredAxis(origin(axis), unsafe_reconstruct(parent(axis), inds; kwargs...))
end

ArrayInterface.known_first(::Type{CenteredAxis{Int,P}}) where {P} = nothing
function ArrayInterface.known_first(::Type{CenteredAxis{StaticInt{O},P}}) where {O,P}
    if known_length(P) === nothing
        return nothing
    else
        return O - div(known_length(P), 2)
    end
end
Base.first(axis::CenteredAxis) = origin(axis) - div(length(parent(axis)), 2)

ArrayInterface.known_last(::Type{CenteredAxis{Int,P}}) where {P} = nothing
function ArrayInterface.known_last(::Type{CenteredAxis{StaticInt{O},P}}) where {O,P}
    if known_length(P) === nothing
        return nothing
    else
        return O - div(known_length(P), 2) + known_length(P)
    end
end
Base.last(axis::CenteredAxis) = last(parent(axis)) + _origin_to_offset(axis)

function _origin_to_offset(axis::CenteredAxis)
    p = parent(axis)
    return _origin_to_offset(first(p), length(p), getfield(axis, :origin))
end
_origin_to_offset(start, len, origin) = (origin - div(len, 2one(start))) - start

origin(axis::CenteredAxis) = getfield(axis, :origin)
@inline function ArrayInterface.offsets(axis::CenteredAxis)
    inds = parent(axis)
    return (_origin_to_offset(static_first(inds), static_length(inds), origin(axis)),)
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

function print_axis(io::IO, axis::CenteredAxis)
    print(io, "center($(Int(origin(axis))))($(parent(axis)))")
end

