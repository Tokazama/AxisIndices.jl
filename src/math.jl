
for (N1,N2) in ((2,2), (1,2), (2,1))
    @eval begin
        function Base.:*(a::AxisIndicesArray{T1,$N1}, b::AxisIndicesArray{T2,$N2}) where {T1,T2}
            return _matmul(promote_type(T1, T2), *(parent(a), parent(b)), matmul_axes(a, b))
        end
        function Base.:*(a::AbstractArray{T1,$N1}, b::AxisIndicesArray{T2,$N2}) where {T1,T2}
            return _matmul(promote_type(T1, T2), *(a, parent(b)), matmul_axes(a, b))
        end
        function Base.:*(a::AxisIndicesArray{T1,$N1}, b::AbstractArray{T2,$N2}) where {T1,T2}
            return _matmul(promote_type(T1, T2), *(parent(a), b), matmul_axes(a, b))
        end
    end
end

function Base.:*(a::Diagonal{T1}, b::AxisIndicesArray{T2,2}) where {T1,T2}
    return _matmul(promote_type(T1, T2), *(a, parent(b)), matmul_axes(a, b))
end
function Base.:*(a::AxisIndicesArray{T1,2}, b::Diagonal{T2}) where {T1,T2}
    return _matmul(promote_type(T1, T2), *(parent(a), b), matmul_axes(a, b))
end

_matmul(::Type{T}, a::T, axs) where {T} = a
_matmul(::Type{T}, a::AbstractArray{T}, axs) where {T} = AxisIndicesArray(a, axs)


# Using `CovVector` results in Method ambiguities; have to define more specific methods.
for A in (Adjoint{<:Any, <:AbstractVector}, Transpose{<:Real, <:AbstractVector{<:Real}})
    @eval function Base.:*(a::$A, b::AxisIndicesArray{T,1,<:AbstractVector{T}}) where {T}
        return *(a, parent(b))
    end
end

# vector^T * vector
Base.:*(a::AxisIndicesArray{T,2,<:CoVector}, b::AxisIndicesArray{S,1}) where {T,S} = *(parent(a), parent(b))

Base.inv(a::AxisIndicesMatrix) = AxisIndicesArray(inv(parent(a)), inverse_axes(a))

# Statistics
for fun in (:cor, :cov)
    @eval function Statistics.$fun(a::AxisIndicesMatrix; dims=1, kwargs...)
        return AxisIndicesArray(Statistics.$fun(parent(a); dims=dims, kwargs...), covcor_axes(a, dims))
    end
end

