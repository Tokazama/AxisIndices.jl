# Methods that mutate the axes of an AbstractAxisIndices

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices, value, inds...)
    return setindex!(parent(a), value, to_indices(a, inds)...)
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

function Base.empty!(a::AbstractAxisIndices)
    for ax_i in axes(a)
        if !can_set_length(ax_i)
            error("Cannot perform `empty!` on AbstractAxisIndices that has an axis with a fixed size.")
        end
    end

    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end


###
### resize
###
# Note that all `grow_*`/`shrink_*` functions ignore the possibility that `d` is
# negative. Although these are documented, they should probably be considered
# unsafe and only used internally.

