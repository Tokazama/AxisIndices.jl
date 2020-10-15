
for (f, FT, arg) in ((:-, typeof(-), Number),
                     (:+, typeof(+), Real),
                     (:*, typeof(*), Real))
    @eval begin
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return maybe_unsafe_reconstruct(r, broadcast($f, x, parent(r)); keys=keys(r))
        end
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, r::AbstractAxis, x::$arg)
            return maybe_unsafe_reconstruct(r, broadcast($f, parent(r), x); keys=keys(r))
        end
    end
end

#=
for (f, FT, arg) in ((:+, typeof(+), Real),)
    @eval begin
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return unsafe_reconstruct(r, broadcast($f, x, eachindex(r)))
        end
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, r::AbstractAxis, x::$arg)
            return unsafe_reconstruct(r, broadcast($f, eachindex(r), x))
        end
    end
end
=#

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
    return (combine_axis(first(shape), first(newshape)), _bcs(tail(shape), tail(newshape))...)
end

_parent_if_axis(x::AbstractAxis) = parent(x)

###
### cat
###
cat_indices(x, y) = set_length(indices(x), length(x) + length(y))

cat_keys(x::AbstractVector, y::AbstractRange) = StaticRanges.grow_last(y, length(x))

cat_keys(x::AbstractRange, y::AbstractVector) = StaticRanges.grow_last(x, length(y))

cat_keys(x::AbstractRange, y::AbstractRange) = StaticRanges.grow_last(x, length(y))

cat_keys(x::AbstractVector, y::AbstractVector) = cat_keys!(promote(x, y)...,)

cat_keys(x::AbstractVector{T}, y::AbstractVector{T}) where {T} = cat_keys!(copy(x), y)

function cat_keys!(x::AbstractVector{T}, y::AbstractVector{T}) where {T}
    for x_i in x
        if x_i in y
            error("Element $x_i appears in both collections in call to cat_axis!(collection1, collection2). All elements must be unique.")
        end
    end
    return vcat(x, y)
end

function cat_axis(x::Axis, y::AbstractUnitRange, inds=cat_indices(x, y))
    return maybe_unsafe_reconstruct(x, inds; keys=cat_keys(keys(x), keys(y)))
end

function cat_axis(x::Axis, y::Axis, inds=cat_indices(x, y))
    return maybe_unsafe_reconstruct(x, inds; keys=cat_keys(keys(x), keys(y)))
end

function cat_axis(x::AbstractUnitRange, y::Axis, inds=cat_indices(x, y))
    return maybe_unsafe_reconstruct(y, inds; keys=cat_keys(keys(x), keys(y)))
end

function cat_axis(x::AbstractUnitRange, y::AbstractUnitRange, inds=cat_indices(x, y))
    if x isa AbstractAxis
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(y, inds)
    end
end

#=
    cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray, dims)

Produces the appropriate set of axes where `x` and `y` are the arrays that were
concatenated over `dims` to produce `xy`. The appropriate indices of each axis
are derived from from `xy`.
=#
@inline function cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray{T,N}, dims) where {T,N}
    ntuple(Val(N)) do i
        if i in dims
            cat_axis(axes(x, i), axes(y, i), axes(xy, i))
        else
            combine_axis(axes(x, i), axes(y, i), axes(xy, i))
        end
    end
end
# TODO do these work?
vcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray) = cat_axes(x, y, xy, 1)

hcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray) = cat_axes(x, y, xy, 2)

###
### combine
###
# LinearIndices indicates that keys are not formally defined so the collection
# that isn't LinearIndices is used. If both are LinearIndices then take the underlying
# OneTo as the new keys.
combine_keys(x, y) = _combine_keys(keys(x), keys(y))
_combine_keys(x, y) = promote_axis_collections(x, y)
_combine_keys(x,                y::LinearIndices) = x
_combine_keys(x::LinearIndices, y               ) = y
_combine_keys(x::LinearIndices, y::LinearIndices) = first(y.indices)

# TODO I still really don't like this solution but the result seems better than any
# alternative I've seen out there
#=
Problem: String, Symbol, Second, etc. don't promote neatly with Int (default key value)
Solution: Symbol(element), Second(element) for promotion
Exception: String(element) doesn't work so string(element) has to be used
=#

promote_axis_collections(x::X, y::X) where {X} = x

function promote_axis_collections(x::LinearIndices{1}, y::Y) where {Y}
    return promote_axis_collections(x.indices[1], y)
end
function promote_axis_collections(x::X, y::LinearIndices{1}) where {X}
    return promote_axis_collections(x, y.indices[1])
end
function promote_axis_collections(x::LinearIndices{1}, y::LinearIndices{1})
    return promote_axis_collections(x.indices[1], y.indices[1])
end
function promote_axis_collections(x::X, y::Y) where {X,Y}
    if promote_rule(X, Y) <: Union{}
        Z = promote_rule(Y, X)
    else
        Z = promote_rule(X, Y)
    end
    if Z <: Union{}
        Tx = eltype(X)
        Ty = eltype(Y)
        Tnew = promote_type(Tx, Ty)
        if Tnew == Any
            if is_key(Tx)
                if Tx <: AbstractString
                    return promote_axis_collections(x, string.(y))
                else
                    return promote_axis_collections(x, Tx.(y))
                end
            else
                if is_key(Ty)
                    if Ty <: AbstractString
                        return promote_axis_collections(string.(x), y)
                    else
                        return promote_axis_collections(Ty.(x), y)
                    end
                else
                    error("No method available for promoting keys of type $Tx and $Ty.")
                end
            end
        else
            return promote_axis_collections(Tnew.(x), y)
        end
    else
        return Z(x)
    end
end

###
### combine_axis
###
combine_axis(x, y) = combine_axis(x, y, _combine_indices(x, y))
combine_axis(x, y, inds) = SimpleAxis(inds)
combine_axis(x, y::AbstractAxis, inds) = combine_axis(y, x, inds)
combine_axis(x::AbstractAxis, y, inds) = unsafe_reconstruct(x, inds)
function combine_axis(x::AbstractAxis, y::AbstractAxis, inds)
    return unsafe_reconstruct(x, unsafe_reconstruct(y, inds))
end

combine_axis(x::SimpleAxis, y::AbstractAxis, inds) = combine_axis(parent(x), y, inds)
combine_axis(x::AbstractAxis, y::SimpleAxis, inds) = combine_axis(x, parent(y), inds)
combine_axis(x::SimpleAxis, y::SimpleAxis, inds) = combine_axis(parent(x), parent(y), inds)

# Axis
combine_axis(x::Axis, y, inds) = resize_last(x, inds)
combine_axis(x::Axis, y::SimpleAxis, inds) = combine_axis(x, parent(y), inds)
function combine_axis(x::Axis, y::AbstractAxis, inds)
    return resize_last(x, combine_axis(parent(x), y, inds))
end
# TODO check this stuff
function combine_axis(x::Axis, y::Axis, inds)
    return Axis(
        combine_keys(x, y),
        combine_axis(parent(x), parent(y), inds);
        checks=NoChecks
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

