
function StaticRanges.unsafe_grow_end!(A::AxisVector, n)
    StaticRanges.unsafe_grow_end!(axes(A, 1), n)
    StaticRanges.unsafe_grow_end!(parent(A), n)
end

function StaticRanges.unsafe_shrink_end!(A::AxisVector, n)
    StaticRanges.unsafe_shrink_end!(axes(A, 1), n)
    StaticRanges.unsafe_shrink_end!(parent(A), n)
end

function Base.push!(A::AxisVector, item)
    can_change_size(axes(A, 1)) || throw(MethodError(push!, (A, item)))
    push!(parent(A), item)
    StaticRanges.unsafe_grow_end!(axes(A, 1), 1)
    return A
end

function Base.push!(A::AxisVector, item::Pair)
    axis = axes(A, 1)
    can_change_size(axis) || throw(MethodError(push!, (A, item)))
    push!(parent(A), last(item))
    push_key!(axis, first(item))
    return A
end

function Base.pushfirst!(A::AxisVector, item)
    can_change_size(A) || throw(MethodError(pushfirst!, (A, item)))
    unsafe_grow_at!(axes(A, 1), 1)
    pushfirst!(parent(A), item)
    return A
end

function Base.append!(A::AxisVector{T,V,Ax}, collection) where {T,V,Ax}
    unsafe_grow_end!(axes(A, 1), length(collection))
    append!(parent(A), collection)
    return A
end

function Base.pop!(A::AxisVector)
    unsafe_shrink_end!(axes(A, 1), 1)
    return pop!(parent(A))
end

function Base.popfirst!(A::AxisVector)
    unsafe_shrink_at!(axes(A, 1), 1)
    return popfirst!(parent(A))
end

"""
    deleteat!(a::AxisVector, arg)

Remove the items corresponding to `A[arg]`, and return the modified `a`. Subsequent
items are shifted to fill the resulting gap. If the axis of `a` is an `SimpleAxis`
then it is shortened to match the length of `a`.

## Examples
```jldoctest
julia> using AxisIndices

julia> x = AxisArray([1, 2, 3, 4]);

julia> deleteat!(x, 3)
3-element AxisArray(::Vector{Int64}
  • axes:
     1 = 1:3
)
     1
  1  1
  2  2
  3  4  

julia> x = AxisArray([1, 2, 3, 4], ["a", "b", "c", "d"]);

julia> keys.(axes(deleteat!(x, "c")))
(["a", "b", "d"],)

```
"""
function Base.deleteat!(A::AxisVector{T,P,Ax}, arg) where {T,P,Ax}
    i = to_index(axes(A, 1), arg)
    unsafe_shrink_at!(axes(A, 1), i)
    deleteat!(parent(A), i)
    return A
end

# FIXME insert items in arrays with keys
function Base.insert!(A::AxisVector, index, item)
    can_change_size(A) || throw(MethodError(insert!, (A, index, item)))
    axis = axes(A, 1)
    unsafe_insert!(parent(A), axis, to_index(axis, index), item)
    return A
end

function unsafe_insert!(data::AbstractVector{T}, axis, index::Int, item::I) where {T,I}
    unsafe_insert!(data, axis, index, convert(T, item))
    return nothing
end

function unsafe_insert!(data::AbstractVector{T}, axis, index::Int, item::I) where {T,I<:T}
    unsafe_grow_end!(axis, 1)
    insert!(data, index, item)
    return nothing
end

function Base.resize!(x::AxisVector, n::Integer)
    dif = length(x) - n
    if dif > 0
        unsafe_shrink_end!(axes(x, 1), dif)
    else
        unsafe_grow_end!(axes(x, 1), abs(dif))
    end
    resize!(parent(x), n)
    return x
end
