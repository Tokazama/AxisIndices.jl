# This file is for methods that change the size of axes or arrays

for f in (:grow_last!, :grow_first!, :shrink_last!, :shrink_first!)
    @eval begin
        function StaticRanges.$f(axis::AbstractSimpleAxis, n::Integer)
            StaticRanges.$f(values(axis), n)
            return axis
        end

        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            StaticRanges.$f(keys(axis), n)
            StaticRanges.$f(values(axis), n)
            return axis
        end
    end
end

for f in (:grow_last, :grow_first, :shrink_last, :shrink_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractSimpleAxis, n::Integer)
            return unsafe_reconstruct(axis, StaticRanges.$f(values(axis), n))
        end

        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), n),
                StaticRanges.$f(values(axis), n)
            )
        end
    end
end

"""
    deleteat!(a::AbstractAxisIndicesVector, arg)

Remove the items corresponding to `A[arg]`, and return the modified `a`. Subsequent
items are shifted to fill the resulting gap. If the axis of `a` is an `AbstractSimpleAxis`
then it is shortened to match the length of `a`. If the 

## Examples
```jldoctest
julia> using AxisIndices

julia> x = AxisIndicesArray([1, 2, 3, 4]);

julia> axes_keys(deleteat!(x, 3))
(OneToMRange(3),)

julia> x = AxisIndicesArray([1, 2, 3, 4], ["a", "b", "c", "d"]);

julia> axes_keys(deleteat!(x, "c"))
(["a", "b", "d"],)

```
"""
function Base.deleteat!(A::AbstractAxisIndices{T,1,P,Tuple{Ax1}}, arg) where {T,P,Ax1<:AbstractSimpleAxis}
    inds = to_index(axes(A, 1), arg)
    shrink_last!(axes(A, 1), length(inds))
    deleteat!(parent(A), inds)
    return A
end

function Base.deleteat!(A::AbstractAxisIndices{T,1,P,Tuple{Ax1}}, arg) where {T,P,Ax1<:AbstractAxis}
    inds = to_index(axes(A, 1), arg)
    deleteat!(axes_keys(A, 1), inds)
    shrink_last!(indices(A, 1), length(inds))
    deleteat!(parent(A), inds)
    return A
end

function Base.resize!(x::AbstractAxisIndices{T,1}, n::Integer) where {T}
    resize!(parent(x), n)
    resize_last!(axes(x, 1), n)
    return x
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

function Base.empty!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    empty!(keys(a))
    empty!(values(a))
    return a
end

function Base.empty!(a::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    empty!(values(a))
    return a
end

Base.isempty(a::AbstractAxis) = isempty(values(a))

