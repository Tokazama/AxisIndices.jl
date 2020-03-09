
"""
    cat_axis(x, y) -> cat_axis(CombineStyle(x, y), x, y)
    cat_axis(::CombineStyle, x, y) -> collection

Returns the concatenated axes `x` and `y`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.cat_axis(Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
Axis(UnitMRange(1:20) => UnitMRange(1:20))

julia> AxisIndices.cat_axis(SimpleAxis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
SimpleAxis(UnitMRange(1:20))
```
"""
cat_axis(x, y) = cat_axis(CombineStyle(x, y), x, y)

function cat_axis(cs::CombineResize, x::X, y::Y) where {X,Y}
    return set_length(promote_axis_collections(x, y), length(x) + length(y))
end

function cat_axis(cs::CombineStack, x::X, y::Y) where {X,Y}
    for x_i in x
        if x_i in y
            error("Element $x_i appears in both collections in call to cat_axis!(collection1, collection2). All elements must be unique.")
        end
    end
    return vcat(x, y)
end

function cat_axis(::CombineAxis, x::X, y::Y) where {X,Y}
    ks = cat_axis(keys(x), keys(y))
    vs = cat_axis(values(x), values(y))
    return similar_type(promote_type(X, Y), typeof(ks), typeof(vs))(ks, vs)
end

function cat_axis(::CombineSimpleAxis, x::X, y::Y) where {X,Y}
    vs = cat_axis(values(x), values(y))
    return similar_type(similar_type(X, Y), typeof(vs))(vs)
end

