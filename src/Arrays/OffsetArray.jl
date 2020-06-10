
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

# TODO What if `arg` is an integer?
function OffsetVector{T}(init::ArrayInitializer, arg) where {T}
    return OffsetVector(Vector{T}(init, length(arg)), arg)
end

OffsetArray{T}(A, inds::Tuple) where {T} = OffsetArray{T,length(inds)}(A, inds)
OffsetArray{T}(A, inds::Vararg) where {T} = OffsetArray{T,length(inds)}(A, inds)

function OffsetArray{T,N}(init::ArrayInitializer, inds::Tuple=()) where {T,N}
    return OffsetArray{T,N}(Array{T,N}(init, map(length, inds)), inds)
end

OffsetArray{T,N}(A, inds::Vararg) where {T,N} = OffsetArray{T,N}(A, inds)

@inline function OffsetArray{T,N}(A::AbstractArray{T,N}, inds::NTuple{M,Any}) where {T,N,M}
    S = Staticness(A)
    if N === M
        axs = map((x, y) -> OffsetAxis(as_staticness(S, x), as_staticness(S, y)), inds, axes(A))
    elseif N < M
        axs = ntuple(Val(N)) do i
            OffsetAxis(as_staticness(S, getfield(inds, i)), as_staticness(S, axes(A, i)))
        end
    else  # N > M
        axs = ntuple(Val(N)) do i
            inds_i = as_staticness(S, axes(A, i))
            if i > M
                OffsetAxis(inds_i, inds_i)
            else
                OffsetAxis(inds_i, as_staticness(S, axes(A, i)))
            end
        end
    end
    return AxisArray{T,N,typeof(A),typeof(axs)}(A, axs)
end

function OffsetArray{T,N}(A::AbstractAxisArray, inds::Tuple) where {T,N}
    return OffsetArray{T,N}(parent(A), inds)
end

