
"""
    PaddedInitializer

Abstract type for padding styles.
"""
abstract type PaddedInitializer <: AxisInitializer end

check_pad(::PaddedInitializer, ::Any, ::Any, ::Any, ::Any) = nothing

struct PaddedAxis{P,FP<:Integer,LP<:Integer,I,Inds} <: AbstractAxis{I,Inds}
    pad::P
    first_pad::FP
    last_pad::LP
    parent::Inds

    function PaddedAxis(
        p::P,
        first_pad::Integer,
        last_pad::Integer,
        inds::AbstractAxis
    ) where {P}

        check_pad(p, first_pad, last_pad, first(inds), last(inds))
        return new{P,typeof(first_pad),typeof(last_pad),eltype(inds),typeof(inds)}(
            p,
            first_pad,
            last_pad,
            inds
        )
    end

    function PaddedAxis(p, first_pad::Integer, last_pad::Integer, inds)
        return PaddedAxis(p, first_pad, last_pad, compose_axis(inds))
    end
end

@inline Base.axes1(axis::PaddedAxis) = OffsetAxis(static_first(axis):static_last(axis))

Base.first(axis::PaddedAxis) = first(parent(axis)) - first_pad(axis)
Base.last(axis::PaddedAxis) = last(parent(axis)) + last_pad(axis)

function ArrayInterface.known_first(::Type{T}) where {F,T<:PaddedAxis{<:Any,StaticInt{F}}}
    if known_first(parent_type(T)) === nothing
        return nothing
    else
        return known_first(parent_type(T)) - F
    end
end
ArrayInterface.known_first(::Type{T}) where {T<:PaddedAxis{<:Any,<:Any}} = nothing

function ArrayInterface.known_last(::Type{T}) where {L,T<:PaddedAxis{<:Any,<:Any,StaticInt{L}}}
    if known_last(parent_type(T)) === nothing
        return nothing
    else
        return known_last(parent_type(T)) + L
    end
end
ArrayInterface.known_last(::Type{T}) where {T<:PaddedAxis{<:Any,<:Any,<:Any}} = nothing

function ArrayInterface.known_length(::Type{T}) where {T<:PaddedAxis}
    return _length_padded_axis(known_first(T), known_last(T))
end

pad(axis::PaddedAxis) = getfield(axis, :pad)

first_pad(axis::PaddedAxis) = getfield(axis, :first_pad)

last_pad(axis::PaddedAxis) = getfield(axis, :last_pad)

@inline function Base.length(axis::PaddedAxis)
    return _length_padded_axis(static_first(axis), static_last(axis))
end

_length_padded_axis(start::Integer, stop::Integer) = (stop - start) + one(start)
_length_padded_axis(::Nothing, ::Integer) = nothing
_length_padded_axis(::Integer, ::Nothing) = nothing
_length_padded_axis(::Nothing, ::Nothing) = nothing

#=
    FillPad{F}(fxn::F)

