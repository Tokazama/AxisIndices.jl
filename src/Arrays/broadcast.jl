
#=
    AxisArrayStyle{S}

This is a `BroadcastStyle` for AxisArray's It preserves the dimension
names. `S` should be the `BroadcastStyle` of the wrapped type.
=#
struct AxisArrayStyle{S <: BroadcastStyle} <: AbstractArrayStyle{Any} end
AxisArrayStyle(::S) where {S} = AxisArrayStyle{S}()
AxisArrayStyle(::S, ::Val{N}) where {S,N} = AxisArrayStyle(S(Val(N)))
AxisArrayStyle(::Val{N}) where N = AxisArrayStyle{DefaultArrayStyle{N}}()
function AxisArrayStyle(a::BroadcastStyle, b::BroadcastStyle)
    inner_style = BroadcastStyle(a, b)

    # if the inner_style is Unknown then so is the outer-style
    if inner_style isa Unknown
        return Unknown()
    else
        return AxisArrayStyle(inner_style)
    end
end

function Base.BroadcastStyle(::Type{T}) where {T<:AxisArray}
    return AxisArrayStyle{typeof(BroadcastStyle(parent_type(T)))}()
end

Base.BroadcastStyle(::AxisArrayStyle{A}, ::AxisArrayStyle{B}) where {A, B} = AxisArrayStyle(A(), B())
#Base.BroadcastStyle(::AxisArrayStyle{A}, b::B) where {A, B} = AxisArrayStyle(A(), b)
#Base.BroadcastStyle(a::A, ::AxisArrayStyle{B}) where {A, B} = AxisArrayStyle(a, B())
Base.BroadcastStyle(::AxisArrayStyle{A}, b::DefaultArrayStyle) where {A} = AxisArrayStyle(A(), b)
Base.BroadcastStyle(a::AbstractArrayStyle{M}, ::AxisArrayStyle{B}) where {B,M} = AxisArrayStyle(a, B())

function Base.BroadcastStyle(a::AxisArrayStyle{A}, b::NamedDims.NamedDimsStyle{B}) where {A,B}
    return NamedDims.NamedDimsStyle(a, B())
end
function Base.BroadcastStyle(a::NamedDims.NamedDimsStyle{M}, b::AxisArrayStyle{B}) where {B,M}
    return NamedDims.NamedDimsStyle(M(), b)
end


#=
    unwrap_broadcasted

Recursively unwraps `AbstractAxisArray`s and `AxisArrayStyle`s.
replacing the `AbstractAxisArray`s with the wrapped array,
and `AxisArrayStyle` with the wrapped `BroadcastStyle`.
=#
function unwrap_broadcasted(bc::Broadcasted{AxisArrayStyle{S}}) where S
    return Broadcasted{S}(bc.f, map(unwrap_broadcasted, bc.args))
end
unwrap_broadcasted(a::AbstractAxisArray) = parent(a)
unwrap_broadcasted(x) = x

get_first_axis_indices(bc::Broadcasted) = _get_first_axis_indices(bc.args)
_get_first_axis_indices(args::Tuple{Any,Vararg{Any}}) = _get_first_axis_indices(tail(args))
_get_first_axis_indices(args::Tuple{<:AbstractAxisArray,Vararg{Any}}) = first(args)
_get_first_axis_indices(args::Tuple{}) = nothing

# We need to implement copy because if the wrapper array type does not support setindex
# then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{AxisArrayStyle{S}}) where S
    return unsafe_reconstruct(
        get_first_axis_indices(bc),
        Broadcast.copy(unwrap_broadcasted(bc)),
        Broadcast.combine_axes(bc.args...)
    )
end

function Base.copyto!(
    dest::AbstractAxisArray,
    ds::Integer,
    src::AbstractAxisArray,
    ss::Integer,
    n::Integer
)
    return copyto!(
        parent(dest),
        to_index(eachindex(dest), ds),
        parent(src),
        to_index(eachindex(src), ss),
        n
    )
end
function Base.copyto!(
    dest::AbstractArray,
    ds::Integer,
    src::AbstractAxisArray,
    ss::Integer,
    n::Integer
)

    copyto!(dest, ds, parent(src), to_index(eachindex(src), ss), n)
end

function Base.copyto!(
    dest::AbstractAxisArray,
    ds::Integer,
    src::AbstractArray,
    ss::Integer,
    n::Integer
)

    return copyto!(parent(dest), to_index(eachindex(dest), ds), src, ss, n)
end

function Base.copyto!(dest::AbstractAxisArray, dstart::Integer, src::AbstractArray)
    return copyto!(parent(dest), to_index(eachindex(dest), dstart), src)
end

function Base.copyto!(dest::AbstractAxisArray, dstart::Integer, src::AbstractAxisArray)
    return copyto!(parent(dest), to_index(eachindex(dest), dstart), parent(src))
end

function Base.copyto!(dest::AbstractArray, dstart::Integer, src::AbstractAxisArray)
    return copyto!(dest, dstart, parent(src))
end

function Base.copyto!(dest::AbstractAxisArray, src::AbstractAxisArray)
    return copyto!(parent(dest), parent(src))
end

function Base.copyto!(dest::AbstractAxisArray, src::AbstractArray)
    return copyto!(parent(dest), src)
end

function Base.copyto!(dest::AbstractArray, src::AbstractAxisArray)
    return copyto!(dest, parent(src))
end

function Base.copyto!(dest::AbstractAxisMatrix, src::SparseArrays.AbstractSparseMatrix)
    return copyto!(parent(dest), src)
end

function Base.copyto!(dest::SparseArrays.AbstractSparseMatrix, src::AbstractAxisMatrix)
    return copyto!(dest, parent(src))
end

function Base.copyto!(dest::SparseVector, src::AbstractAxisVector{T}) where {T}
    return copyto!(dest, parent(src))
end

Base.copyto!(dest::PermutedDimsArray, src::AbstractAxisArray) = copyto!(dest, parent(src))

function Base.copyto!(dest::AbstractAxisMatrix, src::SparseArrays.AbstractSparseMatrixCSC)
    return copyto!(parent(dest), src)
end
