"""
    append_axis(x, y)

Returns the appended axes `x` and `y`. New subtypes of `AbstractAxis` must
implement a unique `append_axis` method.

## Examples
```jldoctest
julia> using AxisIndices

julia> append_axis(Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
Axis(UnitMRange(1:20) => UnitMRange(1:20))

julia> append_axis(SimpleAxis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
SimpleAxis(UnitMRange(1:20))
```
"""
append_axis(x::Axis, y::Axis) = Axis(append_keys(x, y), append_values(x, y))
append_axis(x::SimpleAxis, y::SimpleAxis) = SimpleAxis(append_values(x, y))
append_axis(x, y) = same_type(x, y) ? append_values(x, y) : append_axis(promote(x, y)...)

"""
    append_keys(x, y)

Returns the appropriate keys of and index within the operation `append_axis(x, y)`

See also: [`append_axis`](@ref)
"""
append_keys(x, y) = cat_keys(x, y)

"""
    append_values(x, y)

Returns the appropriate values of and index within the operation `append_axis(x, y)`

See also: [`append_axis`](@ref)
"""
append_values(x, y) = cat_values(x, y)

"""
    append_axis!(x, y)

Returns the appended axes `x` and `y`. New subtypes of `AbstractAxis` must
implement a unique `append_axis!` method.

## Examples
```jldoctest
julia> using AxisIndices

julia> x, y = Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10));

julia> append_axis!(x, y);

julia> length(x)
20

julia> append_axis!(y, x);

julia> length(y)
30
```
"""
function append_axis!(x::Axis, y)
    _append_keys!(keys(x), y)
    set_length!(values(x), length(x) + length(y))
    return x
end
function append_axis!(x::SimpleAxis, y)
    set_length!(x, length(x) + length(y))
    return x
end

_append_keys!(x, y) = __append_keys!(StaticRanges.Continuity(x), x, y)
__append_keys!(::StaticRanges.ContinuousTrait, x, y) = set_length!(x, length(x) + length(y))
__append_keys!(::StaticRanges.DiscreteTrait, x, y) = make_unique!(x, keys(y))

