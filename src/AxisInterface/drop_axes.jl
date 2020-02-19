
"""
    drop_axes(x, dims)

Returns all axes of `x` except for those identified by `dims`. Elements of `dims`
must be unique integers or symbols corresponding to the dimensions or names of
dimensions of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axs = (Axis(1:5), Axis(1:10));

julia> drop_axes(axs, 1)
(Axis(1:10 => Base.OneTo(10)),)

julia> drop_axes(axs, 2)
(Axis(1:5 => Base.OneTo(5)),)

julia> drop_axes(rand(2, 4), 2)
(Base.OneTo(2),)
```
"""
drop_axes(x::AbstractArray, dims) = drop_axes(axes(x), dims)
drop_axes(x::Tuple{Vararg{<:Any}}, dims::Int) = drop_axes(x, (dims,))
function drop_axes(x::Tuple{Vararg{<:Any,D}}, dims::NTuple{N,Int}) where {D,N}
    for i in 1:N
        1 <= dims[i] <= D || throw(ArgumentError("dropped dims must be in range 1:ndims(A)"))
        for j = 1:i-1
            dims[j] == dims[i] && throw(ArgumentError("dropped dims must be unique"))
        end
    end
    d = ()
    for (i,axis_i) in zip(1:D,x)
        if !in(i, dims)
            d = tuple(d..., axis_i)
        end
    end
    return d
end

