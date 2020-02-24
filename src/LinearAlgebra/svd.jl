
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

function Base.getproperty(F::AxisIndicesSVD, s::Symbol)
    inner = getproperty(parent(F), s)
    if s === :U
        return AxisIndicesArray(inner, (axes(F, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif s === :V
        return AxisIndicesArray(inner, (axes(F, 2), SimpleAxis(OneTo(size(inner, 2)))))
    elseif s === :Vt
        return AxisIndicesArray(inner, (SimpleAxis(OneTo(size(inner, 1))), axes(F, 2)))
    else  # d === :S
        return inner
    end
end

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
