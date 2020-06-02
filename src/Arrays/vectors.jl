
# TODO: AxisVector documentation
"""
    AxisVector
"""
const AxisVector{T,P<:AbstractVector{T},Ax} = AxisArray{T,1,P,Tuple{Ax}}

function AxisVector{T}(x::AbstractVector{T}, ks::AbstractVector) where {T}
    axis = Axes.to_axis(ks, axes(x, 1))
    return AxisArray{T,1,typeof(x),Tuple{typeof(axis)}}(x, (axis,))
end

AxisVector(x::AbstractVector{T}, ks::AbstractVector) where {T} = AxisVector{T}(x, ks)

function AxisVector{T}() where {T}
    return AxisArray{T,1,Vector{T},Tuple{OneToMRange{Int}}}(T[], SimpleAxis(OneToMRange(0)))
end

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
    deleteat!(a::AbstractAxisVector, arg)

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

function Base.insert!(A::AbstractAxisVector, index, item)
    is_dynamic(A) || throw(MethodError(insert!, (A, index, item)))
    axis = axes(A, 1)
    unsafe_insert!(parent(A), axis, to_index(axis, index), item)
    return A
end

function unsafe_insert!(data::AbstractVector{T}, axis, index::Integer, item::I) where {T,I}
    unsafe_insert!(data, axis, index, convert(T, item))
    return nothing
end

function unsafe_insert!(data::AbstractVector{T}, axis, index::Integer, item::I) where {T,I<:T}
    grow_last!(axis, 1)
    insert!(data, index, item)
    return nothing
end

function Base.resize!(x::AbstractAxisVector, n::Integer)
    resize!(parent(x), n)
    resize_last!(axes(x, 1), n)
    return x
end

function Base.push!(A::AbstractAxisVector, item)
    StaticRanges.can_set_last(axes(A, 1)) || throw(MethodError(push!, (A, item)))
    push!(parent(A), item)
    grow_last!(axes(A, 1), 1)
    return A
end

function Base.push!(A::AbstractAxisVector, item::Pair)
    axis = axes(A, 1)
    StaticRanges.can_set_last(axis) || throw(MethodError(push!, (A, item)))
    push!(parent(A), last(item))
    Axes.push_key!(axis, first(item))
    return A
end

function Base.pushfirst!(A::AbstractAxisVector, item)
    grow_first!(axes(A, 1), 1)
    pushfirst!(parent(A), item)
    return A
end

function Base.pushfirst!(A::AbstractAxisVector, item::Pair)
    axis = axes(A, 1)
    StaticRanges.can_set_first(axis) || throw(MethodError(pushfirst!, (A, item)))
    pushfirst!(parent(A), last(item))
    Axes.pushfirst_key!(axis, first(item))
    return A
end

###
### f
###

function _merge_non_continuous_vectors!(x, y)
    yaxis = axes(y, 1)
    xaxis = axes(x, 1)
    for (k,v) in yaxis
        idx = findfirst(==(k), keys(xaxis)) 
        if idx === nothing
            Axes.push_key!(xaxis, k)
            push!(values(x), v)
        else
            @inbounds setindex!(x, v, k)
        end
    end
end

function _merge_continuous_vectors!(x, y)
end

