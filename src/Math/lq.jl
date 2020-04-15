
LinearAlgebra.lq(A::AbstractAxisIndices, args...; kws...) = lq!(copy(A), args...; kws...)
function LinearAlgebra.lq!(A::AbstractAxisIndices, args...; kwargs...)
    F = lq!(parent(A), args...; kwargs...)
    inner = getfield(F, :factors)
    return LQ(unsafe_reconstruct(A, inner, axes(A)), getfield(F, :τ))
end
function Base.parent(F::LQ{T,<:AbstractAxisIndices}) where {T}
    return LQ(parent(getfield(F, :factors)), getfield(F, :τ))
end

@inline function Base.getproperty(F::LQ{T,<:AbstractAxisIndices}, d::Symbol) where {T}
    return get_factorization(parent(F), getfield(F, :factors), d)
end

"""

    get_factorization(F::LQ, A::AbstractArray, d::Symbol)

Returns a component of the LQ decomposition `F` with the appropriate axes given `A`.

## LQ Factorization
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisIndicesArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

julia> F = lq(m);

julia> keys.(axes(F.L))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.Q))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.L * F.Q))
(2:3, 3:4)
```
"""
function get_factorization(F::LQ, A::AbstractArray, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return unsafe_reconstruct(A, inner, (axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :Q
        return unsafe_reconstruct(A, inner, (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    else
        return inner
    end
end
function LinearAlgebra.lu!(a::AxisIndicesArray, args...; kwargs...)
    inner_lu = lu!(parent(a), args...; kwargs...)
    return LU(
        AxisIndicesArray(getfield(inner_lu, :factors), axes(a)),
        getfield(inner_lu, :ipiv),
        getfield(inner_lu, :info)
       )
end

