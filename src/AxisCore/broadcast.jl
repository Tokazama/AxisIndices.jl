
#=
    AxisIndicesArrayStyle{S}

This is a `BroadcastStyle` for AxisIndicesArray's It preserves the dimension
names. `S` should be the `BroadcastStyle` of the wrapped type.
=#
struct AxisIndicesArrayStyle{S <: BroadcastStyle} <: AbstractArrayStyle{Any} end
AxisIndicesArrayStyle(::S) where {S} = AxisIndicesArrayStyle{S}()
AxisIndicesArrayStyle(::S, ::Val{N}) where {S,N} = AxisIndicesArrayStyle(S(Val(N)))
AxisIndicesArrayStyle(::Val{N}) where N = AxisIndicesArrayStyle{DefaultArrayStyle{N}}()
function AxisIndicesArrayStyle(a::BroadcastStyle, b::BroadcastStyle)
    inner_style = BroadcastStyle(a, b)

    # if the inner_style is Unknown then so is the outer-style
    if inner_style isa Unknown
        return Unknown()
    else
        return AxisIndicesArrayStyle(inner_style)
    end
end

function Base.BroadcastStyle(::Type{T}) where {T<:AxisIndicesArray}
    return AxisIndicesArrayStyle{typeof(BroadcastStyle(parent_type(T)))}()
end

Base.BroadcastStyle(::AxisIndicesArrayStyle{A}, ::AxisIndicesArrayStyle{B}) where {A, B} = AxisIndicesArrayStyle(A(), B())
Base.BroadcastStyle(::AxisIndicesArrayStyle{A}, b::B) where {A, B} = AxisIndicesArrayStyle(A(), b)
Base.BroadcastStyle(a::A, ::AxisIndicesArrayStyle{B}) where {A, B} = AxisIndicesArrayStyle(a, B())
Base.BroadcastStyle(::AxisIndicesArrayStyle{A}, b::DefaultArrayStyle) where {A} = AxisIndicesArrayStyle(A(), b)
Base.BroadcastStyle(a::AbstractArrayStyle{M}, ::AxisIndicesArrayStyle{B}) where {B,M} = AxisIndicesArrayStyle(a, B())

#=
    unwrap_broadcasted

Recursively unwraps `AbstractAxisIndices`s and `AxisIndicesArrayStyle`s.
replacing the `AbstractAxisIndices`s with the wrapped array,
and `AxisIndicesArrayStyle` with the wrapped `BroadcastStyle`.
=#
function unwrap_broadcasted(bc::Broadcasted{AxisIndicesArrayStyle{S}}) where S
    return Broadcasted{S}(bc.f, map(unwrap_broadcasted, bc.args))
end
unwrap_broadcasted(a::AbstractAxisIndices) = parent(a)
unwrap_broadcasted(x) = x

get_first_axis_indices(bc::Broadcasted) = _get_first_axis_indices(bc.args)
_get_first_axis_indices(args::Tuple{Any,Vararg{Any}}) = _get_first_axis_indices(tail(args))
_get_first_axis_indices(args::Tuple{<:AbstractAxisIndices,Vararg{Any}}) = first(args)
_get_first_axis_indices(args::Tuple{}) = nothing

# We need to implement copy because if the wrapper array type does not support setindex
# then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{AxisIndicesArrayStyle{S}}) where S
    return unsafe_reconstruct(
        get_first_axis_indices(bc),
        Broadcast.copy(unwrap_broadcasted(bc)),
        Broadcast.combine_axes(bc.args...)
    )
end

#= TODO do we need this
function Base.copyto!(dest::AbstractArray, bc::Broadcasted{AxisIndicesArrayStyle{S}}) where S
    inner_bc = unwrap_broadcasted(bc)
    copyto!(dest, inner_bc)
    A = get_first_axis_indices(bc)
    return unsafe_reconstruct(A, dest, axes(A))
end
=#

_broadcast(axis, inds) = inds
_broadcast(axis, inds::AbstractUnitRange{<:Integer}) = assign_indices(axis, inds)

for (f, FT, arg) in ((:-, typeof(-), Number),
                     (:+, typeof(+), Real),
                     (:*, typeof(*), Real))
    @eval begin
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return _broadcast(r, (broadcast($f, x, values(r))))
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

function Base.copyto!(dest::AbstractAxisIndices, ds::Integer, src::AbstractAxisIndices, ss::Integer, n::Integer)
    copyto!(parent(dest), to_index(eachindex(dest), ds), src, to_index(eachindex(src), ss), n)
end
function Base.copyto!(dest::AbstractArray, ds::Integer, src::AbstractAxisIndices, ss::Integer, n::Integer)
    copyto!(dest, ds, parent(src), to_index(eachindex(src), ss), n)
end
function Base.copyto!(dest::AbstractAxisIndices, ds::Integer, src::AbstractArray, ss::Integer, n::Integer)
    copyto!(parent(dest), to_index(eachindex(dest), ds), src, ss, n)
end

function Base.copyto!(dest::AbstractAxisIndices, dstart::Integer, src::AbstractArray)
    copyto!(parent(dest), to_index(eachindex(dest), dstart), src)
end

function Base.copyto!(dest::AbstractAxisIndices, dstart::Integer, src::AbstractAxisIndices)
    copyto!(parent(dest), to_index(eachindex(dest), dstart), parent(src))
end

function Base.copyto!(dest::AbstractArray, dstart::Integer, src::AbstractAxisIndices)
    copyto!(dest, dstart, parent(src))
end

