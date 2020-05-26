
_broadcast(axis, inds) = inds
_broadcast(axis, inds::AbstractUnitRange{<:Integer}) = assign_indices(axis, inds)

for (f, FT, arg) in ((:-, typeof(-), Number),
                     (:+, typeof(+), Real),
                     (:*, typeof(*), Real))
    @eval begin
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return _broadcast(r, broadcast($f, x, values(r)))
        end
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, r::AbstractAxis, x::$arg)
            return _broadcast(r, broadcast($f, values(r), x))
        end
    end
end


function Broadcast.broadcast_shape(
    shape1::Tuple,
    shape2::Tuple{Vararg{<:AbstractAxis}},
    shapes::Tuple...
   )
    return Broadcast.broadcast_shape(_bcs(shape1, shape2), shapes...)
end

function Broadcast.broadcast_shape(
    shape1::Tuple{Vararg{<:AbstractAxis}},
    shape2::Tuple,
    shapes::Tuple...
   )
    return Broadcast.broadcast_shape(_bcs(shape1, shape2), shapes...)
end
function Broadcast.broadcast_shape(
    shape1::Tuple{Vararg{<:AbstractAxis}},
    shape2::Tuple{Vararg{<:AbstractAxis}},
    shapes::Tuple...
   )
    return Broadcast.broadcast_shape(_bcs(shape1, shape2), shapes...)
end

# _bcs consolidates two shapes into a single output shape
_bcs(::Tuple{}, ::Tuple{}) = ()
_bcs(::Tuple{}, newshape::Tuple) = (newshape[1], _bcs((), tail(newshape))...)
_bcs(shape::Tuple, ::Tuple{}) = (shape[1], _bcs(tail(shape), ())...)
function _bcs(shape::Tuple, newshape::Tuple)
    return (_bcs1(first(shape), first(newshape)), _bcs(tail(shape), tail(newshape))...)
end

function _bcs1(a, b)
    if _bcsm(a, b)
        return broadcast_axis(a, b)
    else
        if _bcsm(b, a)
            return broadcast_axis(b, a)
        else
            throw(DimensionMismatch("arrays could not be broadcast to a common size; got a dimension with lengths $(length(a)) and $(length(b))"))
        end
    end
end

# _bcsm tests whether the second index is consistent with the first
_bcsm(a, b) = length(a) == length(b) || length(b) == 1

keys_or_nothing(x::AbstractAxis) = keys(x)
keys_or_nothing(x) = nothing

#=
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
=#

function broadcast_axis(x::AbstractAxis, y::AbstractAxis, inds::AbstractUnitRange{<:Integer})
    if is_indices_axis(x)
        if is_indices_axis(y)
            return unsafe_reconstruct(x, inds)
        else
            return unsafe_reconstruct(y, keys(y), inds)
        end
    else
        if is_indices_axis(y)
            return unsafe_reconstruct(x, keys(x), inds)
        else
            return unsafe_reconstruct(y, promote_axis_collections(keys(x), keys(y)), inds)
        end
    end
end

function broadcast_axis(x::AbstractAxis, y::AbstractUnitRange{<:Integer}, inds::AbstractUnitRange{<:Integer})
    if is_indices_axis(x)
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(x, keys(x), inds)
    end
end

function broadcast_axis(x::AbstractUnitRange{<:Integer}, y::AbstractAxis, inds::AbstractUnitRange{<:Integer})
    if is_indices_axis(y)
        return unsafe_reconstruct(y, inds)
    else
        return unsafe_reconstruct(y, keys(y), inds)
    end
end

function broadcast_axis(x::AbstractUnitRange{<:Integer}, y::AbstractUnitRange{<:Integer}, inds::AbstractUnitRange{<:Integer})
    return inds
end

function broadcast_axis(x::AbstractAxis, y::AbstractAxis)
    inds = promote_axis_collections(indices(x), indices(y))
    if is_indices_axis(x)
        if is_indices_axis(y)
            return unsafe_reconstruct(x, inds)
        else
            return unsafe_reconstruct(y, keys(y), inds)
        end
    else
        if is_indices_axis(y)
            return unsafe_reconstruct(x, keys(x), inds)
        else
            return unsafe_reconstruct(y, promote_axis_collections(keys(x), keys(y)), inds)
        end
    end
end

function broadcast_axis(x::AbstractAxis, y::AbstractUnitRange{<:Integer})
    inds = promote_axis_collections(indices(x), indices(y))
    if is_indices_axis(x)
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(x, keys(x), inds)
    end
end

function broadcast_axis(x::AbstractUnitRange{<:Integer}, y::AbstractAxis)
    inds = promote_axis_collections(indices(x), indices(y))
    if is_indices_axis(y)
        return unsafe_reconstruct(y, inds)
    else
        return unsafe_reconstruct(y, keys(y), inds)
    end
end

function broadcast_axis(x::AbstractUnitRange{<:Integer}, y::AbstractUnitRange{<:Integer})
    return promote_axis_collections(indices(x), indices(y))
end

