"""
    reshape(A::AbstractAxisIndices, shape)

Reshape the array and axes of `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = reshape(AxisIndicesArray(Vector(1:8), [:a, :b, :c, :d, :e, :f, :g, :h]), 4, 2);

julia> axes(A)
(Axis([:a, :b, :c, :d] => Base.OneTo(4)), SimpleAxis(Base.OneTo(2)))

julia> axes(reshape(A, 2, :))
(Axis([:a, :b] => Base.OneTo(2)), SimpleAxis(Base.OneTo(4)))
```
"""
function Base.reshape(A::AbstractAxisIndices, shp::NTuple{N,Int}) where {N}
    p = reshape(parent(A), shp)
    return unsafe_reconstruct(A, p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

function Base.reshape(A::AbstractAxisIndices, shp::Tuple{Vararg{Union{Int,Colon},N}}) where {N}
    p = reshape(parent(A), shp)
    return unsafe_reconstruct(A, p, reshape_axes(naxes(A, Val(N)), axes(p)))
end


#=
We need to assign new indices to axes of `A` but `reshape` may have changed the
size of any axis
=#
@inline function reshape_axis(axis::A, inds) where {A}
    if is_simple_axis(A)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, resize_last(keys(axis), length(inds)), inds)
    end
end

@inline function reshape_axes(axs::Tuple, inds::Tuple{Vararg{Any,N}}) where {N}
    return map(reshape_axis, axs, inds)
end

