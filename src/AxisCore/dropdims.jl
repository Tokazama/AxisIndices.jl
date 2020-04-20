
"""
    drop_axes(x, dims)

Returns all axes of `x` except for those identified by `dims`. Elements of `dims`
must be unique integers or symbols corresponding to the dimensions or names of
dimensions of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axs = (Axis(1:5), Axis(1:10));

julia> AxisIndices.drop_axes(axs, 1)
(Axis(1:10 => Base.OneTo(10)),)

julia> AxisIndices.drop_axes(axs, 2)
(Axis(1:5 => Base.OneTo(5)),)

julia> AxisIndices.drop_axes(rand(2, 4), 2)
(Base.OneTo(2),)
```
"""
@inline drop_axes(x::AbstractArray, dims) = drop_axes(axes(x), dims)
@inline drop_axes(x::Tuple{Vararg{<:Any}}, dims::Int) = drop_axes(x, (dims,))
@inline drop_axes(x::Tuple{Vararg{<:Any}}, dims::Tuple) = _drop_axes(x, dims)
_drop_axes(x, y) = select_axes(x, dropinds(x, y))

dropinds(x, y) = _dropinds(x, y)
Base.@pure @inline function _dropinds(x::Tuple{Vararg{Any,N}}, dims::NTuple{M,Int}) where {N,M}
    out = ()
    for i in 1:N
        cnd = true
        for j in dims
            if i === j
                cnd = false
                break
            end
        end
        if cnd
            out = (out..., i)
        end
    end
    return out::NTuple{N - M, Int}
end

select_axes(x::Tuple, dims::NTuple{N,Int}) where {N} = map(i -> getfield(x, i), dims)

function Base.dropdims(a::AbstractAxisIndices; dims)
    return unsafe_reconstruct(a, dropdims(parent(a); dims=dims), drop_axes(a, dims))
end

