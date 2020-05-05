
struct AxisIndicesSVD{T,F<:SVD{T},A<:AbstractAxisIndices} <: Factorization{T}
    factor::F
    axes_indices::A
end

"""
    svd(F::AbstractAxisArray, args...; kwargs...)

Compute the singular value decomposition (SVD) of an `AbstractAxisIndices` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisIndicesArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

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
function LinearAlgebra.svd(A::AbstractAxisIndices, args...; kwargs...)
    return AxisIndicesSVD(svd(parent(A), args...; kwargs...), A)
end

function LinearAlgebra.svd!(A::AbstractAxisIndices, args...; kwargs...)
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
