

_broadcast(axis, inds) = inds
_broadcast(axis, inds::AbstractUnitRange{<:Integer}) = assign_indices(axis, inds)

for (f, FT, arg) in ((:-, typeof(-), Number),
                     (:+, typeof(+), Real),
                     (:*, typeof(*), Real))
    @eval begin
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return _broadcast(r, broadcast($f, x, indices(r)))
        end
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, r::AbstractAxis, x::$arg)
            return _broadcast(r, broadcast($f, indices(r), x))
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
        return combine_axis(a, b)
    else
        if _bcsm(b, a)
            return combine_axis(b, a)
        else
            throw(DimensionMismatch("arrays could not be broadcast to a common size;" *
                                    " got a dimension with lengths $(length(a)) and $(length(b))"))
        end
    end
end

# _bcsm tests whether the second index is consistent with the first
_bcsm(a, b) = length(a) == length(b) || length(b) == 1

keys_or_nothing(x::AbstractAxis) = keys(x)
keys_or_nothing(x) = nothing

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

function cat_axis(x::AbstractAxis, y::AbstractAxis, inds=cat_indices(x, y))
    if is_indices_axis(x)
        if is_indices_axis(y)
            return unsafe_reconstruct(x, inds)
        else
            return unsafe_reconstruct(y, set_length(keys(y), length(inds)), inds)
        end
    else
        if is_indices_axis(y)
            return unsafe_reconstruct(x, set_length(keys(x), length(inds)), inds)
        else
            return unsafe_reconstruct(y, cat_keys(keys(x), keys(y)), inds)
        end
    end
end

function cat_axis(x::AbstractUnitRange, y::AbstractAxis, inds=cat_indices(x, y))
    if is_indices_axis(y)
        return unsafe_reconstruct(y, inds)
    else
        return unsafe_reconstruct(y, set_length(keys(y), length(inds)), inds)
    end
end

function cat_axis(x::AbstractAxis, y::AbstractUnitRange, inds=cat_indices(x, y))
    if is_indices_axis(x)
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(x, set_length(keys(x), length(inds)), inds)
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
# TODO document combine_indices
#=
    combine_indices(x, y)

=#
combine_indices(x, y) = _combine_indices(indices(x), indices(y))
_combine_indices(x::X, y::Y) where {X,Y} = promote_type(X, Y)(x)

# LinearIndices indicates that keys are not formally defined so the collection
# that isn't LinearIndices is used. If both are LinearIndices then take the underlying
# OneTo as the new keys.
combine_keys(x, y) = _combine_keys(keys(x), keys(y))
_combine_keys(x, y) = promote_axis_collections(x, y)
_combine_keys(x,                y::LinearIndices) = x
_combine_keys(x::LinearIndices, y               ) = y
_combine_keys(x::LinearIndices, y::LinearIndices) = first(y.indices)

@inline function combine_axis(x::AbstractAxis, y::AbstractAxis, inds=combine_indices(x, y))
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
            return unsafe_reconstruct(y, combine_keys(x, y), inds)
        end
    end
end

@inline function combine_axis(x, y::AbstractAxis, inds=combine_indices(x, y))
    if is_indices_axis(y)
        return unsafe_reconstruct(y, inds)
    else
        return unsafe_reconstruct(y, keys(y), inds)
    end
end

@inline function combine_axis(x::AbstractAxis, y, inds=combine_indices(x, y))
    if is_indices_axis(x)
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(x, keys(x), inds)
    end
end


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

