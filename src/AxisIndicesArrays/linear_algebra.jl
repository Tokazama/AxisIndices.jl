
###
### QR
###
const AIQRUnion{T} = Union{LinearAlgebra.QRCompactWY{T,<:AbstractAxisIndices},
                                     QRPivoted{T,<:AbstractAxisIndices},
                                     QR{T,<:AbstractAxisIndices}}

function LinearAlgebra.qr(A::AbstractAxisIndices{T,2}, arg) where T
    Base.require_one_based_indexing(A)
    AA = similar(A, LinearAlgebra._qreltype(T), axes(A))
    copyto!(AA, A)
    return qr!(AA, arg)
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
    return LinearAlgebra.QRCompactWY(unsafe_reconstruct(a, getfield(F, :factors), axs), F.T)
end
function Base.parent(F::LinearAlgebra.QRCompactWY{<:Any, <:AbstractAxisIndices})
    return LinearAlgebra.QRCompactWY(parent(getfield(F, :factors)), getfield(F, :T))
end

function _qr(a::AbstractAxisIndices, F::QRPivoted, axs::Tuple)
    return QRPivoted(unsafe_reconstruct(a, getfield(F, :factors), axs), getfield(F, :τ), getfield(F, :jpvt))
end
function Base.parent(F::QRPivoted{<:Any, <:AbstractAxisIndices})
    return QRPivoted(parent(getfield(F, :factors)), getfield(F, :τ), getfield(F, :jpvt))
end

@inline function Base.getproperty(F::AIQRUnion, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::Q, A::AbstractAxisIndices, d::Symbol) where {Q<:Union{LinearAlgebra.QRCompactWY,QRPivoted,QR}}
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

###
### Eigen
###
if VERSION <= v"1.2"
    function LinearAlgebra.eigen(A::AbstractAxisIndices{T,N,P,AI}; kwargs...) where {T,N,P,AI}
        vals, vecs = LinearAlgebra.eigen(parent(A); kwargs...)
        return Eigen(vals, unsafe_reconstruct(A, vecs, axes(A)))
    end

    function LinearAlgebra.eigvals(A::AbstractAxisIndices; kwargs...)
        return LinearAlgebra.eigvals(parent(A); kwargs...)
    end

end

function LinearAlgebra.eigen!(A::AbstractAxisIndices{T,N,P,AI}; kwargs...) where {T,N,P,AI}
    vals, vecs = LinearAlgebra.eigen!(parent(A); kwargs...)
    return Eigen(vals, unsafe_reconstruct(A, vecs, axes(A)))
end

function LinearAlgebra.eigvals!(A::AbstractAxisIndices; kwargs...)
    return LinearAlgebra.eigvals!(parent(A); kwargs...)
end
 
#TODO eigen!(::AbstractArray, ::AbstractArray)

###
### LQ
###
LinearAlgebra.lq(A::AbstractAxisIndices, args...; kws...) = lq!(copy(A), args...; kws...)
function LinearAlgebra.lq!(A::AbstractAxisIndices, args...; kwargs...)
    F = lq!(parent(A), args...; kwargs...)
    inner = getfield(F, :factors)
    return LQ(unsafe_reconstruct(A, inner, axes(A)), getfield(F, :τ))
end
function Base.parent(F::LQ{T,<:AbstractAxisIndices}) where {T}
    return LQ(parent(getfield(F, :factors)), getfield(F, :τ))
end

