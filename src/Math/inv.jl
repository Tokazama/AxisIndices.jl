
function Base.inv(a::AbstractAxisIndices{T,2}) where {T}
    return unsafe_reconstruct(a, inv(parent(a)), permute_axes(axes(a)))
end

