
function covcor_axes(old_axes::NTuple{2,Any}, new_indices::NTuple{2,Any}, dim::Int)
    if dim === 1
        return (
            unsafe_reconstruct(last(old_axes), first(new_indices)),
            StaticRanges.resize_last(last(old_axes), last(new_indices))
        )
    elseif dim === 2
        return (
            StaticRanges.resize_last(first(old_axes), first(new_indices)),
            unsafe_reconstruct(first(old_axes), last(new_indices))
        )
    else
        return (
            StaticRanges.resize_last(first(old_axes), first(new_indices)),
            StaticRanges.resize_last(last(old_axes), last(new_indices))
        )
    end
end

for fun in (:cor, :cov)
    fun_doc = """
        $fun(x::AxisMatrix; dims=1, kwargs...)

    Performs `$fun` on the parent matrix of `x` and reconstructs a similar type
    with the appropriate axes.

    ## Examples
    ```jldoctest
    julia> using AxisIndices, Statistics

    julia> A = AxisArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"], [:one, :two, :three]);

    julia> keys.(axes($fun(A, dims = 2)))
    (["a", "b", "c"], ["a", "b", "c"])

    julia> keys.(axes($fun(A, dims = 1)))
    ([:one, :two, :three], [:one, :two, :three])

    ```
    """
    @eval begin
        @doc $fun_doc
        function Statistics.$fun(x::AxisArray{T,2}; dims=1, kwargs...) where {T}
            p = Statistics.$fun(parent(x); dims=dims, kwargs...)
            return initialize_axis_array(p, covcor_axes(axes(x), axes(p), dims))
        end
    end
end


###
### 🐇/*
###
#
#    matmul_axes(a, b, p) -> Tuple
#
# The arrays from `a * b = p`, where `p` will be the new parent array of an AxisArray.

matmul_axes(a::Tuple, b::Tuple, p::Tuple) = _matmul_axes(a, b, p)
matmul_axes(a::Tuple, b::Tuple, p::Tuple{}) = ()

function _matmul_axes(a::Tuple{Any}, b::Tuple{Any,Any}, p::Tuple{Any,Any})
    return (
        _matmul_unsafe_reconstruct(first(a), first(p)),
        _matmul_unsafe_reconstruct(last(b), last(p))
    )
end

function _matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any,Any}, p::Tuple{Any,Any})
    return (
        _matmul_unsafe_reconstruct(first(a), first(p)),
        _matmul_unsafe_reconstruct(last(b), last(p))
    )
end

function _matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any}, p::Tuple{Any})
    return (_matmul_unsafe_reconstruct(first(a), first(p)),)
end

function _matmul_unsafe_reconstruct(axis::AbstractAxis, inds)
    if is_dynamic(axis)
        return copy(axis)
    else
        return axis
    end
end
_matmul_unsafe_reconstruct(axis, inds) = SimpleAxis(inds)

_matmul(p, axs::Tuple) = initialize_axis_array(p, axs)
_matmul(p, axs::Tuple{}) = p

