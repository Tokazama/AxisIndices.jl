
LinearAlgebra.eigen(A::AbstractAxisIndices; kwargs...) = LinearAlgebra.eigen!(A; kwargs...)

function LinearAlgebra.eigen!(A::AbstractAxisIndices{T,N,P,AI}; kwargs...) where {T,N,P,AI}
    vals, vecs = LinearAlgebra.eigen!(parent(A); kwargs...)
    return Eigen(vals, similar_type(A, typeof(vecs), AI)(vecs, axes(A)))
end

function LinearAlgebra.eigvals!(A::AbstractAxisIndices; kwargs...)
    return LinearAlgebra.eigvals!(parent(A); kwargs...)
end

#TODO eigen!(::AbstractArray, ::AbstractArray)