@inline function Base.getproperty(F::LQ{T,<:AbstractAxisIndices}, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::LQ, A::AbstractAxisIndices, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return unsafe_reconstruct(A, inner, (axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Q
        return unsafe_reconstruct(A, inner, (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    else
        return inner
    end
end
function LinearAlgebra.lu!(a::AxisIndicesArray, args...; kwargs...)
    inner_lu = lu!(parent(a), args...; kwargs...)
    return LU(
        AxisIndicesArray(getfield(inner_lu, :factors), axes(a)),
        getfield(inner_lu, :ipiv),
        getfield(inner_lu, :info)
       )
end

###
### LU
###
function Base.parent(F::LU{T,<:AxisIndicesArray}) where {T}
    return LU(parent(getfield(F, :factors)), getfield(F, :ipiv), getfield(F, :info))
end

@inline function Base.getproperty(F::LU{T,<:AxisIndicesArray}, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::LU, A::AbstractAxisIndices, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return unsafe_reconstruct(A, inner, (axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :U
        return unsafe_reconstruct(A, inner, (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    elseif d === :P
        return unsafe_reconstruct(A, inner, (axes(A, 1), axes(A, 1)))
    elseif d === :p
        return unsafe_reconstruct(A, inner, (axes(A, 1),))
    else
        return inner
    end
end

###
### SVD
###
struct AxisIndicesSVD{T,F<:SVD{T},A<:AbstractAxisIndices} <: Factorization{T}
    factor::F
    axes_indices::A
end

function LinearAlgebra.svd(A::AbstractAxisIndices, args...; kwargs...)
    return AxisIndicesSVD(svd(parent(A), args...; kwargs...), A)
end

function LinearAlgebra.svd!(A::AxisIndicesArray, args...; kwargs...)
    return AxisIndicesSVD(svd!(parent(A), args...; kwargs...), A)
end

Base.parent(F::AxisIndicesSVD) = getfield(F, :factor)

Base.size(F::AxisIndicesSVD) = size(parent(F))

Base.size(F::AxisIndicesSVD, i) = size(parent(F), i)

function Base.propertynames(F::AxisIndicesSVD, private::Bool=false)
    return private ? (:V, fieldnames(typeof(parent(F)))...) : (:U, :S, :V, :Vt)
end
function Base.show(io::IO, mime::MIME{Symbol("text/plain")}, F::AxisIndicesSVD)
    summary(io, F)
    println(io)
    println(io, "U factor:")
    show(io, mime, F.U)
    println(io, "\nsingular values:")
    show(io, mime, F.S)
    println(io, "\nVt factor:")
    show(io, mime, F.Vt)
end

LinearAlgebra.svdvals(A::AbstractAxisIndices) = sdvals(parent(A))

# iteration for destructuring into components
Base.iterate(S::AxisIndicesSVD) = (S.U, Val(:S))
Base.iterate(S::AxisIndicesSVD, ::Val{:S}) = (S.S, Val(:V))
Base.iterate(S::AxisIndicesSVD, ::Val{:V}) = (S.V, Val(:done))
Base.iterate(S::AxisIndicesSVD, ::Val{:done}) = nothing
# TODO GeneralizedSVD

@inline function Base.getproperty(F::AxisIndicesSVD, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :axes_indices), d)
end

function get_factorization(F::SVD, A::AbstractAxisIndices, d::Symbol)
    inner = getproperty(F, d)
    if d === :U
        return unsafe_reconstruct(A, inner, (axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :V
        return unsafe_reconstruct(A, inner, (axes(A, 2), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Vt
        return unsafe_reconstruct(A, inner, (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    else  # d === :S
        return inner
    end
end
function LinearAlgebra.diag(x::AbstractAxisIndices{T,2}) where {T}
    return AxisIndicesArray(diag(parent(x)), (diagonal_axes(axes(x)),))
end

function Base.inv(a::AbstractAxisIndices{T,2}) where {T}
    return unsafe_reconstruct(a, inv(parent(a)), permute_axes(axes(a)))
end

"""
    get_factorization(F::Factorization, A::AbstractAxisIndices, d::Symbol)

Used internally to compose an `AxisIndicesArray` for each component of a factor
decomposition.

## QR Factorization
```jldoctest get_factorization_example
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
(2:3, UnitMRange(3:4))
```

## LU Factorization
```jldoctest get_factorization_example
julia> F = lu(m);

julia> keys.(axes(F.L))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.U))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.p))
(2:3,)

julia> keys.(axes(F.P))
(2:3, 2:3)

julia> keys.(axes(F.P * m))
(2:3, 3:4)

julia> keys.(axes(F.L * F.U))
(2:3, 3:4)
```

## LQ Factorization
```jldoctest get_factorization_example
julia> F = lq(m);

julia> keys.(axes(F.L))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.Q))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.L * F.Q))
(2:3, 3:4)
```

## SVD Factorization
```jldoctest get_factorization_example
julia> F = svd(m);

julia> axes(F.U)
(Axis(2:3 => Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

julia> axes(F.V)
(Axis(3:4 => Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

julia> axes(F.Vt)
(SimpleAxis(Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))

julia> axes(F.U * Diagonal(F.S) * F.Vt)
(Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))
```
"""
get_factorization

for (N1,N2) in ((2,2), (1,2), (2,1))
    @eval begin
        function Base.:*(a::AbstractAxisIndices{T1,$N1}, b::AbstractAxisIndices{T2,$N2}) where {T1,T2}
            return _matmul(a, promote_type(T1, T2), *(parent(a), parent(b)), as_axis(a, matmul_axes(a, b)))
        end
        function Base.:*(a::AbstractArray{T1,$N1}, b::AbstractAxisIndices{T2,$N2}) where {T1,T2}
            return _matmul(b, promote_type(T1, T2), *(a, parent(b)), as_axis(b, matmul_axes(a, b)))
        end
        function Base.:*(a::AbstractAxisIndices{T1,$N1}, b::AbstractArray{T2,$N2}) where {T1,T2}
            return _matmul(a, promote_type(T1, T2), *(parent(a), b), as_axis(a, matmul_axes(a, b)))
        end
    end
end

function Base.:*(a::Diagonal{T1}, b::AbstractAxisIndices{T2,2}) where {T1,T2}
    return _matmul(b, promote_type(T1, T2), *(a, parent(b)), as_axis(b, matmul_axes(a, b)))
end
function Base.:*(a::AbstractAxisIndices{T1,2}, b::Diagonal{T2}) where {T1,T2}
    return _matmul(a, promote_type(T1, T2), *(parent(a), b), as_axis(a, matmul_axes(a, b)))
end

_matmul(A, ::Type{T}, a::T, axs) where {T} = a
_matmul(A, ::Type{T}, a::AbstractArray{T}, axs) where {T} = unsafe_reconstruct(A, a, axs)

# Using `CovVector` results in Method ambiguities; have to define more specific methods.
for A in (Adjoint{<:Any, <:AbstractVector}, Transpose{<:Real, <:AbstractVector{<:Real}})
    @eval function Base.:*(a::$A, b::AbstractAxisIndices{T,1,<:AbstractVector{T}}) where {T}
        return *(a, parent(b))
    end
end

# vector^T * vector
function Base.:*(a::AbstractAxisIndices{T,2,<:CoVector}, b::AbstractAxisIndices{S,1}) where {T,S}
    return *(parent(a), parent(b))
end

