

# TODO I'm not totally sold on this implementation.
# should the axis's keys reflect what remains after filtering?
function Base.filter(f, A::AbstractAxisIndices{T,1}) where {T}
    p = filter(f, parent(A))
    axs = (shrink_last(axes(A, 1), length(p) - length(A)),)
    return similar_type(A, typeof(p), typeof(axs))(p, axs)
end
Base.filter(f, A::AbstractAxisIndices) = filter(f, parent(A))