function Base.:*(a::AxisMatrix, b::AxisMatrix)
    p = *(parent(a), parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AxisMatrix, b::AxisVector)
    p = *(parent(a), parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AxisVector, b::AxisMatrix)
    p = *(parent(a), parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end

#Base.:*(x::AxisVector, y::AxisVector) = throw(MethodError(*, (x, y)))
function Base.:*(a::AxisVector, b::AxisVector)
    p = *(parent(a), parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end

macro declare_axis_array_matmul_left(X, Y)
    esc(quote
        function Base.:*(x::$X, y::$Y)
            p = *(parent(x), y)
            return _matmul(p, matmul_axes(axes(x), axes(y), axes(p)))
        end
    end)
end

macro declare_axis_array_matmul_right(X, Y)
    esc(quote
        function Base.:*(x::$X, y::$Y)
            p = *(x, parent(y))
            return _matmul(p, matmul_axes(axes(x), axes(y), axes(p)))
        end
    end)
end


#     @declare_axisarray_matmul(T)
#
# This is used to quickly resolve ambiguities with `*`.
# It simply defines a method for `*(::T, ::AxisArray)` and
# `*(::AxisArray, ::T)`, which unwrap the `AxisArray` for subsequent
# `*` methods and than rewraps the appropriate axes as an axis array. It isn't
# exported and doesn't have an official docstring b/c it's unlikely to be useful
# outside the internals of this package.
macro declare_axisarray_matmul(T)
    esc(quote
        @declare_axis_array_matmul_left(AxisMatrix, $T)
        @declare_axis_array_matmul_left(AxisVector, $T)
        @declare_axis_array_matmul_right($T, AxisMatrix)
        @declare_axis_array_matmul_right($T, AxisVector)
    end)
end

@declare_axisarray_matmul AbstractVector

@declare_axisarray_matmul AbstractMatrix

@declare_axisarray_matmul Diagonal

@declare_axis_array_matmul_left(AxisMatrix, Transpose{<:Any,<:LinearAlgebra.RealHermSymComplexSym})
@declare_axis_array_matmul_left(AxisMatrix, Transpose{<:Any,<:LinearAlgebra.AbstractTriangular})
@declare_axis_array_matmul_left(AxisMatrix, Adjoint{<:Any,<:LinearAlgebra.RealHermSymComplexHerm})
@declare_axis_array_matmul_left(AxisMatrix, LinearAlgebra.AbstractTriangular)
@declare_axis_array_matmul_left(AxisVector, LinearAlgebra.AdjOrTransAbsVec)
@declare_axis_array_matmul_left(AxisVector, Transpose{<:Any,<:AbstractMatrix})
@declare_axis_array_matmul_left(AxisVector, Adjoint{<:Any,<:AbstractMatrix})


@declare_axis_array_matmul_right(LinearAlgebra.AdjointAbsVec{<:Number}, AxisVector{<:Number})
@declare_axis_array_matmul_right(LinearAlgebra.AdjOrTransAbsVec, AxisVector)
@declare_axis_array_matmul_right(LinearAlgebra.TransposeAbsVec, AxisMatrix)

for T in (AxisVector, AxisMatrix)
    @eval begin
        @declare_axis_array_matmul_right(LinearAlgebra.AbstractTriangular, $T)
        @declare_axis_array_matmul_right(Adjoint{<:Any,<:LinearAlgebra.AbstractTriangular}, $T)
        @declare_axis_array_matmul_right(Transpose{<:Any,<:LinearAlgebra.AbstractTriangular}, $T)
        @declare_axis_array_matmul_right(Adjoint{<:Any,<:LinearAlgebra.RealHermSymComplexHerm}, $T)
        @declare_axis_array_matmul_right(LinearAlgebra.AdjointAbsVec, $T)
        @declare_axis_array_matmul_right(Transpose{<:Any,<:LinearAlgebra.RealHermSymComplexSym}, $T)

        @declare_axis_array_matmul_left($T, Adjoint{<:Any,<:LinearAlgebra.AbstractTriangular})
        @declare_axis_array_matmul_left($T, Adjoint{<:Any,<:LinearAlgebra.AbstractRotation})
    end
end
function Base.:*(a::Transpose{<:Any,<:AbstractMatrix{T}}, b::AxisVector{S}) where {T,S}
    p = *(a, parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end

function Base.:*(x::LinearAlgebra.TransposeAbsVec{T}, y::AxisVector{T}) where {T<:Real}
    p = *(x, parent(y))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end

function Base.:*(a::Adjoint{<:Any,<:AbstractMatrix{T}}, b::AxisVector{S}) where {T,S}
    p = *(a, parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Adjoint{T,<:AbstractArray{T,1}}, b::AxisVector{T}) where {T}
    p = *(a, parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Adjoint{T,<:AbstractArray{T,1}}, b::AxisVector{T}) where {T<:Number}
    p = *(a, parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Transpose{T,<:AbstractArray{T,1}}, b::AxisVector{T}) where {T<:Real}
    p = *(a, parent(b))
    return _matmul(p, matmul_axes(axes(a), axes(b), axes(p)))
end

#=
    get_factorization(F::Factorization, A::AbstractArray, d::Symbol)

Used internally to compose an `AxisArray` for each component of a factor
decomposition. `F` is the result of decomposition, `A` is an arry (likely
a subtype of `AxisArray`), and `d` is a symbol referring to a component
of the factorization.
=#
function get_factorization end


@doc """
    lu(A::AxisArray, args...; kwargs...)

Compute the LU factorization of an `AxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (2:3, 3:4));

julia> F = lu(m);

julia> axes(F.L)
(offset(1)(SimpleAxis(1:2)), SimpleAxis(1:2))

julia> axes(F.U)
(SimpleAxis(1:2), offset(2)(SimpleAxis(1:2)))

julia> F.p
2-element Vector{Int64}:
 3
 2

julia> axes(F.P)
(offset(1)(SimpleAxis(1:2)), offset(1)(SimpleAxis(1:2)))

julia> axes(F.P * m)
(offset(1)(SimpleAxis(1:2)), offset(2)(SimpleAxis(1:2)))

julia> axes(F.L * F.U)
(offset(1)(SimpleAxis(1:2)), offset(2)(SimpleAxis(1:2)))

```
""" lu

function LinearAlgebra.lu!(A::AxisArray, args...; kwargs...)
    inner_lu = lu!(parent(A), args...; kwargs...)
    return LU(
        unsafe_reconstruct(A, getfield(inner_lu, :factors); axes=axes(A)),
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
        return unsafe_reconstruct(A, inner, axes=(axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :U
        return unsafe_reconstruct(A, inner, axes=(SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    elseif d === :P
        return unsafe_reconstruct(A, inner, axes=(axes(A, 1), axes(A, 1)))
    elseif d === :p
        return _add_offset(axes(A, 1), inner)
        #=
        if is_offset_axis(axis)
            return inner .+ offsets(axis, 1)
        else
            return inner
        end
        =#
    else
        return inner
    end
end

"""
    lq(A::AxisArray, args...; kwargs...)

Compute the LQ factorization of an `AxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (2:3, 3:4));

julia> F = lq(m);

julia> axes(F.L)
(offset(1)(SimpleAxis(1:2)), SimpleAxis(1:2))

julia> axes(F.Q)
(SimpleAxis(1:2), offset(2)(SimpleAxis(1:2)))

julia> axes(F.L * F.Q)
(offset(1)(SimpleAxis(1:2)), offset(2)(SimpleAxis(1:2)))
```
"""
LinearAlgebra.lq(A::AxisArray, args...; kws...) = lq!(copy(A), args...; kws...)
function LinearAlgebra.lq!(A::AxisArray, args...; kwargs...)
    F = lq!(parent(A), args...; kwargs...)
    inner = getfield(F, :factors)
    return LQ(unsafe_reconstruct(A, inner, axes=axes(A)), getfield(F, :τ))
end
function Base.parent(F::LQ{T,<:AxisArray}) where {T}
    return LQ(parent(getfield(F, :factors)), getfield(F, :τ))
end

@inline function Base.getproperty(F::LQ{T,<:AxisArray}, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::LQ, A::AbstractArray, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return unsafe_reconstruct(A, inner, axes=(axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Q
        return unsafe_reconstruct(A, inner, axes=(SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    else
        return inner
    end
end

const AIQRUnion{T} = Union{LinearAlgebra.QRCompactWY{T,<:AxisArray},
                                     QRPivoted{T,<:AxisArray},
                                     QR{T,<:AxisArray}}

"""
    qr(F::AxisArray, args...; kwargs...)

Compute the QR factorization of an `AxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (2:3, 3:4));

julia> F = qr(m, Val(true));

julia> axes(F.Q)
(offset(1)(SimpleAxis(1:2)), SimpleAxis(1:2))

julia> axes(F.R)
(SimpleAxis(1:2), offset(2)(SimpleAxis(1:2)))

julia> axes(F.Q * F.R)
(offset(1)(SimpleAxis(1:2)), offset(2)(SimpleAxis(1:2)))

julia> axes(F.p)
(Base.OneTo(2),)

julia> axes(F.P)
(offset(1)(SimpleAxis(1:2)), offset(1)(SimpleAxis(1:2)))

julia> axes(F.P * AxisArray([1.0 2; 3 4], (2:3, 3:4)))
(offset(1)(SimpleAxis(1:2)), offset(2)(SimpleAxis(1:2)))

```

"""
function LinearAlgebra.qr(A::AxisArray{T,2}, args...; kwargs...) where T
    Base.require_one_based_indexing(A)
    AA = similar(A, LinearAlgebra._qreltype(T), axes(A))
    copyto!(AA, A)
    return qr!(AA, args...; kwargs...)
end

function LinearAlgebra.qr!(a::AxisArray, args...; kwargs...)
    return _qr(a, qr!(parent(a), args...; kwargs...), axes(a))
end

function _qr(a::AxisArray, F::QR, axs::Tuple)
    return QR(unsafe_reconstruct(a, getfield(F, :factors); axes=axs), F.τ)
end
function Base.parent(F::QR{<:Any,<:AxisArray})
    return QR(parent(getfield(F, :factors)), getfield(F, :τ))
end

function _qr(a::AxisArray, F::LinearAlgebra.QRCompactWY, axs::Tuple)
    return LinearAlgebra.QRCompactWY(
        unsafe_reconstruct(a, getfield(F, :factors); axes=axs),
        F.T
    )
end
function Base.parent(F::LinearAlgebra.QRCompactWY{<:Any, <:AxisArray})
    return LinearAlgebra.QRCompactWY(parent(getfield(F, :factors)), getfield(F, :T))
end

function _qr(a::AxisArray, F::QRPivoted, axs::Tuple)
    return QRPivoted(
        unsafe_reconstruct(a, getfield(F, :factors), axes=axs),
        getfield(F, :τ),
        getfield(F, :jpvt)
    )
end
function Base.parent(F::QRPivoted{<:Any, <:AxisArray})
    return QRPivoted(parent(getfield(F, :factors)), getfield(F, :τ), getfield(F, :jpvt))
end

@inline function Base.getproperty(F::AIQRUnion, d::Symbol)
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::Q, A::AbstractArray, d::Symbol) where {Q<:Union{LinearAlgebra.QRCompactWY,QRPivoted,QR}}
    inner = getproperty(F, d)
    if d === :Q
        return unsafe_reconstruct(A, inner; axes=(axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :R
        return unsafe_reconstruct(A, inner; axes=(SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    elseif F isa QRPivoted && d === :P
        return unsafe_reconstruct(A, inner; axes=(axes(A, 1), axes(A, 1)))
    elseif F isa QRPivoted && d === :p
        return _add_offset(axes(A, 1), inner)
        #=
        axis = 
        if known_offset(axis) === nothing || known_offset(axis) !== 1
            return inner .+ offsets(axis, 1)
        else
            return inner
        end
        =#
    else
        return inner
    end
end

struct AxisSVD{T,F<:SVD{T},A<:AxisArray} <: Factorization{T}
    factor::F
    array::A
end

"""
    svd(F::AxisArray, args...; kwargs...)

Compute the singular value decomposition (SVD) of an `AxisArray` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisArray([1.0 2; 3 4], (2:3, 3:4));

julia> F = svd(m);

julia> axes(F.U)
(offset(1)(SimpleAxis(1:2)), SimpleAxis(1:2))

julia> axes(F.V)
(offset(2)(SimpleAxis(1:2)), SimpleAxis(1:2))

julia> axes(F.Vt)
(SimpleAxis(1:2), offset(2)(SimpleAxis(1:2)))

julia> axes(F.U * Diagonal(F.S) * F.Vt)
(offset(1)(SimpleAxis(1:2)), offset(2)(SimpleAxis(1:2)))

```
"""
function LinearAlgebra.svd(A::AxisArray, args...; kwargs...)
    return AxisSVD(svd(parent(A), args...; kwargs...), A)
end

function LinearAlgebra.svd!(A::AxisArray, args...; kwargs...)
    return AxisSVD(svd!(parent(A), args...; kwargs...), A)
end

Base.parent(F::AxisSVD) = getfield(F, :factor)

Base.size(F::AxisSVD) = size(parent(F))

Base.size(F::AxisSVD, i) = size(parent(F), i)

function Base.propertynames(F::AxisSVD, private::Bool=false)
    return private ? (:V, fieldnames(typeof(parent(F)))...) : (:U, :S, :V, :Vt)
end

Base.show(io::IO, F::AxisSVD) = show(io, MIME"text/plain"(), F)
function Base.show(io::IO, mime::MIME{Symbol("text/plain")}, F::AxisSVD{T}) where {T}
    print(io, "AxisSVD{$T}\n")
    println(io, "U factor:")
    show(io, mime, F.U)
    println(io, "\nsingular values:")
    show(io, mime, F.S)
    println(io, "\nVt factor:")
    show(io, mime, F.Vt)
end

LinearAlgebra.svdvals(A::AxisArray) = svdvals(parent(A))

# iteration for destructuring into components
Base.iterate(S::AxisSVD) = (S.U, Val(:S))
Base.iterate(S::AxisSVD, ::Val{:S}) = (S.S, Val(:V))
Base.iterate(S::AxisSVD, ::Val{:V}) = (S.V, Val(:done))
Base.iterate(S::AxisSVD, ::Val{:done}) = nothing
# TODO GeneralizedSVD

@inline function Base.getproperty(F::AxisSVD, d::Symbol)
    return get_factorization(parent(F), getfield(F, :array), d)
end

function get_factorization(F::SVD, A::AbstractArray, d::Symbol)
    inner = getproperty(F, d)
    if d === :U
        return unsafe_reconstruct(A, inner, axes=(axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :V
        return unsafe_reconstruct(A, inner, axes=(axes(A, 2), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Vt
        return unsafe_reconstruct(A, inner, axes=(SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    else  # d === :S
        return inner
    end
end

function LinearAlgebra.eigen(A::AxisArray{T,N,P,AI}; kwargs...) where {T,N,P,AI}
    vals, vecs = LinearAlgebra.eigen(parent(A); kwargs...)
    return Eigen(vals, unsafe_reconstruct(A, vecs; axes=axes(A)))
end

function LinearAlgebra.eigvals(A::AxisArray; kwargs...)
    return LinearAlgebra.eigvals(parent(A); kwargs...)
end

# TODO test this
function LinearAlgebra.eigen!(A::AxisArray{T,N,P,AI}; kwargs...) where {T,N,P,AI}
    vals, vecs = LinearAlgebra.eigen!(parent(A); kwargs...)
    return Eigen(vals, unsafe_reconstruct(A, vecs; axes=axes(A)))
end

function LinearAlgebra.eigvals!(A::AxisArray; kwargs...)
    return LinearAlgebra.eigvals!(parent(A); kwargs...)
end
 
#TODO eigen!(::AbstractArray, ::AbstractArray)

