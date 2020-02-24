function Base.push!(A::AxisIndicesVector, items...)
    grow_last!(axes(A, 1), length(items))
    push!(parent(A), items...)
    return A
end

function Base.pushfirst!(A::AxisIndicesVector, items...)
    grow_first!(axes(A, 1), length(items))
    pushfirst!(parent(A), items...)
    return A
end

function Base.pop!(A::AxisIndicesVector)
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end

function Base.popfirst!(A::AxisIndicesVector)
    shrink_first!(axes(A, 1), 1)
    return popfirst!(parent(A))
end

function Base.append!(A::AxisIndicesVector, collection)
    append_axis!(axes(A, 1), axes(collection, 1))
    append!(parent(A), collection)
    return A
end
