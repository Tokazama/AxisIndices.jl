
"""
    IdentityArray(A::AbstractArray)

Provides [`IdentityAxis`](@ref)s for indexing `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> IdentityArray(ones(3,3))[2:3, 2:3]
2×2 AxisArray{Float64,2}
 • dim_1 - 2:3
 • dim_2 - 2:3
        2     3
  2   1.0   1.0
  3   1.0   1.0

```
"""
const IdentityArray{T,N,P,A<:Tuple{Vararg{<:IdentityAxis}}} = AxisArray{T,N,P,A}


IdentityArray(A::AbstractArray{T,N}) where {T,N} = IdentityArray{T,N}(A)

IdentityArray(A::AbstractArray{T,0}) where {T} = AxisArray(A)


IdentityArray{T}(A::AbstractArray) where {T} = IdentityArray{T,ndims(A)}(A)

IdentityArray{T,N}(A::AbstractArray) where {T,N} = IdentityArray{T,N,typeof(A)}(A)

IdentityArray{T,N,P}(A::IdentityArray{T,N,P}) where {T,N,P} = A
function IdentityArray{T,N,P}(A::IdentityArray) where {T,N,P}
    return IdentityArray{T,N,P}(parent(A))
end

function IdentityArray{T,N,P}(A::AbstractArray) where {T,N,P<:AbstractArray{T,N},M}
    return IdentityArray{T,N,P}(convert(P, A))
end

function IdentityArray{T,N,P}(A::P) where {T,N,P<:AbstractArray{T,N}}
    axs = map(idaxis, axes(A))
    return IdentityArray{T,N,P,typeof(axs)}(A, axs)
end

function IdentityArray{T}(init::ArrayInitializer, sz::Tuple=()) where {T,N}
    return IdentityArray{T,length(inds)}(init, sz)
end

function IdentityArray{T,N}(init::ArrayInitializer, sz::Tuple=()) where {T,N}
    return IdentityArray{T,N}(Array{T,N}(init, sz))
end

"""
    IdentityVector(v::AbstractVector)

Provides an [`IdentityAxis`](@ref) for indexing `v`.

## Examples
```jldoctest
julia> using AxisIndices

julia> IdentityVector(ones(4))[3:4]
2-element AxisArray{Float64,1}
 • dim_1 - 3:4

  3   1.0
  4   1.0

```
"""
const IdentityVector{T,P<:AbstractVector{T},Ax1<:IdentityAxis} = IdentityArray{T,1,P,Tuple{Ax1}}

IdentityVector(A::AbstractVector) = IdentityArray{eltype(A)}(A)
IdentityVector{T}(A::AbstractVector) where {T} = IdentityArray{T,1}(A)


"""
    IdentityVector{T}(init::ArrayInitializer, sz::Integer)

Creates a vector with elements of type `T` of size `sz` an [`IdentityAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> IdentityVector{Union{Missing, Int}}(missing, 3)[2:3]
2-element AxisArray{Union{Missing, Int64},1}
 • dim_1 - 2:3

  2   missing
  3   missing

```
"""
function IdentityVector{T}(init::ArrayInitializer, arg) where {T}
    return IdentityVector{T}(Vector{T}(init, arg))
end
