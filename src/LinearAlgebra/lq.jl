
LinearAlgebra.lq(A::AbstractAxisIndices, args...; kws...) = lq!(copy(A), args...; kws...)
function LinearAlgebra.lq!(A::AbstractAxisIndices, args...; kwargs...)
    F = lq!(parent(A), args...; kwargs...)
    inner = getfield(F, :factors)
    return LQ(similar_type(A, typeof(inner))(inner, axes(A)), getfield(F, :τ))
end
function Base.parent(F::LQ{T,<:AbstractAxisIndices}) where {T}
    return LQ(parent(getfield(F, :factors)), getfield(F, :τ))
end

Base.axes(F::LQ{T,<:AbstractAxisIndices}) where {T} = axes(getfield(F, :factors))

Base.axes(F::LQ{T,<:AbstractAxisIndices}, i) where {T} = axes(F)[i]

@inline function Base.getproperty(F::LQ{T,<:AbstractAxisIndices}, d::Symbol) where {T}
    return get_factorization(getfield(F, :factors), parent(F), axes(F), d)
end

function get_factorization(A::AbstractAxisIndices, F::LQ, axs::NTuple{2,Any}, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        axs = (first(axs), SimpleAxis(OneTo(size(inner, 2))))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :Q
        axs = (SimpleAxis(OneTo(size(inner, 1))), last(axs))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    else
        return inner
    end
end
