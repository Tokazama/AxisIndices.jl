
"""
    AxisIndicesArrayStyle{S}

This is a `BroadcastStyle` for AxisIndicesArray's It preserves the dimension
names. `S` should be the `BroadcastStyle` of the wrapped type.
"""
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

"""
    unwrap_broadcasted

Recursively unwraps `AbstractAxisIndices`s and `AxisIndicesArrayStyle`s.
replacing the `AbstractAxisIndices`s with the wrapped array,
and `AxisIndicesArrayStyle` with the wrapped `BroadcastStyle`.
"""
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
    return _similar_type(get_first_axis_indices(bc),
                         Broadcast.copy(unwrap_broadcasted(bc)),
                         Broadcast.combine_axes(bc.args...))
end

function Base.copyto!(dest::AbstractArray, bc::Broadcasted{AxisIndicesArrayStyle{S}}) where S
    inner_bc = unwrap_broadcasted(bc)
    copyto!(dest, inner_bc)
    _similar_type(get_first_axis_indices(bc), dest)
end

# catch cases where get_first_axis_indices couldn't find a AbstractAxisIndices
function _similar_type(A::AbstractAxisIndices, p, axs=axes(A))
    return similar_type(A, typeof(p), typeof(axs))(p, axs)
end
_similar_type(::Nothing, p, axs=nothing) = AxisIndicesArray(p)

function Base.broadcasted(::DefaultArrayStyle{1}, ::typeof(-), x::Number, r::AbstractAxis)
    ks = keys(r)
    vs = x .- values(r)
    return similar_type(r, typeof(ks), typeof(vs))(ks, vs)
end
function Base.broadcasted(::DefaultArrayStyle{1}, ::typeof(-), r::AbstractAxis, x::Number)
    ks = keys(r)
    vs = values(r) .- x
    return similar_type(r, typeof(ks), typeof(vs))(ks, vs)
end
function Base.broadcasted(::DefaultArrayStyle{1}, ::typeof(+), x::Real, r::AbstractAxis)
    ks = keys(r)
    vs = x .+ values(r)
    return similar_type(r, typeof(ks), typeof(vs))(ks, vs)
end
function Base.broadcasted(::DefaultArrayStyle{1}, ::typeof(+), r::AbstractAxis, x::Real)
    ks = keys(r)
    vs = values(r) .+ x
    return similar_type(r, typeof(ks), typeof(vs))(ks, vs)
end
function Base.broadcasted(::DefaultArrayStyle{1}, ::typeof(*), x::Real, r::AbstractAxis)
    ks = keys(r)
    vs = x .* values(r)
    return similar_type(r, typeof(ks), typeof(vs))(ks, vs)
end
function Base.broadcasted(::DefaultArrayStyle{1}, ::typeof(*), r::AbstractAxis, x::Real)
    ks = keys(r)
    vs = values(r) .* x
    return similar_type(r, typeof(ks), typeof(vs))(ks, vs)
end
keys_or_nothing(x::AbstractAxis) = keys(x)
keys_or_nothing(x) = nothing

"""
    combine_axis(x, y) -> collection

Returns the combination of axes `x` and `y`. This method relies on [`combine_values`](@ref)
and [`combine_keys`](@ref) to form a new axis.

## Examples
```jldoctest
julia> using AxisIndices

julia> a, b = 1:10, Base.OneTo(10);

julia> combine_axis(a, SimpleAxis(b))
SimpleAxis(1:10)

julia> combine_axis(a, b)
1:10

julia> combine_axis(b, a)
1:10

julia> c = combine_axis(a, SimpleAxis(b))
SimpleAxis(1:10)

julia> d = combine_axis(SimpleAxis(b), a)
SimpleAxis(1:10)

julia> e = combine_axis(c, d)
SimpleAxis(1:10)

julia> f = combine_axis(Axis(a), a)
Axis(1:10 => 1:10)

julia> g = combine_axis(a, Axis(b))
Axis(Base.OneTo(10) => 1:10)

julia> combine_axis(f, g)
Axis(1:10 => 1:10)

```
"""
combine_axis(x::X, y::Y) where {X, Y} = combine_axis(promote_rule(X, Y), x, y)
function combine_axis(::Type{T}, x, y) where {T<:SimpleAxis}
    return SimpleAxis(combine_values(values(x), values(y)))
