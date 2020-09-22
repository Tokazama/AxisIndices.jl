
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

function IdentityArray{T,N,P}(A::AbstractArray) where {T,N,P<:AbstractArray{T,N}}
    return IdentityArray{T,N,P}(convert(P, A))
end

function IdentityArray{T,N,P}(A::P) where {T,N,P<:AbstractArray{T,N}}
    axs = map(idaxis, axes(A))
    return IdentityArray{T,N,P,typeof(axs)}(A, axs)
end

function IdentityArray{T}(init::ArrayInitializer, sz::Tuple=()) where {T}
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


function OffsetArray{T,N,P}(A::AbstractArray, inds::NTuple{M,Any}) where {T,N,P<:AbstractArray{T,N},M}
    return OffsetArray{T,N,P}(convert(P, A))
end

OffsetArray{T,N,P}(A::OffsetArray{T,N,P}) where {T,N,P} = A

function OffsetArray{T,N,P}(A::OffsetArray) where {T,N,P}
    p = convert(P, parent(A))
    axs = map(to_axes, axes(A), axes(p))
    return AxisArray{T,N,P,typeof(axs)}(p, axs)
end

function OffsetArray{T,N,P}(A::P, inds::NTuple{M,Any}) where {T,N,P<:AbstractArray{T,N},M}
    if N === 1
        if M === 1
            axs = (OffsetAxis(first(inds), of_staticness(A, axes(A, 1))),)
        else
            axs = (OffsetAxis(of_staticness(A, axes(A, 1))),)
        end
    else
        if N === M
            axs = map((x, y) -> OffsetAxis(x, y), inds, axes(A))
        elseif N < M
            axs = ntuple(Val(N)) do i
                OffsetAxis(getfield(inds, i), axes(A, i))
            end
        else  # N > M
            axs = ntuple(Val(N)) do i
                inds_i = axes(A, i)
                if i > M
                    OffsetAxis(inds_i, inds_i)
                else
                    OffsetAxis(inds_i, axes(A, i))
                end
            end
        end
    end
    return AxisArray{T,N,typeof(A),typeof(axs)}(A, axs)
end


function OffsetArray{T,N}(A::AxisArray, inds::Tuple) where {T,N}
    return OffsetArray{T,N}(parent(A), inds)
end

