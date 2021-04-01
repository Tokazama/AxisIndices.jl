
####################
### similar_axes ###
####################
# TODO choose better name for this b/c this assumes that they are the same size already
similar_axis(original, paxis, inds) = _similar_axis(original, paxis, inds)

# we can't be sure that the new indices aren't longer than the keys for Axis or StructAxis
# so we have to drop them
similar_axis(original::Axis, paxis, inds) = similar_axis(parent(axis), paxis, inds)
similar_axis(original::StructAxis, paxis, inds) = similar_axis(parent(axis), paxis, inds)

# If the original axis has an offset we should try to preserive that trait, but if the new
# type explicitly provides an offset then we should respect that
similar_axis(original::OffsetAxis, paxis, inds) =  _similar_offset_axis(original.offset, similar_axis(parent(original), paxis, inds))
similar_axis(original::PaddedAxis, paxis, inds) =  _similar_offset_axis(offset1(original), similar_axis(parent(original), paxis, inds))
function _similar_offset_axis(f, inds::I) where {I}
    if known_first(I) === 1
        return OffsetAxis(f, inds)
    else
        return inds
    end
end
similar_axis(original::CenteredAxis, paxis, inds) =  _similar_centered_axis(similar_axis(parent(original), paxis, inds))
function _similar_centered_axis(inds::I) where {I}
    if known_first(I) === 1
        return CenteredAxis(similar_axis(paxis, inds))
    else
        return similar_axis(paxis, inds)
    end
end
similar_axis(original::SimpleAxis, paxis, inds) = similar_axis(paxis, inds)
similar_axis(::OneTo, paxis, inds) = similar_axis(paxis, inds)

similar_axis(::OneTo, inds::Integer) = SimpleAxis(One():inds)
similar_axis(::OptionallyStaticUnitRange{One,Int}, inds::Integer) = SimpleAxis(One():inds)

# 2-args
similar_axis(paxis, dim::Integer) = SimpleAxis(One():dim)
function similar_axis(paxis::A, inds::I) where {A,I}
    if known_first(A) !== 1
        throw_offset_error(paxis)
    end
    return compose_axis(inds)
end

###################
### matmul_axes ###
###################
matmul_axes(a::Tuple{Any}, b::Tuple{Any,Any}) = (copy(first(a)), copy(last(b)))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any,Any}) = (copy(first(a)), copy(last(b)))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any}) = (copy(first(a)),)

###################
### covcor_axes ###
###################
function covcor_axes(a::Tuple{Any,Any}, dim::Int)
    if dim === 1
        len = length(first(a))
    else
        len = length(last(a))
    end
    return (reshape_axis(first(a), len), reshape_axis(last(a), len))
end
function covcor_axes(a::Tuple{Any,Any}, ::StaticInt{1})
    len = static_length(first(a))
    return (reshape_axis(first(a), len), reshape_axis(last(a), len))
end
function covcor_axes(a::Tuple{Any,Any}, ::StaticInt)
    len = static_length(last(a))
    return (reshape_axis(first(a), len), reshape_axis(last(a), len))
end

#################
### drop_axes ###
#################
function drop_axes(x::Tuple{Vararg{Any,N}}, dims) where {N}
    return _drop_axes(x, dims_indicators(dims, nstatic(Val(N))))
end
function _drop_axes(x::Tuple{Any,Vararg{Any}}, indicator::Tuple{False,Vararg{Any}})
    return (first(x), _drop_axes(tail(x), tail(indicator))...)
end
function _drop_axes(x::Tuple{Any,Vararg{Any}}, indicator::Tuple{True,Vararg{Any}})
    return _drop_axes(tail(x), tail(indicator))
end
function _drop_axes(x::Tuple{Any,Vararg{Any}}, indicator::Tuple{Bool,Vararg{Any}})
    if first(indicator)
        return (first(x), _drop_axes(tail(x), tail(indicator))...)
    else
        return _drop_axes(tail(x), tail(indicator))
    end
end

####################
### permute_axes ###
####################
permute_axes(x::AbstractArray{T,N}, perms) where {T,N} = permute_axes(axes(x), perms)
function permute_axes(x::NTuple{N,Any}, perms::AbstractVector{<:Integer}) where {N}
    return Tuple(map(i -> getindex(x, i), perms))
