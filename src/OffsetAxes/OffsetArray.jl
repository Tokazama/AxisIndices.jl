
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
    axs = map(assign_indices, axes(A), axes(p))
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


function OffsetArray{T,N}(A::AbstractAxisArray, inds::Tuple) where {T,N}
    return OffsetArray{T,N}(parent(A), inds)
end

