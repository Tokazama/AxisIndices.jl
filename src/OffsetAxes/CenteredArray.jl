
"""
    CenteredArray(A::AbstractArray)

Provides centered axes for indexing `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> CenteredArray(ones(3,3))
3×3 AxisArray{Float64,2}
 • dim_1 - -1:1
 • dim_2 - -1:1
        -1     0     1
  -1   1.0   1.0   1.0
   0   1.0   1.0   1.0
   1   1.0   1.0   1.0

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

julia> CenteredVector(ones(3))
3-element AxisArray{Float64,1}
 • dim_1 - -1:1

  -1   1.0
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

julia> CenteredVector{Union{Missing, Int}}(missing, 3)
3-element AxisArray{Union{Missing, Int64},1}
 • dim_1 - -1:1

  -1   missing
   0   missing
   1   missing
```
"""
function CenteredVector{T}(init::ArrayInitializer, arg) where {T}
    return CenteredVector{T}(Vector{T}(init, arg))
end
