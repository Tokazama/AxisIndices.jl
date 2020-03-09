
"""
    append_axis!(x, y)
    append_axis!(::CombineStyle, x, y)

Returns the appended axes `x` and `y`.

## Examples
```jldoctest
julia> using AxisIndices

julia> x, y = Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10));

julia> AxisIndices.append_axis!(x, y);

julia> length(x)
20

julia> AxisIndices.append_axis!(y, x);

julia> length(y)
30
```
"""
append_axis!(x, y) = append_axis!(CombineStyle(x), x, y)
function append_axis!(::CombineResize, x, y)
    return set_length!(x, length(x) + length(y))
end
function append_axis!(cs::CombineStack, x, y) where {T}
    if eltype(x) <: eltype(y)
        for x_i in x
            if x_i in y
                error("Element $x_i appears in both collections in call to append_axis!(collection1, collection2). All elements must be unique.")
            end
        end
        return append!(x, y)
    else
        return append_axis!(x, _promote_axis_collections(y, x))
    end
end

function append_axis!(::CombineAxis, x::X, y::Y) where {X,Y}
    append_axis!(keys(x), keys(y))
    append_axis!(values(x), values(y))
    return x
end
function append_axis!(::CombineSimpleAxis, x::X, y::Y) where {X,Y}
    append_axis!(values(x), values(y))
    return x
end