end
permute_axes(x::NTuple{N,Any}, p::NTuple{N,<:Integer}) where {N} = map(i -> getfield(x, i), p)
permute_axes(x::AbstractVector) = permute_axes(axes(x))
function permute_axes(x::Tuple{Ax}) where {Ax<:AbstractUnitRange}
    if is_static(Ax)
        return (SimpleAxis(OneToSRange(1)), first(x))
    elseif is_fixed(Ax)
        return (SimpleAxis(Base.OneTo(1)), first(x))
    else  # is_dynamic(Ax)
        return (SimpleAxis(OneToMRange(1)), first(x))
    end
end
permute_axes(x::AbstractMatrix) = permute_axes(axes(x))
permute_axes(x::NTuple{2,Any}) = (last(x), first(x))
function permute_axes(old_array::AbstractVector, new_array::AbstractMatrix)
    return (
        SimpleAxis(axes(new_array, 1)),
        unsafe_reconstruct(axes(old_array, 1), axes(new_array, 2))
    )
end

function permute_axes(old_array::AbstractMatrix, new_array::AbstractMatrix)
    return (
        unsafe_reconstruct(axes(old_array, 2), axes(new_array, 1)),
        unsafe_reconstruct(axes(old_array, 1), axes(new_array, 2))
    )
end
function permute_axes(old_array::AbstractMatrix, new_array::AbstractVector)
    return (unsafe_reconstruct(axes(old_array, 2), axes(new_array, 1)),)
end
function permute_axes(old_array::AbstractArray{T1,N}, new_array::AbstractArray{T2,N}, perms) where {T1,T2,N}
    ntuple(Val(N)) do i
        unsafe_reconstruct(axes(old_array, perms[i]), axes(new_array, i))
    end
end

######################
### broadcast_axes ###
######################
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

broadcast_axis(x, y) = broadcast_axis2(x, y)
broadcast_axis2(x, y) = SimpleAxis(_combine_length(x, y))

function broadcast_axis(x::KeyedAxis, y)
    xk, xaxis = strip_offset(x)
    yk, yaxis = strip_offset(y)
    return initialize(xk, broadcast_axis(xaxis, yaxis))
end
function broadcast_axis2(x, y::KeyedAxis)
    xk, xaxis = strip_offset(x)
    yk, yaxis = strip_offset(y)
    return initialize(yk, broadcast_axis(xaxis, yaxis))
end

function broadcast_axis(x::CenteredAxis, y)
    xo, xaxis = strip_offset(x)
    yo, yaxis = strip_offset(y)
    return initialize(xo, broadcast_axis(xaxis, yaxis))
end
function broadcast_axis2(x, y::CenteredAxis)
    xo, xaxis = strip_offset(x)
    yo, yaxis = strip_offset(y)
    return initialize(yo, broadcast_axis(xaxis, yaxis))
end

function broadcast_axis(x::OffsetAxis, y)
    xo, xaxis = strip_offset(x)
    yo, yaxis = strip_offset(y)
    return initialize(xo, broadcast_axis(xaxis, yaxis))
end
function broadcast_axis2(x, y::OffsetAxis)
    xo, xaxis = strip_offset(x)
    yo, yaxis = strip_offset(y)
    return initialize(yo, broadcast_axis(xaxis, yaxis))
end

broadcast_keys(::Nothing, y) = y
broadcast_keys(x, ::Nothing) = x
broadcast_keys(x, y) = x  # TODO

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

################
### cat_axes ###
################
cat_axes(dims::Tuple, x) = x
@inline cat_axes(dims::Tuple, x, y, zs...) = cat_axes(dims, _cat_axes(dims, x, y), zs...)
_cat_axes(::Tuple{}, x::Tuple, y::Tuple) = ()
@inline function _cat_axes(dims::Tuple, x::Tuple, y::Tuple)
    return (
        cat_axis(first(dims), maybe_first(x), maybe_first(y)),
        _cat_axes(tail(dims), maybe_tail(x), maybe_tail(y))...
    )
end

# TODO do these work?
vcat_axes(args...) = cat_axes(static(1), args...)

hcat_axes(args...) = cat_axes(static(2), args...)

# TODO handle combine AxisOffset and AxisOrigin
function cat_axis(indicator, x::OffsetAxis, y)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(xo, cat_axis(indicator, xp, yp))
end
function cat_axis2(indicator, x, y::OffsetAxis)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(yo, cat_axis(indicator, xp, yp))
end


function cat_axis(indicator, x::CenteredAxis, y)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(xo, cat_axis(indicator, xp, yp))
end
function cat_axis2(indicator, x, y::CenteredAxis)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(yo, cat_axis(indicator, xp, yp))
end

