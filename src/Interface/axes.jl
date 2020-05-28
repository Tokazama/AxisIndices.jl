# FIXME this explanation is confusing.
"""
    axis_eltype(x)

Returns the type corresponds to the type of the ith element returned when slicing
along that dimension.
"""
axis_eltype(axis, i) = Any

# TODO document
axis_eltypes(axis) = Tuple{[axis_eltype(axis, i) for i in axis]...}
@inline axis_eltypes(axis, vs::AbstractVector) = Tuple{map(i -> axis_eltype(axis, i), vs)...}

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
drop_axes(x::AbstractArray, d::Int) = drop_axes(x, (d,))
drop_axes(x::AbstractArray, d::Tuple) = drop_axes(x, dims(dimnames(x), d))
drop_axes(x::AbstractArray, d::Tuple{Vararg{Int}}) = drop_axes(axes(x), d)
drop_axes(x::Tuple{Vararg{<:Any}}, d::Int) = drop_axes(x, (d,))
drop_axes(x::Tuple{Vararg{<:Any}}, d::Tuple) = _drop_axes(x, d)
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

# TODO document select_axes
select_axes(x::AbstractArray, d::Tuple) = select_axes(x, dims(dimnames(x), d))
select_axes(x::AbstractArray, d::Tuple{Vararg{Int}}) = map(i -> axes(x, i), d)
select_axes(x::Tuple, d::Tuple) = map(i -> getfield(x, i), d)

#=
    print_axis_compactly(io, axis)

Determines how `axis` is printed when above a printed array
=#
print_axis_compactly(io, x) = print(io, x)
print_axis_compactly(io, x::AbstractUnitRange) = print(io, "$(first(x)):$(last(x))")
function print_axis_compactly(io, x::AbstractRange)
    print(io, "$(first(x)):$(step(x)):$(last(x))")
end

function print_axis(io, axis)
    if haskey(io, :compact)
        print_axis_compactly(io, keys(axis))
    else
        if is_indices_axis(axis)
            print(io, "$(typeof(axis).name)($(keys(axis)))")
        else
            print(io, "$(typeof(axis).name)($(keys(axis)) => $(indices(axis)))")
        end
    end
end

