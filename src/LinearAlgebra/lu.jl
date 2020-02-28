
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

Base.axes(F::LU{T,<:AxisIndicesArray}) where {T} = axes(getfield(F, :factors))

Base.axes(F::LU{T,<:AxisIndicesArray}, i) where {T} = axes(F)[i]

@inline function Base.getproperty(F::LU{T,<:AxisIndicesArray}, d::Symbol) where {T}
    return get_factorization(getfield(F, :factors), parent(F), axes(F), d)
end

function get_factorization(A::AbstractAxisIndices, F::LU, axs::NTuple{2,Any}, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        axs = (first(axs), SimpleAxis(OneTo(size(inner, 2))))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :U
        axs = (SimpleAxis(OneTo(size(inner, 1))), last(axs))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :P
        axs = (first(axs), first(axs))
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    elseif d === :p
        axs = (first(axs),)
        return similar_type(A, typeof(inner), typeof(axs))(inner, axs)
    else
        return inner
    end
end
