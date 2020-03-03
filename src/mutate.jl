# Methods that mutate the axes of an AbstractAxisIndices

function Base.empty!(a::AbstractAxisIndices)
    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end

function Base.push!(A::AbstractAxisIndices{T,1}, items...) where {T}
    grow_last!(axes(A, 1), length(items))
    push!(parent(A), items...)
    return A
end

function Base.pushfirst!(A::AbstractAxisIndices{T,1}, items...) where {T}
    grow_first!(axes(A, 1), length(items))
    pushfirst!(parent(A), items...)
    return A
end

function Base.pop!(A::AbstractAxisIndices{T,1}) where {T}
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end

function Base.popfirst!(A::AbstractAxisIndices{T,1}) where {T}
    shrink_first!(axes(A, 1), 1)
    return popfirst!(parent(A))
end

function Base.append!(A::AbstractAxisIndices{T,1}, collection) where {T}
    append_axis!(axes(A, 1), axes(collection, 1))
    append!(parent(A), collection)
    return A
end

