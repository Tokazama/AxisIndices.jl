
"""
    CenteredArray

An array whose axes are all `CenteredAxis`
"""
const CenteredArray{T,N,P,A<:Tuple{Vararg{<:CenteredAxis}}} = AxisIndicesArray{T,N,P,A}

"""
    CenteredVector

A vector whose axis is `CenteredAxis`
"""
const CenteredVector{T,P<:AbstractVector{T},Ax1<:CenteredAxis} = CenteredArray{T,1,P,Tuple{Ax1}}

CenteredArray(A::AbstractArray{T,N}, inds::Vararg) where {T,N} = CenteredArray(A, inds)

CenteredArray(A::AbstractArray{T,N}, inds::Tuple) where {T,N} = CenteredArray{T,N}(A, inds)

CenteredArray(A::AbstractArray{T,0}, ::Tuple{}) where {T} = AxisIndicesArray(A)
CenteredArray(A::AbstractArray) = CenteredArray(A, offsets(A))

# CenteredVector constructors
CenteredVector(A::AbstractVector, arg) = CenteredArray{eltype(A)}(A, arg)

# TODO What if `arg` is an integer?
function CenteredVector{T}(init::Union{UndefInitializer, Missing, Nothing}, arg) where {T}
    return CenteredVector(Vector{T}(init, length(arg)), arg)
end

CenteredArray{T}(A, inds::Tuple) where {T} = CenteredArray{T,length(inds)}(A, inds)
CenteredArray{T}(A, inds::Vararg) where {T} = CenteredArray{T,length(inds)}(A, inds)

function CenteredArray{T,N}(init::Union{UndefInitializer, Missing, Nothing}, inds::Tuple=()) where {T,N}
    return CenteredArray{T,N}(Array{T,N}(init, map(length, inds)), inds)
end

CenteredArray{T,N}(A, inds::Vararg) where {T,N} = CenteredArray{T,N}(A, inds)

function CenteredArray{T,N}(A::AbstractArray, inds::Tuple) where {T,N}
    return AxisIndicesArray{T,N}(A, to_offset_axes(A, inds))
end

function CenteredArray{T,N}(A::AbstractAxisIndices, inds::Tuple) where {T,N}
    return AxisIndicesArray{T,N}(parent(A), to_offset_axes(A, inds))
end