Index style that pads a set number of indices on each side of an axis.
`fxn`(eltype(A))` returns the padded value.

=#
abstract type FillPad <: PaddedInitializer end

"""
    zero_pad(x; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements return `zero(eltype(A))`, where `A` is the parent array being padded.
"""
struct ZeroPad <: FillPad end
const zero_pad = ZeroPad()
pad_call_string(::ZeroPad) = "zero_pad"

"""
    one_pad(x; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements return `oneunit(eltype(A))`, where `A` is the parent array being padded.
"""
struct OnePad <: FillPad end
const one_pad = OnePad()
pad_call_string(::OnePad) = "one_pad"

@inline function pad_index(p::FillPad, start, stop, i)
    if start > i
        return p
    elseif stop < i
        return p
    else
        return Int(i)
    end
end

"""
    symmetric_pad(x; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements reflect relative to a position between elements. That is, the
border pixel is omitted when mirroring.

```math
\\boxed{
\\begin{array}{l|c|r}
  e\\, d\\, c\\, b  &  a \\, b \\, c \\, d \\, e \\, f & e \\, d \\, c \\, b
\\end{array}
}
```
"""
struct SymmetricPad <: PaddedInitializer end
pad_call_string(::Symmetric) = "symmetric_pad"
const symmetric_pad = SymmetricPad()
axis_method(p::SymmetricPad) = (pads, axis) -> PaddedAxis(p, pads, axis)

function pad_index(::SymmetricPad, start, stop, i)
    if start > i
        return 2start - i
    elseif stop < i
        return 2stop - i
    else
        return Int(i)
    end
end

function check_pad(::SymmetricPad, first_pad, last_pad, start, stop)
    len = stop - start
    if first_pad > len
        throw(ArgumentError("cannot have pad that is larger than length of parent indices +1 for SymmetricPad, " *
            "first pad is $first_pad and indices are of length $len"))
    elseif last_pad > len
        throw(ArgumentError("cannot have pad that is larger than length of parent indices +1 for SymmetricPad, " *
            "first pad is $last_pad and indices are of length $len"))
    else
        return nothing
    end
end

struct ReplicatePad <: PaddedInitializer end
pad_call_string(::ReplicatePad) = "replicate_pad"

"""
    replicate_pad(x; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements extend beyond the image boundaries.

```math
\\boxed{
\\begin{array}{l|c|r}
  a\\, a\\, a\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, f \\, f \\, f
\\end{array}
}
```
"""
const replicate_pad = ReplicatePad()

function pad_index(::ReplicatePad, start, stop, i)
    if start > i
        return start
    elseif stop < i
        return stop
    else
        return Int(i)
    end
end

struct CircularPad <: PaddedInitializer end
pad_call_string(::CircularPad) = "circular_pad"

"""
    circular_pad(x; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements wrap around. For instance, indexing beyond the left border
returns values starting from the right border.

```math
\\boxed{
\\begin{array}{l|c|r}
  c\\, d\\, e\\, f  &  a \\, b \\, c \\, d \\, e \\, f & a \\, b \\, c \\, d
\\end{array}
}
```
"""
const circular_pad = CircularPad()

function pad_index(::CircularPad, start, stop, i)
    if start > i
        return stop - start + i + one(start)
    elseif stop < i
        return start + i - stop - one(stop)
    else
        return Int(i)
    end
end

function check_pad(::CircularPad, first_pad, last_pad, start, stop)
    len = stop - start + 1
    if first_pad > len
        throw(ArgumentError("cannot have pad of size $first_pad and indices of length $len for CircularPad"))
    elseif last_pad > len
        throw(ArgumentError("cannot have pad of size $last_pad and indices of length $len for CircularPad"))
    else
        return nothing
    end
end

struct ReflectPad <: PaddedInitializer end
pad_call_string(::ReflectPad) = "reflect_pad"

"""
    reflect_pad(x; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements reflect relative to the edge itself.

```math
\\boxed{
\\begin{array}{l|c|r}
  d\\, c\\, b\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, e \\, d \\, c
\\end{array}
}
```
"""
const reflect_pad = ReflectPad()


function pad_index(::ReflectPad, start, stop, i)
    if start > i
        return 2start - i - one(start)
    elseif stop < i
        return 2stop - i + one(stop)
    else
        return Int(i)
    end
end

function check_pad(::ReflectPad, first_pad, last_pad, start, stop)
    len = stop - start + 1
    if first_pad > len
        throw(ArgumentError("cannot have pad of size $first_pad and indices of length $len for ReflectPad"))
    elseif last_pad > len 
        throw(ArgumentError("cannot have pad of size $last_pad and indices of length $len for ReflectPad"))
    else
        return nothing
    end
end

function (p::PaddedInitializer)(; first_pad=Zero(), last_pad=Zero(), sym_pad=nothing)
    return x -> p(x; first_pad=first_pad, last_pad=last_pad, sym_pad=sym_pad)
end
function (p::PaddedInitializer)(x::AbstractArray; first_pad=Zero(), last_pad=Zero(), sym_pad=nothing)
    if known_step(x) === 1
        if sym_pad === nothing
            return PaddedAxis(p, first_pad, last_pad, x)
        else
            return PaddedAxis(p, sym_pad, sym_pad, x)
        end
    else
        if sym_pad === nothing
            return _pad_init_to_array(x, p, first_pad, last_pad)
        else
            return _pad_init_to_array(x, p, sym_pad)
        end
    end
end

@inline function _pad_init_to_array(x, p, fp::Integer, lp::Integer)
    axs = map(axis -> PaddedAxis(p, fp, lp, axis), axes(x), sp)
    return AxisArray{eltype(x),ndims(x),typeof(x),typeof(axs)}(x, axs; checks=NoChecks)
end
@inline function _pad_init_to_array(x, p, fp::Tuple, lp::Tuple)
    axs = map((axis, f, l) -> PaddedAxis(p, f, l, axis), axes(x), fp, lp)
    return AxisArray{eltype(x),ndims(x),typeof(x),typeof(axs)}(x, axs; checks=NoChecks)
end
@inline function _pad_init_to_array(x, p, sp::Integer)
    axs = map(axis -> PaddedAxis(p, sp, sp, axis), axes(x))
    return AxisArray{eltype(x),ndims(x),typeof(x),typeof(axs)}(x, axs; checks=NoChecks)
end
@inline function _pad_init_to_array(x, p, sp::Tuple)
    axs = map((axis, sp_i) -> PaddedAxis(p, sp_i, sp_i, axis), axes(x), sp)
    return AxisArray{eltype(x),ndims(x),typeof(x),typeof(axs)}(x, axs; checks=NoChecks)
end

@inline function _sub_offset(axis::PaddedAxis, i::Integer)
    p = parent(axis)
    return pad_index(pad(axis), static_first(p), static_last(p), i)
end

function print_axis(io::IO, axis::PaddedAxis)
    print(io, pad_call_string(pad(axis)))
    print(io, "(")
    print(io, parent(axis))
    if first_pad(axis) === last_pad(axis)
        print(io, "; sym_pad=")
        print(io, first_pad(axis))
        print(io, ")")
    else
        print(io, "; first_pad=")
        print(io, first_pad(axis))
        print(io, ", last_pad=")
        print(io, last_pad(axis))
        print(io, ")")
    end
end

@inline function _check_index_real(axis::PaddedAxis, arg)
    if first(axis) > arg
        return false
    elseif last(axis) < arg
        return false
    else
        return true
    end
end
_check_index_range(axis::PaddedAxis, arg) = checkindex(Bool, eachindex(axis), arg)

check_axis_length(::PaddedAxis, inds, ::AxisArrayChecks{T}) where {T >: CheckedAxisLengths} = nothing
function check_axis_length(ks::PaddedAxis, inds, ::AxisArrayChecks{T}) where {T}
    if length(parent(ks)) != length(inds)
        throw(DimensionMismatch(
            "keys and indices must have same length, got length(keys) = $(length(ks))" *
            " and length(indices) = $(length(inds)).")
        )
    end
    return nothing
end

is_dense_wrapper(::Type{T}) where {T<:PaddedAxis} = false

function ArrayInterface.unsafe_reconstruct(axis::PaddedAxis, data; kwargs...)
    return OffsetAxis(-first_pad(axis), data)
end

@inline function _unsafe_get_element(A, inds::Tuple{Vararg{Union{Integer,P}}}) where {P<:OnePad}
    return oneunit(eltype(A))
end

@inline function _unsafe_get_element(A, inds::Tuple{Vararg{Union{Integer,P}}}) where {P<:ZeroPad}
    return zero(eltype(A))
end
