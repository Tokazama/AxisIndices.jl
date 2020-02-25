
const AIQRCompactWY{T,M,Ax1,Ax2} = LinearAlgebra.QRCompactWY{T,AxisIndicesMatrix{T,M,Ax1,Ax2}}

const AIQRPivoted{T,M,Ax1,Ax2} = QRPivoted{T,AxisIndicesMatrix{T,M,Ax1,Ax2}}

const AIQR{T,M,Ax1,Ax2} = QR{T,AxisIndicesMatrix{T,M,Ax1,Ax2}}

const AIQRUnion{T,M,Ax1,Ax2} = Union{AIQRCompactWY{T,M,Ax1,Ax2},
                                    AIQRPivoted{T,M,Ax1,Ax2},
                                    AIQR{T,M,Ax1,Ax2}}

function LinearAlgebra.qr(A::AxisIndicesMatrix{T}, arg) where T
    Base.require_one_based_indexing(A)
    # this line throws away axes in the original function
    #similar(A, LinearAlgebra._qreltype(T), size(A))
    AA = similar(A, LinearAlgebra._qreltype(T), axes(A))
    copyto!(AA, A)
    return qr!(AA, arg)
end

function LinearAlgebra.qr!(a::AxisIndicesArray, args...; kwargs...)
    return _qr(qr!(parent(a), args...; kwargs...), axes(a))
end

function _qr(inner::QR, axs::Tuple)
    return QR(AxisIndicesArray(inner.factors, axs, false), inner.τ)
end

function Base.parent(F::QR{<:Any,<:AxisIndicesArray})
    return QR(parent(getfield(F, :factors)), getfield(F, :τ))
end

function _qr(inner::LinearAlgebra.QRCompactWY, inds::Tuple)
    return LinearAlgebra.QRCompactWY(AxisIndicesArray(inner.factors, inds), inner.T)
end
function Base.parent(F::LinearAlgebra.QRCompactWY{<:Any, <:AxisIndicesArray})
    return LinearAlgebra.QRCompactWY(parent(getfield(F, :factors)), getfield(F, :T))
end

function _qr(F::QRPivoted, axs::Tuple)
    return QRPivoted(AxisIndicesArray(getfield(F, :factors), axs),
                     getfield(F, :τ),
                     getfield(F, :jpvt))
end
function Base.parent(F::QRPivoted{<:Any, <:AxisIndicesArray})
    return QRPivoted(parent(getfield(F, :factors)), getfield(F, :τ), getfield(F, :jpvt))
end

Base.axes(F::AIQRUnion) = axes(getfield(F, :factors))

Base.axes(F::AIQRUnion, i) = axes(getfield(F, :factors))[i]

@inline function Base.getproperty(F::AIQRUnion, d::Symbol) where {T}
    return get_factorization(parent(F), axes(F), d)
end

function get_factorization(F::Q, axs::NTuple{2,Any}, d::Symbol) where {Q<:Union{LinearAlgebra.QRCompactWY,QRPivoted,QR}}
    inner = getproperty(F, d)
    if d === :Q
        return AxisIndicesArray(inner, (first(axs), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :R
        return AxisIndicesArray(inner, (SimpleAxis(OneTo(size(inner, 1))), last(axs)))
    elseif F isa QRPivoted && d === :P
        return AxisIndicesArray(inner, (first(axs), first(axs)))
    elseif F isa QRPivoted && d === :p
        return AxisIndicesArray(inner, (first(axs),))
    else
        return inner
    end
end

