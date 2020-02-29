
function LinearAlgebra.lu!(a::AxisIndicesArray, args...; kwargs...)
    inner_lu = lu!(parent(a), args...; kwargs...)
    return LU(
        AxisIndicesArray(getfield(inner_lu, :factors), axes(a)),
        getfield(inner_lu, :ipiv),
        getfield(inner_lu, :info)
       )
end

function Base.parent(F::LU{T,<:AxisIndicesArray}) where {T}
    return LU(parent(getfield(F, :factors)), getfield(F, :ipiv), getfield(F, :info))
end

@inline function Base.getproperty(F::LU{T,<:AxisIndicesArray}, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

function get_factorization(F::LU, A::AbstractAxisIndices, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        axs = (axes(A, 1), SimpleAxis(OneTo(size(inner, 2))))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :U
        axs = (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :P
        axs = (axes(A, 1), axes(A, 1))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :p
        axs = (axes(A, 1),)
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    else
        return inner
    end
end
