
LinearAlgebra.lq(A::AxisIndicesArray, args...; kws...) = lq!(copy(A), args...; kws...)
function LinearAlgebra.lq!(A::AxisIndicesArray, args...; kwargs...)
    inner = lq!(parent(A), args...; kwargs...)
    return LQ(AxisIndicesArray(getfield(inner, :factors), axes(A)), getfield(inner, :τ))
end
function Base.parent(F::LQ{T,<:AxisIndicesArray}) where {T}
    return LQ(parent(getfield(F, :factors)), getfield(F, :τ))
end

Base.axes(F::LQ{T,<:AxisIndicesArray}) where {T} = axes(getfield(F, :factors))

Base.axes(F::LQ{T,<:AxisIndicesArray}, i) where {T} = axes(F)[i]

@inline function Base.getproperty(F::LQ{T,<:AxisIndicesArray}, d::Symbol) where {T}
    return get_factorization(parent(F), axes(F), d)
end

function get_factorization(F::LQ, axs::NTuple{2,Any}, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return AxisIndicesArray(inner, (first(axs), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Q
        return AxisIndicesArray(inner, (SimpleAxis(OneTo(size(inner, 1))), last(axs)))
    else
        return inner
    end
end
