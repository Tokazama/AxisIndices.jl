
const AIQRUnion{T} = Union{LinearAlgebra.QRCompactWY{T,<:AbstractAxisIndices},
                                     QRPivoted{T,<:AbstractAxisIndices},
                                     QR{T,<:AbstractAxisIndices}}

function LinearAlgebra.qr(A::AbstractAxisIndices{T,2}, args...; kwargs...) where T
    Base.require_one_based_indexing(A)
    AA = similar(A, LinearAlgebra._qreltype(T), axes(A))
    copyto!(AA, A)
    return qr!(AA, args...; kwargs...)
end

function LinearAlgebra.qr!(a::AbstractAxisIndices, args...; kwargs...)
    return _qr(a, qr!(parent(a), args...; kwargs...), axes(a))
end

function _qr(a::AbstractAxisIndices, F::QR, axs::Tuple)
    return QR(unsafe_reconstruct(a, getfield(F, :factors), axs), F.τ)
end
function Base.parent(F::QR{<:Any,<:AbstractAxisIndices})
    return QR(parent(getfield(F, :factors)), getfield(F, :τ))
end

function _qr(a::AbstractAxisIndices, F::LinearAlgebra.QRCompactWY, axs::Tuple)
    return LinearAlgebra.QRCompactWY(
        unsafe_reconstruct(a, getfield(F, :factors), axs),
        F.T
    )
end
function Base.parent(F::LinearAlgebra.QRCompactWY{<:Any, <:AbstractAxisIndices})
    return LinearAlgebra.QRCompactWY(parent(getfield(F, :factors)), getfield(F, :T))
end

function _qr(a::AbstractAxisIndices, F::QRPivoted, axs::Tuple)
    return QRPivoted(
        unsafe_reconstruct(a, getfield(F, :factors), axs),
        getfield(F, :τ),
        getfield(F, :jpvt)
    )
end
function Base.parent(F::QRPivoted{<:Any, <:AbstractAxisIndices})
    return QRPivoted(parent(getfield(F, :factors)), getfield(F, :τ), getfield(F, :jpvt))
end

@inline function Base.getproperty(F::AIQRUnion, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

"""
    get_factorization(F::Union{LinearAlgebra.QRCompactWY,QRPivoted,QR}, A::AbstractArray, d::Symbol)

Returns a component of the QR decomposition `F` with the appropriate axes given `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisIndicesArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

julia> F = qr(m, Val(true));

julia> keys.(axes(F.Q))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.R))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.Q * F.R))
(2:3, 3:4)

julia> keys.(axes(F.p))
(2:3,)

julia> keys.(axes(F.P))
(2:3, 2:3)

julia> keys.(axes(F.P * AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))))
(2:3, 3:4)
```

"""
function get_factorization(F::Q, A::AbstractArray, d::Symbol) where {Q<:Union{LinearAlgebra.QRCompactWY,QRPivoted,QR}}
    inner = getproperty(F, d)
    if d === :Q
        return unsafe_reconstruct(A, inner, (axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :R
        return unsafe_reconstruct(A, inner, (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    elseif F isa QRPivoted && d === :P
        return unsafe_reconstruct(A, inner, (axes(A, 1), axes(A, 1)))
    elseif F isa QRPivoted && d === :p
        return unsafe_reconstruct(A, inner, (axes(A, 1),))
    else
        return inner
    end
end

