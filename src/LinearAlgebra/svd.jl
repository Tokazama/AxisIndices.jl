
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
        axs = (axes(A, 1), SimpleAxis(OneTo(size(inner, 2))))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :V
        axs = (axes(A, 2), SimpleAxis(OneTo(size(inner, 2))))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :Vt
        axs = (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    else  # d === :S
        return inner
    end
end
