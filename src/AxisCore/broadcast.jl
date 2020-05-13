
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
#Base.BroadcastStyle(::AxisIndicesArrayStyle{A}, b::B) where {A, B} = AxisIndicesArrayStyle(A(), b)
#Base.BroadcastStyle(a::A, ::AxisIndicesArrayStyle{B}) where {A, B} = AxisIndicesArrayStyle(a, B())
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