end
function combine_axis(::Type{T}, x, y) where {T<:AbstractAxis}
    ks = combine_keys(keys_or_nothing(x), keys_or_nothing(y))
    vs = combine_values(values(x), values(y))
    return similar_type(T, typeof(ks), typeof(vs))(ks, vs)
end
combine_axis(::Type{T}, x, y) where {T} = combine_values(x, y)

"""
    combine_values(x, y)

Returns the combination of the values of `x` and `y`, creating a new index. New
subtypes of `AbstractAxis` may implement a unique `combine_values` method if 
needed. Default behavior is to use the return of `promote_rule(x, y)` for the
type of the combined values.
"""
combine_values(x, y) = combine_values(promote_values_rule(x, y), values(x), values(y))
combine_values(::Type{T}, x, y) where {T<:StaticRanges.OneToUnion} = T(length(x))
combine_values(::Type{T}, x, y) where {T<:AbstractUnitRange} = T(first(x), last(x))

"""
    combine_keys(x, y)

Returns the combination of `x` and `y`, assuming they are keys to another structure.
Default behavior is to use `promote_rule` for converting `x`. This method should be
overloaded to accomodate combining keys where a traditional promotion isn't appropriate.

## Examples

The default behavior is to promote the first argument.
```jldoctest combine_keys_examples
julia> using AxisIndices

julia> combine_keys(Base.OneTo(10), Base.OneTo(10))
Base.OneTo(10)

julia> combine_keys(1:10, Base.OneTo(10))
1:10
```

Using `combine_keys` allows combining axes that aren't appropriate for conventional
promotion.
```jldoctest combine_keys_examples
julia> combine_keys(1:2, string.(1:2))
2-element Array{String,1}:
 "1"
 "2"

julia> combine_keys(1:2, Symbol.(1:2))
2-element Array{Symbol,1}:
 Symbol("1")
 Symbol("2")

```
"""
combine_keys(::Nothing, y) = y
combine_keys(x, ::Nothing) = x
# TODO gracefully error
combine_keys(x::X, y::Y) where {X,Y} = combine_keys(promote_keys_rule(X, Y), x, y)
combine_keys(::Type{T}, x, y) where {T} = convert(T, x)
function combine_keys(::Type{Union{}}, x::X, y::Y) where {X,Y}
    error("No method available for combining keys of type $X and $Y.")
end

# TODO make sure these are sensible defaults
combine_keys(x::AbstractVector{<:AbstractString}, y::AbstractVector{<:Number}) = x
combine_keys(x::AbstractVector{<:Number}, y::AbstractVector{<:AbstractString}) = string.(x)

combine_keys(x::AbstractVector{Symbol}, y::AbstractVector{<:Number}) = x
combine_keys(x::AbstractVector{<:Number}, y::AbstractVector{Symbol}) = Symbol.(x)

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
# _bcs1 handles the logic for a single dimension
_bcs1(a::Integer, b::Integer) = a == 1 ? b : (b == 1 ? a : (a == b ? a : throw(DimensionMismatch("arrays could not be broadcast to a common size; got a dimension with lengths $a and $b"))))
_bcs1(a::Integer, b) = a == 1 ? b : (first(b) == 1 && last(b) == a ? b : throw(DimensionMismatch("arrays could not be broadcast to a common size; got a dimension with lengths $a and $(length(b))")))
_bcs1(a, b::Integer) = _bcs1(b, a)
function _bcs1(a, b)
    if _bcsm(b, a)
        return combine_axis(b, a)
    else
        if _bcsm(a, b)
            return combine_axis(a, b)
        else
            throw(DimensionMismatch("arrays could not be broadcast to a common size; got a dimension with lengths $(length(a)) and $(length(b))"))
        end
    end
end
# _bcsm tests whether the second index is consistent with the first
_bcsm(a, b) = a == b || length(b) == 1
_bcsm(a, b::Number) = b == 1
_bcsm(a::Number, b::Number) = a == b || b == 1

