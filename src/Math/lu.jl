
@doc """
    lu(A::AbstractAxisArray, args...; kwargs...)

Compute the LU factorization of an `AbstractAxisIndices` `A`.

## Examples
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> m = AxisIndicesArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

julia> F = lu(m);

julia> keys.(axes(F.L))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.U))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.p))
(2:3,)

julia> keys.(axes(F.P))
(2:3, 2:3)

julia> keys.(axes(F.P * m))
(2:3, 3:4)

julia> keys.(axes(F.L * F.U))
(2:3, 3:4)
```
""" lu

function LinearAlgebra.lu!(A::AbstractAxisIndices, args...; kwargs...)
    inner_lu = lu!(parent(A), args...; kwargs...)
    return LU(
        unsafe_reconstruct(A, getfield(inner_lu, :factors), axes(A)),
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

function get_factorization(F::LU, A::AbstractArray, d::Symbol)
    inner = getproperty(F, d)
    if d === :L
        return unsafe_reconstruct(A, inner, (axes(A, 1), SimpleAxis(OneTo(size(inner, 2)))))
    elseif d === :U
        return unsafe_reconstruct(A, inner, (SimpleAxis(OneTo(size(inner, 1))), axes(A, 2)))
    elseif d === :P
        return unsafe_reconstruct(A, inner, (axes(A, 1), axes(A, 1)))
    elseif d === :p
        return unsafe_reconstruct(A, inner, (axes(A, 1),))
    else
        return inner
    end
end

