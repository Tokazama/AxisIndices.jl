
function LinearAlgebra.lu!(a::AxisIndicesArray, args...; kwargs...)
    inner_lu = lu!(parent(a), args...; kwargs...)
    return LU(
        AxisIndicesArray(getfield(inner_lu, :factors), axes(a)),
        getfield(inner_lu, :ipiv),
        getfield(inner_lu, :info)
       )
end

function Base.parent(F::LU{T,<:AxisIndicesArray}) where {T}
    return LU(
        parent(getfield(F, :factors)),
        getfield(F, :ipiv),
        getfield(F, :info)
       )
end

Base.axes(F::LU{T,<:AxisIndicesArray}) where {T} = axes(getfield(F, :factors))

Base.axes(F::LU{T,<:AxisIndicesArray}, i) where {T} = axes(F)[i]

@inline function Base.getproperty(F::LU{T,<:AxisIndicesArray}, d::Symbol) where {T}
    return get_factorization(parent(F), axes(F), d)
end

function get_factorization(F::LU, axs::NTuple{2,Any}, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return AxisIndicesArray(inner, (first(axs), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :U
        return AxisIndicesArray(inner, (SimpleAxis(OneTo(size(inner, 1))), last(axs)))
    elseif d === :P
        return AxisIndicesArray(inner, (first(axs), first(axs)))
    elseif d === :p
        return AxisIndicesArray(inner, (first(axs),))
    else
        return inner
    end
end