cat_axis(indicator, x, y) = cat_axis2(indicator, x, y)
cat_axis2(indicator, x, y) = _final_cat_axis(indicator, x, y)
# when resizing axes for concatenation we have to account for what is known at compile time
# if we don't know the dimensions being concatenated we don't know their sizes
function _final_cat_axis(indicator::Bool, x, y)
    if indicator
        return static(1):(length(x) + length(y))
    else
        return static(1):length(x)
    end
end
_final_cat_axis(::True, x, y) = static(1):(staatic_length(x) + static_length(y))
_final_cat_axis(::False, x, y) = _combine_length(static_length(x), static_length(y))


# TODO cat - specialize concatenation based on type of keys
function cat_axis(indicator, x::KeyedAxis, y)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end
function cat_axis2(indicator, x, y::KeyedAxis)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end
cat_keys(::True, k1, k2) = LazyVCat(k1, k2)
cat_keys(::False, k1, k2) = k1
function cat_keys(indicator::Bool, k1, k2)
    if indicator
        return LazyVCat(k1, k2[static(1):length(k2)])
    else
        return LazyVCat(k1, empty(k2))
    end
end

# PaddedAxis
function cat_axis(indicator, x::PaddedAxis, y)
    xp, xaxis = strip_pads(x)
    yp, yaxis = strip_pads(y)
    return cat_axis(indicator, cat_pads(xp, yp), cat_axis(indicator, xaxis, yaxis))
end
function cat_axis2(indicator, x, y::PaddedAxis)
    xp, xaxis = strip_pads(x)
    yp, yaxis = strip_pads(y)
    return cat_axis(indicator, cat_pads(xp, yp), cat_axis(indicator, xaxis, yaxis))
end

cat_pads(x, y) = static(1):(first_pad(x) + last_pad(x) + first_pad(y) + last_pad(y))
cat_pads(::Nothing, y) = static(1):(first_pad(y) + last_pad(y))
cat_pads(x, ::Nothing) = static(1):(first_pad(x) + last_pad(x))
cat_pads(::Nothing, ::Nothing) = static(1):static(0)


# TODO cat AxisStruct
function cat_axis(indicator, x::StructAxis, y)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end
function cat_axis2(indicator, x, y::StructAxis)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end

###################
### reduce_axes ###
###################
# TODO this should probably be in ArrayInterface.jl "dimensions.jl"
function Base.reduced_index(i::OptionallyStaticUnitRange)
    start = static_first(i)
    # keep last position dynamic for type stability b/c we don't know which axis is reduced
    return start:dynamic(start)
end
function Base.reduced_index(i::Slice{<:OptionallyStaticUnitRange})
    return Base.Slice(Base.reduced_index(i.indices))
end
function Base.reduced_index(i::IdentityUnitRange{<:OptionallyStaticUnitRange})
    return IdentityUnitRange(Base.reduced_index(i.indices))
end

reduced_axes(::Tuple{}, ::Tuple{}) = ()
function reduced_axes(axs::Tuple{A,Vararg{Any}}, x::Tuple{B,Vararg{Any}}) where {A,B}
    return (reduced_axis(first(axs), first(x)), reduced_axes(tail(axs), tail(x))...)
end
function reduced_axis(axis, ::True)
    start = static_first(axis)
    return @inbounds(axis[start:start])
end
reduced_axis(axis, ::False) = axis
function reduced_axis(axis, b::Bool)
    start = first(axis)
    if b
        return @inbounds(axis[start:dynamic(start)])
    else
        return @inbounds(axis[start:dynamic(last(axis))])
    end
end

###################
### resize_axes ###
###################
function ArrayInterface.can_change_size(::Type{T}) where {T<:Axis}
    return can_change_size(keys_type(T)) & can_change_size(parent_type(T))
end

#= unsafe_grow_end! =#
function StaticRanges.unsafe_grow_end!(axis::KeyedAxis, n::Integer)
    unsafe_grow_end!(keys(axis), n)
    unsafe_grow_end!(parent(axis), n)
    return nothing
end
function StaticRanges.unsafe_grow_end!(axis::AbstractAxis, n)
    unsafe_grow_end!(parent(axis), n)
end

#= unsafe_grow_at! =#
unsafe_grow_at!(axis::AbstractAxis, n) = unsafe_grow_at!(parent(axis), n)
function unsafe_grow_at!(axis::KeyedAxis, n)
    unsafe_grow_at!(param(axis).keys, n)
    unsafe_grow_at!(parent(axis), n)
