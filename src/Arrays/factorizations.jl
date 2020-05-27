"""
    get_factorization(F::Factorization, A::AbstractArray, d::Symbol)

Used internally to compose an `AxisArray` for each component of a factor
decomposition. `F` is the result of decomposition, `A` is an arry (likely
a subtype of `AbstractAxisArray`), and `d` is a symbol referring to a component
of the factorization.
"""
function get_factorization end


@doc """
    lu(A::AbstractAxisArray, args...; kwargs...)

Compute the LU factorization of an `AbstractAxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

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
""" lu

function LinearAlgebra.lu!(A::AbstractAxisArray, args...; kwargs...)
    inner_lu = lu!(parent(A), args...; kwargs...)
    return LU(
        unsafe_reconstruct(A, getfield(inner_lu, :factors), axes(A)),
        getfield(inner_lu, :ipiv),
        getfield(inner_lu, :info)
       )
end

function Base.parent(F::LU{T,<:AxisArray}) where {T}
    return LU(parent(getfield(F, :factors)), getfield(F, :ipiv), getfield(F, :info))
end

@inline function Base.getproperty(F::LU{T,<:AxisArray}, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::LU, A::AbstractArray, d::Symbol)
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

"""
    lq(A::AbstractAxisArray, args...; kwargs...)

Compute the LQ factorization of an `AbstractAxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

julia> F = lq(m);

julia> keys.(axes(F.L))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.Q))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.L * F.Q))
(2:3, 3:4)
```
"""
LinearAlgebra.lq(A::AbstractAxisArray, args...; kws...) = lq!(copy(A), args...; kws...)
function LinearAlgebra.lq!(A::AbstractAxisArray, args...; kwargs...)
    F = lq!(parent(A), args...; kwargs...)
    inner = getfield(F, :factors)
    return LQ(unsafe_reconstruct(A, inner, axes(A)), getfield(F, :τ))
end
function Base.parent(F::LQ{T,<:AbstractAxisArray}) where {T}
    return LQ(parent(getfield(F, :factors)), getfield(F, :τ))
end

@inline function Base.getproperty(F::LQ{T,<:AbstractAxisArray}, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::LQ, A::AbstractArray, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return unsafe_reconstruct(A, inner, (axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Q
        return unsafe_reconstruct(A, inner, (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    else
        return inner
    end
end

const AIQRUnion{T} = Union{LinearAlgebra.QRCompactWY{T,<:AbstractAxisArray},
                                     QRPivoted{T,<:AbstractAxisArray},
                                     QR{T,<:AbstractAxisArray}}

"""
    qr(F::AbstractAxisArray, args...; kwargs...)

Compute the QR factorization of an `AbstractAxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

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

julia> keys.(axes(F.P * AxisArray([1.0 2; 3 4], (2:3, 3:4))))
(2:3, 3:4)
```

"""
function LinearAlgebra.qr(A::AbstractAxisArray{T,2}, args...; kwargs...) where T
    Base.require_one_based_indexing(A)
    AA = similar(A, LinearAlgebra._qreltype(T), axes(A))
    copyto!(AA, A)
    return qr!(AA, args...; kwargs...)
end

function LinearAlgebra.qr!(a::AbstractAxisArray, args...; kwargs...)
    return _qr(a, qr!(parent(a), args...; kwargs...), axes(a))
end

function _qr(a::AbstractAxisArray, F::QR, axs::Tuple)
    return QR(unsafe_reconstruct(a, getfield(F, :factors), axs), F.τ)
end
function Base.parent(F::QR{<:Any,<:AbstractAxisArray})
    return QR(parent(getfield(F, :factors)), getfield(F, :τ))
end

function _qr(a::AbstractAxisArray, F::LinearAlgebra.QRCompactWY, axs::Tuple)
    return LinearAlgebra.QRCompactWY(
        unsafe_reconstruct(a, getfield(F, :factors), axs),
        F.T
    )
end
function Base.parent(F::LinearAlgebra.QRCompactWY{<:Any, <:AbstractAxisArray})
    return LinearAlgebra.QRCompactWY(parent(getfield(F, :factors)), getfield(F, :T))
end

function _qr(a::AbstractAxisArray, F::QRPivoted, axs::Tuple)
    return QRPivoted(
        unsafe_reconstruct(a, getfield(F, :factors), axs),
        getfield(F, :τ),
        getfield(F, :jpvt)
    )
end
function Base.parent(F::QRPivoted{<:Any, <:AbstractAxisArray})
    return QRPivoted(parent(getfield(F, :factors)), getfield(F, :τ), getfield(F, :jpvt))
end

@inline function Base.getproperty(F::AIQRUnion, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

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

struct AxisIndicesSVD{T,F<:SVD{T},A<:AbstractAxisArray} <: Factorization{T}
    factor::F
    axes_indices::A
end

"""
    svd(F::AbstractAxisArray, args...; kwargs...)

Compute the singular value decomposition (SVD) of an `AbstractAxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

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
function LinearAlgebra.svd(A::AbstractAxisArray, args...; kwargs...)
    return AxisIndicesSVD(svd(parent(A), args...; kwargs...), A)
end

function LinearAlgebra.svd!(A::AbstractAxisArray, args...; kwargs...)
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

LinearAlgebra.svdvals(A::AbstractAxisArray) = sdvals(parent(A))

# iteration for destructuring into components
Base.iterate(S::AxisIndicesSVD) = (S.U, Val(:S))
Base.iterate(S::AxisIndicesSVD, ::Val{:S}) = (S.S, Val(:V))
Base.iterate(S::AxisIndicesSVD, ::Val{:V}) = (S.V, Val(:done))
Base.iterate(S::AxisIndicesSVD, ::Val{:done}) = nothing
# TODO GeneralizedSVD

@inline function Base.getproperty(F::AxisIndicesSVD, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :axes_indices), d)
end

function get_factorization(F::SVD, A::AbstractArray, d::Symbol)
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

if VERSION <= v"1.2"
    function LinearAlgebra.eigen(A::AbstractAxisArray{T,N,P,AI}; kwargs...) where {T,N,P,AI}
        vals, vecs = LinearAlgebra.eigen(parent(A); kwargs...)
        return Eigen(vals, unsafe_reconstruct(A, vecs, axes(A)))
    end

    function LinearAlgebra.eigvals(A::AbstractAxisArray; kwargs...)
        return LinearAlgebra.eigvals(parent(A); kwargs...)
    end

end

function LinearAlgebra.eigen!(A::AbstractAxisArray{T,N,P,AI}; kwargs...) where {T,N,P,AI}
    vals, vecs = LinearAlgebra.eigen!(parent(A); kwargs...)
    return Eigen(vals, unsafe_reconstruct(A, vecs, axes(A)))
end

function LinearAlgebra.eigvals!(A::AbstractAxisArray; kwargs...)
    return LinearAlgebra.eigvals!(parent(A); kwargs...)
end
 
#TODO eigen!(::AbstractArray, ::AbstractArray)

