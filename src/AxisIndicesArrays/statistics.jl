
for fun in (:cor, :cov)
    @eval function Statistics.$fun(a::AbstractAxisIndices{T,2}; dims=1, kwargs...) where {T}
        return unsafe_reconstruct(
            a,
            Statistics.$fun(parent(a); dims=dims, kwargs...),
            covcor_axes(a, dims)
        )
    end
end

for f in (:mean, :std, :var, :median)
    @eval function Statistics.$f(a::AbstractAxisIndices; dims=:, kwargs...)
        return indicesarray_result(a, Statistics.$f(parent(a); dims=dims, kwargs...), dims)
    end
end

