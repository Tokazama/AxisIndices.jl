
const AIQRUnion{T} = Union{LinearAlgebra.QRCompactWY{T,<:AbstractAxisIndices},
                                     QRPivoted{T,<:AbstractAxisIndices},
                                     QR{T,<:AbstractAxisIndices}}

function LinearAlgebra.qr(A::AbstractAxisIndices{T,2}, arg) where T
    Base.require_one_based_indexing(A)
    # this line throws away axes in the original function
    #similar(A, LinearAlgebra._qreltype(T), size(A))
    AA = similar(A, LinearAlgebra._qreltype(T), axes(A))
    copyto!(AA, A)
    return qr!(AA, arg)
end

function LinearAlgebra.qr!(a::AbstractAxisIndices, args...; kwargs...)
    return _qr(a, qr!(parent(a), args...; kwargs...), axes(a))
end

function _qr(a::AbstractAxisIndices, F::QR, axs::Tuple)
    p = getfield(F, :factors)
    return QR(similar_type(a, typeof(p), typeof(axs))(p, axs, false), F.τ)
end
function Base.parent(F::QR{<:Any,<:AbstractAxisIndices})
    return QR(parent(getfield(F, :factors)), getfield(F, :τ))
end

function _qr(a::AbstractAxisIndices, inner::LinearAlgebra.QRCompactWY, inds::Tuple)
    p = inner.factors
    return LinearAlgebra.QRCompactWY(similar_type(a, typeof(p))(p, inds), inner.T)
end
function Base.parent(F::LinearAlgebra.QRCompactWY{<:Any, <:AbstractAxisIndices})
    return LinearAlgebra.QRCompactWY(parent(getfield(F, :factors)), getfield(F, :T))
end

function _qr(a::AbstractAxisIndices, F::QRPivoted, axs::Tuple)
    p = getfield(F, :factors)
    return QRPivoted(similar_type(a, typeof(p))(p, axs), getfield(F, :τ), getfield(F, :jpvt))
end
function Base.parent(F::QRPivoted{<:Any, <:AbstractAxisIndices})
    return QRPivoted(parent(getfield(F, :factors)), getfield(F, :τ), getfield(F, :jpvt))
end

Base.axes(F::AIQRUnion) = axes(getfield(F, :factors))

Base.axes(F::AIQRUnion, i) = getfield(axes(getfield(F, :factors)), i)

@inline function Base.getproperty(F::AIQRUnion, d::Symbol) where {T}
    return get_factorization(getfield(F, :factors), parent(F), axes(F), d)
end

function get_factorization(A::AbstractAxisIndices, F::Q, axs::NTuple{2,Any}, d::Symbol) where {Q<:Union{LinearAlgebra.QRCompactWY,QRPivoted,QR}}
    inner = getproperty(F, d)
    if d === :Q
        axs = (first(axs), SimpleAxis(OneTo(size(inner, 2))))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :R
        axs = (SimpleAxis(OneTo(size(inner, 1))), last(axs))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif F isa QRPivoted && d === :P
        axs = (first(axs), first(axs))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif F isa QRPivoted && d === :p
        axs = (first(axs),)
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    else
        return inner
    end
end

