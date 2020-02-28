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

Recursively unwraps `AxisIndicesArray`s and `AxisIndicesArrayStyle`s.
replacing the `AxisIndicesArray`s with the wrapped array,
and `AxisIndicesArrayStyle` with the wrapped `BroadcastStyle`.
"""
function unwrap_broadcasted(bc::Broadcasted{AxisIndicesArrayStyle{S}}) where S
    return Broadcasted{S}(bc.f, map(unwrap_broadcasted, bc.args))
end
#unwrap_broadcasted(bc::Broadcasted{BroadcastIndexStyle{S}}) where S = Broadcasted{S}(bc.f, map(unwrap_broadcasted, bc.args))
unwrap_broadcasted(a::AxisIndicesArray) = parent(a)
#unwrap_broadcasted(a::AbstractIndex) = parent(a)
unwrap_broadcasted(x) = x

# We need to implement copy because if the wrapper array type does not support setindex
# then the `similar` based default method will not work
# TODO: need to make this flexible to other AxisIndicesArrays types
function Broadcast.copy(bc::Broadcasted{AxisIndicesArrayStyle{S}}) where S
    return AxisIndicesArray(Broadcast.copy(unwrap_broadcasted(bc)),
                     Broadcast.combine_axes(bc.args...))
end

function Base.copyto!(dest::AbstractArray, bc::Broadcasted{AxisIndicesArrayStyle{S}}) where S
    inner_bc = unwrap_broadcasted(bc)
    copyto!(dest, inner_bc)
    return AxisIndicesArray(dest)
end
# TODO make the above generic
