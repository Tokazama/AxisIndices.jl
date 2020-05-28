
const AxisVector{T,P<:AbstractVector{T},Ax} = AxisArray{T,1,P,Tuple{Ax}}

###
### Vector Methods
###

function Base.append!(A::AbstractAxisVector{T}, collection) where {T}
    append_axis!(axes(A, 1), axes(collection, 1))
    append!(parent(A), collection)
    return A
end

function Base.pop!(A::AbstractAxisVector)
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end


function Base.popfirst!(A::AbstractAxisVector)
    shrink_first!(axes(A, 1), 1)
    return popfirst!(parent(A))
end

function Base.reverse(x::AbstractAxisVector)
    p = reverse(parent(x))
    return unsafe_reconstruct(x, p, (reverse_keys(axes(x, 1), axes(p, 1)),))
end

"""
    deleteat!(a::AbstractAxisVectorVector, arg)

Remove the items corresponding to `A[arg]`, and return the modified `a`. Subsequent
items are shifted to fill the resulting gap. If the axis of `a` is an `AbstractSimpleAxis`
then it is shortened to match the length of `a`. If the 

## Examples
```jldoctest
julia> using AxisIndices

julia> x = AxisArray([1, 2, 3, 4]);

julia> axes_keys(deleteat!(x, 3))
(OneToMRange(3),)

julia> x = AxisArray([1, 2, 3, 4], ["a", "b", "c", "d"]);

julia> axes_keys(deleteat!(x, "c"))
(["a", "b", "d"],)

```
"""
function Base.deleteat!(A::AbstractAxisVector{T,P,Ax}, arg) where {T,P,Ax}
    if is_indices_axis(Ax)
        inds = to_index(axes(A, 1), arg)
        shrink_last!(axes(A, 1), length(inds))
        deleteat!(parent(A), inds)
        return A
    else
        inds = to_index(axes(A, 1), arg)
        deleteat!(axes_keys(A, 1), inds)
        shrink_last!(indices(A, 1), length(inds))
        deleteat!(parent(A), inds)
        return A
    end
end

function Base.resize!(x::AbstractAxisVector, n::Integer)
    resize!(parent(x), n)
    resize_last!(axes(x, 1), n)
    return x
end

function Base.push!(A::AbstractAxisVector, items...)
    grow_last!(axes(A, 1), length(items))
    push!(parent(A), items...)
    return A
end

function Base.pushfirst!(A::AbstractAxisVector, items...)
    grow_first!(axes(A, 1), length(items))
    pushfirst!(parent(A), items...)
    return A
end
