
keys_or_nothing(x::AbstractAxis) = keys(x)
keys_or_nothing(x) = nothing

"""
    broadcast_axis(x, y) -> collection
    broadcast_axis(::PromoteStyle, ::CombineStyle, x, y)

Returns an axis given the axes `x` and `y` that are appropriate for a broadcasting operation.

## Examples
```jldoctest combine_examples
julia> using AxisIndices

julia> a, b = 1:10, Base.OneTo(10);

julia> AxisIndices.broadcast_axis(a, SimpleAxis(b))
SimpleAxis(1:10)

julia> AxisIndices.broadcast_axis(a, b)
1:10

julia> AxisIndices.broadcast_axis(b, a)
1:10

julia> c = AxisIndices.broadcast_axis(a, SimpleAxis(b))
SimpleAxis(1:10)

julia> d = AxisIndices.broadcast_axis(SimpleAxis(b), a)
SimpleAxis(1:10)

julia> e = AxisIndices.broadcast_axis(c, d)
SimpleAxis(1:10)

julia> f = AxisIndices.broadcast_axis(Axis(a), a)
Axis(1:10 => 1:10)

julia> g = AxisIndices.broadcast_axis(a, Axis(b))
Axis(Base.OneTo(10) => 1:10)

julia> AxisIndices.broadcast_axis(f, g)
Axis(1:10 => 1:10)

julia> AxisIndices.broadcast_axis(Base.OneTo(10), Base.OneTo(10))
Base.OneTo(10)

julia> AxisIndices.broadcast_axis(1:10, Base.OneTo(10))
1:10
```

Using `combine` allows combining axes that aren't appropriate for conventional
promotion.
```jldoctest combine_examples
julia> AxisIndices.broadcast_axis(1:2, string.(1:2))
2-element Array{String,1}:
 "1"
 "2"

julia> AxisIndices.broadcast_axis(1:2, Symbol.(1:2))
2-element Array{Symbol,1}:
 Symbol("1")
 Symbol("2")
```
"""
broadcast_axis(x::AbstractVector, y::AbstractVector, inds) = broadcast_axis(CombineStyle(x, y), x, y, inds)
broadcast_axis(x::AbstractVector, y::AbstractVector) = broadcast_axis(CombineStyle(x, y), x, y)
broadcast_axis(x::AbstractVector, ::Nothing) = copy(x)
broadcast_axis(::Nothing, y::AbstractVector) = copy(y)

_promote_first(x::T, y::T) where {T} = x
_promote_first(x::T1, y::T2) where {T1,T2} = first(promote(x, y))

function broadcast_axis(::CombineAxis, x::X, y::Y, inds::I) where {X,Y,I}
    ks = broadcast_axis(keys_or_nothing(x), keys_or_nothing(y))
    return similar_type(promote_rule(X, Y), typeof(ks), I)(ks, inds)
end

function broadcast_axis(::CombineSimpleAxis, x::X, y::Y, inds::I) where {X,Y,I}
    return similar_type(promote_rule(X, Y), I)(inds)
end

# ignore new indices because this is combining keys
function broadcast_axis(ps::CombineStyle, x::X, y::Y) where {X, Y}
    return promote_axis_collections(x, y)
end

function broadcast_axis(::CombineAxis, x::X, y::Y) where {X,Y}
    ks = broadcast_axis(keys_or_nothing(x), keys_or_nothing(y))
    vs = broadcast_axis(values(x), values(y))
    return similar_type(promote_rule(X, Y), typeof(ks), typeof(vs))(ks, vs)
end

function broadcast_axis(::CombineSimpleAxis, x::X, y::Y) where {X,Y}
    vs = broadcast_axis(values(x), values(y))
    return similar_type(promote_rule(X, Y), typeof(vs))(vs)
end


#= TODO delete this garbage
"""
    broadcast_axes
"""
broadcast_axes(x, y) = broadcast_axes(axes(x), axes(y))
function broadcast_axes(x::Tuple, y::Tuple)
    return (broadcast_axes(first(x), first(y)), broadcast_axes(tail(x), tail(y))...)
end
broadcast_axes(x::Tuple{}, y::Tuple) = (broadcast_axis(first(x), first(y)), tail(y)...)
broadcast_axes(x::Tuple, y::Tuple{}) = (broadcast_axis(first(x), first(y)), tail(x)...)
broadcast_axes(x::Tuple{}, y::Tuple{}) = ()
=#

