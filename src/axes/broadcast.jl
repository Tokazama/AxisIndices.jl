
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
    return (broadcast_axis(first(shape), first(newshape)), _bcs(tail(shape), tail(newshape))...)
end


for (f, FT, arg) in ((:-, typeof(-), Number),
                     (:+, typeof(+), Real),
                     (:*, typeof(*), Real))
    @eval begin
        function Base.broadcasted(b::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return maybe_unsafe_reconstruct(r, Base.broadcasted(b, $f, x, parent(r)); keys=keys(r))
        end
        function Base.broadcasted(b::DefaultArrayStyle{1}, ::$FT, r::AbstractAxis, x::$arg)
            return maybe_unsafe_reconstruct(r, Base.broadcasted(b, $f, parent(r), x); keys=keys(r))
        end
    end
end

broadcast_axis(x, y) = broadcast_axis(x, y, _combine_indices(x, y))
broadcast_axis(x, y, inds) = SimpleAxis(inds)
broadcast_axis(x, y::AbstractAxis, inds) = broadcast_axis(y, x, inds)
broadcast_axis(x::AbstractAxis, y, inds) = unsafe_reconstruct(x, inds)
function broadcast_axis(x::AbstractAxis, y::AbstractAxis, inds)
    if y isa AbstractOffsetAxis
        return unsafe_reconstruct(x, unsafe_reconstruct(parent(y), inds))
    else
        return unsafe_reconstruct(x, unsafe_reconstruct(y, inds))
    end
end

broadcast_axis(x::SimpleAxis, y::AbstractAxis, inds) = broadcast_axis(parent(x), y, inds)
broadcast_axis(x::AbstractAxis, y::SimpleAxis, inds) = broadcast_axis(x, parent(y), inds)
broadcast_axis(x::SimpleAxis, y::SimpleAxis, inds) = broadcast_axis(parent(x), parent(y), inds)

# Axis
broadcast_axis(x::Axis, y, inds) = resize_last(x, inds)
broadcast_axis(x::Axis, y::SimpleAxis, inds) = broadcast_axis(x, parent(y), inds)
function broadcast_axis(x::Axis, y::AbstractAxis, inds)
    return resize_last(x, broadcast_axis(parent(x), y, inds))
end
# TODO check this stuff
function broadcast_axis(x::Axis, y::Axis, inds)
    return Axis(
        combine_keys(x, y),
        broadcast_axis(parent(x), parent(y), inds)
    )
end

_combine_indices(x, y) = One():_combine_length(static_length(x), static_length(y))
function _combine_length(::StaticInt{X}, ::StaticInt{Y}) where {X,Y}
    return StaticInt(_combine_length(X, Y))
end
_combine_length(::StaticInt{X}, y) where {X} = _combine_length(X, y)
_combine_length(x, ::StaticInt{Y}) where {Y} = _combine_length(x, Y)
function _combine_length(x, y)
    if x == y || y == 1
        return x
    elseif x == 1
        return y
    else
        throw(DimensionMismatch("arrays could not be broadcast to a common size;" *
                                " got a dimension with lengths $(x) and $(y)"))
    end
end

