
struct AxisIndicesSVD{T,F<:SVD{T},Ax} <: Factorization{T}
    factor::F
    axes::Ax
end

function LinearAlgebra.svd(A::AxisIndicesArray, args...; kwargs...)
    return AxisIndicesSVD(svd(parent(A), args...; kwargs...), axes(A))
end

function LinearAlgebra.svd!(A::AxisIndicesArray, args...; kwargs...)
    return AxisIndicesSVD(svd!(parent(A), args...; kwargs...), axes(A))
end

Base.parent(F::AxisIndicesSVD) = getfield(F, :factor)

Base.axes(F::AxisIndicesSVD) = getfield(F, :axes)

Base.axes(F::AxisIndicesSVD, i) = getfield(F, :axes)[i]

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

LinearAlgebra.svdvals(A::AxisIndicesArray) = sdvals(parent(A))

# iteration for destructuring into components
Base.iterate(S::AxisIndicesSVD) = (S.U, Val(:S))
Base.iterate(S::AxisIndicesSVD, ::Val{:S}) = (S.S, Val(:V))
Base.iterate(S::AxisIndicesSVD, ::Val{:V}) = (S.V, Val(:done))
Base.iterate(S::AxisIndicesSVD, ::Val{:done}) = nothing
# TODO GeneralizedSVD

@inline function Base.getproperty(F::AxisIndicesSVD, d::Symbol) where {T}
    return get_factorization(parent(F), axes(F), d)
end

function get_factorization(F::SVD, axs::NTuple{2,Any}, d::Symbol)
    inner = getproperty(F, d)
    if d === :U
        return AxisIndicesArray(inner, (first(axs), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :V
        return AxisIndicesArray(inner, (last(axs), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Vt
        return AxisIndicesArray(inner, (SimpleAxis(OneTo(size(inner, 1))), last(axs)))
    else  # d === :S
        return inner
    end
end
