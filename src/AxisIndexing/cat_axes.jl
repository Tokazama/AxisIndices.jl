
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


"""
    vcat_axes(x, y) -> Tuple

Returns the appropriate axes for `vcat(x, y)`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.vcat_axes((Axis(1:2), Axis(1:4)), (Axis(1:2), Axis(1:4)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> a, b = [1 2 3 4 5], [6 7 8 9 10; 11 12 13 14 15];

julia> AxisIndices.vcat_axes(a, b) == axes(vcat(a, b))
true

julia> c, d = LinearAxes((1:1, 1:5,)), LinearAxes((1:2, 1:5));

julia> length.(AxisIndices.vcat_axes(c, d)) == length.(AxisIndices.vcat_axes(a, b))
true
```
"""
vcat_axes(x::AbstractArray, y::AbstractArray) = vcat_axes(axes(x), axes(y))
function vcat_axes(x::Tuple{Any,Vararg}, y::Tuple{Any,Vararg})
    return (cat_axis(first(x), first(y)), Broadcast.broadcast_shape(tail(x), tail(y))...)
end

"""
    hcat_axes(x, y) -> Tuple

Returns the appropriate axes for `hcat(x, y)`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.hcat_axes((Axis(1:4), Axis(1:2)), (Axis(1:4), Axis(1:2)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> a, b = [1; 2; 3; 4; 5], [6 7; 8 9; 10 11; 12 13; 14 15];

julia> AxisIndices.hcat_axes(a, b) == axes(hcat(a, b))
true

julia> c, d = CartesianAxes((Axis(1:5),)), CartesianAxes((Axis(1:5), Axis(1:2)));

julia> length.(AxisIndices.hcat_axes(c, d)) == length.(AxisIndices.hcat_axes(a, b))
true
```
"""
hcat_axes(x::AbstractArray, y::AbstractArray) = hcat_axes(axes(x), axes(y))
function hcat_axes(x::Tuple, y::Tuple)
    return (broadcast_axis(first(x), first(y)), _hcat_axes(tail(x), tail(y))...)
end
_hcat_axes(x::Tuple{}, y::Tuple) = (grow_last(first(y), 1), tail(y)...)
_hcat_axes(x::Tuple, y::Tuple{}) = (grow_last(first(x), 1), tail(x)...)
_hcat_axes(x::Tuple{}, y::Tuple{}) = (SimpleAxis(OneTo(2)),)
function _hcat_axes(x::Tuple, y::Tuple)
    return (cat_axis(first(x), first(y)), broadcast_axes(tail(x), tail(y))...)
end