end
unsafe_grow_at!(axis::MutableAxis, n) = unsafe_grow_end!(axis, n)
function unsafe_grow_at!(axis::AbstractRange, n)
    if n === 1
        unsafe_grow_beg!(axis, n)
    else
        unsafe_grow_end!(axis, n)
    end
end

#= unsafe_shrink_end! =#
function StaticRanges.unsafe_shrink_end!(axis::AbstractAxis, n)
    unsafe_shrink_end!(parent(axis), n)
end
function StaticRanges.unsafe_shrink_end!(axis::KeyedAxis, n::Integer)
    unsafe_shrink_end!(keys(axis), n)
    unsafe_shrink_end!(parent(axis), n)
    return nothing
end

#= shrink_at! =#
unsafe_shrink_at!(axis::AbstractAxis, n) = unsafe_shrink_at!(parent(axis), n)
function unsafe_shrink_at!(axis::KeyedAxis, n)
    unsafe_shrink_at!(getfield(axis, :keys), n)
    unsafe_shrink_at!(parent(axis), n)
end
unsafe_shrink_at!(axis::MutableAxis, n) = unsafe_shrink_end!(axis, n)
function unsafe_shrink_at!(axis::AbstractRange, n)
    if n === 1
        unsafe_shrink_beg!(axis, n)
    else
        unsafe_shrink_end!(axis, n)
    end
end
unsafe_shrink_at!(axis::AbstractVector, n) = deleteat!(axis, n)

function StaticRanges.unsafe_shrink_end(axis::Axis, n)
    len = static_length(axis) - n
    start = static_first(axis)
    return @inbounds(axis[start:(start + len - one(start))])
end

function StaticRanges.unsafe_grow_end(axis::SimpleAxis, n::Integer)
    return SimpleAxis(static(1):(static_length(axis) + n))
end
StaticRanges.unsafe_grow_end(axis::Axis, n::Integer) = _grow_end(has_keys(axis), axis, n)
function _grow_end(::True, axis, n)
    k, p = strip_keys(axis)
    return _Axis(LazyVCat(keys(axis), static(1):n), unsafe_grow_end(p, n))
end
_grow_end(::False, axis, n) = _initialize(param(axis), unsafe_grow_end(parent(axis), n))

###
### reshape_axes
###
function reshape_axes(a::Tuple, s::Tuple)
    return (reshape_axis(first(a), first(s)), reshape_axes(tail(a), tail(s))...)
end
reshape_axes(::Tuple{}, s::Tuple) = (SimpleAxis(first(s)), reshape_axes((), tail(s))...)
reshape_axes(a::Tuple, ::Tuple{}) = ()
reshape_axes(::Tuple{}, ::Tuple{}) = ()

function reshape_axis(axis, n)
    len = static_length(axis)
    if len > n
        return unsafe_grow_end(axis, len - n)
    else
        start = static_first(axis)
        stop = start + n - one(start)
        return @inbounds(axis[start:stop])
    end
end

for (X,Y) in (
    (:(Base.Indices),:(Tuple{Vararg{<:AbstractAxis}})),
    (:(Tuple{Vararg{<:AbstractAxis}}),:(Base.Indices)),
    (:(Tuple{Vararg{<:AbstractAxis}}),:(Tuple{Vararg{<:AbstractAxis}})))
    @eval begin
        function Base.promote_shape(a::$X, b::$Y)
            if length(a) < length(b)
                return Base.promote_shape(b, a)
            end
            for i=1:length(b)
                if length(a[i]) != length(b[i])
                    throw(DimensionMismatch("dimensions must match: a has dims $a, b has dims $b, mismatch at $i"))
                end
            end
            for i=length(b)+1:length(a)
                if length(a[i]) != 1
                    throw(DimensionMismatch("dimensions must match: a has dims $a, must have singleton at dim $i"))
                end
            end
            return a
        end
    end
end

###
### empty
###
function Base.empty!(axis::AbstractAxis)
    StaticRanges.shrink_to!(axis, 0)
    return axis
end
Base.isempty(axis::AbstractAxis) = isempty(parent(axis))
Base.empty(::SimpleAxis) = SimpleAxis(static(1):static(0))
Base.empty(axis::KeyedAxis) = _Axis(_AxisKeys(empty(keys(axis))), empty(parent(axis)))
