
offsets(A) = map(offset, axes(A))

"""
    OffsetArray
"""
const OffsetArray{T,N,P,A<:Tuple{Vararg{<:OffsetAxis}}} = AxisIndicesArray{T,N,P,A}

"""
    OffsetVector
"""
const OffsetVector{T,P<:AbstractVector{T},Ax1} = OffsetArray{T,1,P,Tuple{Ax1}}

compute_offset(parent_inds::AbstractUnitRange, offset::AbstractUnitRange) = first(offset) - first(parent_inds)
compute_offset(parent_inds::AbstractUnitRange, offset::Integer) = 1 - first(parent_inds)

OffsetArray(A::AbstractArray{T,N}, inds::Vararg) where {T,N} = OffsetArray(A, inds)

OffsetArray(A::AbstractArray{T,N}, inds::Tuple) where {T,N} = OffsetArray{T,N}(A, inds)

OffsetArray(A::AbstractArray{T,0}, ::Tuple{}) where {T} = AxisIndicesArray(A)
OffsetArray(A::AbstractArray) = OffsetArray(A, offsets(A))

# OffsetVector constructors
OffsetVector(A::AbstractVector, arg) = OffsetArray{eltype(A)}(A, arg)

# TODO What if `arg` is an integer?
function OffsetVector{T}(init::Union{UndefInitializer, Missing, Nothing}, arg) where {T}
    return OffsetVector(Vector{T}(init, length(arg)), arg)
end

OffsetArray{T}(A, inds::Tuple) where {T} = OffsetArray{T,length(inds)}(A, inds)
OffsetArray{T}(A, inds::Vararg) where {T} = OffsetArray{T,length(inds)}(A, inds)

function OffsetArray{T,N}(init::Union{UndefInitializer, Missing, Nothing}, inds::Tuple=()) where {T,N}
    return OffsetArray{T,N}(Array{T,N}(init, map(length, inds)), inds)
end

OffsetArray{T,N}(A, inds::Vararg) where {T,N} = OffsetArray{T,N}(A, inds)

function OffsetArray{T,N}(A::AbstractArray, inds::Tuple) where {T,N}
    return AxisIndicesArray{T,N}(A, to_offset_axes(A, inds))
end

function OffsetArray{T,N}(A::AbstractAxisIndices, inds::Tuple) where {T,N}
    return AxisIndicesArray{T,N}(parent(A), to_offset_axes(A, inds))
end


