
for f in (:sum!, :prod!, :maximum!, :minimum!)
    for (A,B) in ((AbstractAxisIndices, AbstractArray),
                  (AbstractArray,       AbstractAxisIndices),
                  (AbstractAxisIndices, AbstractAxisIndices))
        @eval begin
            function Base.$f(a::$A, b::$B)
                Base.$f(parent(a), parent(b))
                return a
            end
        end
    end
end


for f in (:cumsum, :cumprod)
    @eval function Base.$f(a::AbstractAxisIndices; dims, kwargs...)
        return AxisIndicesArray(Base.$f(parent(a); dims=dims, kwargs...), axes(a))
    end

    # Vector case
    @eval function Base.$f(a::AbstractAxisIndices{T,1}; kwargs...) where {T}
        return unsafe_reconstruct(a, Base.$f(parent(a); kwargs...), axes(a))
    end
end

# if reducing over `:` then results is a scalar
indicesarray_result(original_ia, reduced_data, reduction_dims::Colon) = reduced_data
function indicesarray_result(original_ia, reduced_data, reduction_dims)
    return AxisIndicesArray(reduced_data, reduce_axes(original_ia, reduction_dims))
end

for f in (:sum, :prod, :maximum, :minimum, :extrema)
    @eval function Base.$f(a::AbstractAxisIndices; dims=:, kwargs...)
        return indicesarray_result(a, Base.$f(parent(a); dims=dims, kwargs...), dims)
    end
end

for f in (:(==), :isequal, :isapprox)
    @eval begin
        Base.$f(a::AbstractAxisIndices, b::AbstractAxisIndices; kw...) = $f(parent(a), parent(b); kw...)
        Base.$f(a::AbstractAxisIndices, b::AbstractArray; kw...) = $f(parent(a), b; kw...)
        Base.$f(a::AbstractArray, b::AbstractAxisIndices; kw...) = $f(a, parent(b); kw...)
    end
end

for f in (:zero, :one, :copy)
    @eval begin
        function Base.$f(a::AbstractAxisIndices)
            return unsafe_reconstruct(a, Base.$f(parent(a)), axes(a))
        end
    end
end

