
"""
    PadStyle

Abstract type for padding styles.
"""
abstract type PadStyle end

function check_pad end

struct PaddedAxis{S,FP<:Integer,LP<:Integer,I,Inds} <: AbstractAxis{I,Inds}
    pad_style::S
    first_pad::FP
    last_pad::LP
    parent::Inds

    function PaddedAxis(
        style::S,
        first_pad::Integer,
        last_pad::Integer,
        inds::AbstractAxis
    ) where {S}

        check_pad(style, first_pad, last_pad, first(inds), last(inds))
        return new{S,typeof(first_pad),typeof(last_pad),eltype(inds),typeof(inds)}(
            style,
            first_pad,
            last_pad,
            inds
        )
    end

    function PaddedAxis(style::S, first_pad::Integer, last_pad::Integer, inds) where {S}
        return PaddedAxis(style, first_pad, last_pad, compose_axis(inds))
    end
end

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

pad_style(axis::PaddedAxis) = getfield(axis, :pad_style)

first_pad(axis::PaddedAxis) = getfield(axis, :first_pad)

last_pad(axis::PaddedAxis) = getfield(axis, :last_pad)


@inline function Base.length(axis::PaddedAxis)
    return _length_padded_axis(static_first(axis), static_last(axis))
end

_length_padded_axis(start::Integer, stop::Integer) = (stop - start) + one(start)
_length_padded_axis(::Nothing, ::Integer) = nothing
_length_padded_axis(::Integer, ::Nothing) = nothing
_length_padded_axis(::Nothing, ::Nothing) = nothing

"""
    FillPad{F}(fxn::F)

Index style that pads a set number of indices on each side of an axis.
`fxn`(eltype(A))` returns the padded value.

"""
struct FillPad{F} <: PadStyle
    fxn::F
end

const ZeroPad = FillPad(zero)

const OnePad = FillPad(oneunit)

(p::FillPad)(x) = p.fxn(eltype(x))

@inline function pad_index(s::FillPad, pstart, pstop, start, stop, i)
    if start > i
        return s
    elseif stop < i
        return s
    else
        return Int(i)
    end
end

"""
    SymmetricPad <: PadStyle

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
struct SymmetricPad <: PadStyle end

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

"""
    ReplicatePad

The border elements extend beyond the image boundaries.

```math
\\boxed{
\\begin{array}{l|c|r}
  a\\, a\\, a\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, f \\, f \\, f
\\end{array}
}
```
"""
struct ReplicatePad <: PadStyle end

function pad_index(::ReplicatePad, start, stop, i)
    if start > i
        return start
    elseif stop < i
        return stop
    else
        return Int(i)
    end
end

check_pad(::ReplicatePad, first_pad, last_pad, start, stop) = nothing

"""
    CircularPad

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
struct CircularPad <: PadStyle end

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

"""
    ReflectPad

The border elements reflect relative to the edge itself.

```math
\\boxed{
\\begin{array}{l|c|r}
  d\\, c\\, b\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, e \\, d \\, c
\\end{array}
}
```
"""
struct ReflectPad <: PadStyle end

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

for (f, P) in (
    (:zero_pad, ZeroPad),
    (:one_pad, OnePad),
    (:replicate_pad, ReplicatePad),
    (:symmetric_pad, SymmetricPad),
    (:reflect_pad, ReflectPad),
    (:circular_pad, CircularPad)
   )
    pad_doc = """
        $f(; first_pad=ArrayInterface.Zero(), last_pad=ArrayInterface.Zero())

    Create a function that produces a `PaddedAxis` when provided a set of indices.        
    Behavior in the padded region uses the [`$P`](@ref) pad style.
    """
    @eval begin
        @doc $pad_doc
        function $f(; first_pad=Zero(), last_pad=Zero())
            inds -> PaddedAxis($P(), first_pad, last_pad, inds)
        end
    end
end

@inline function _sub_offset(axis::PaddedAxis, i::Integer)
    p = parent(axis)
    return pad_index(pad_style(axis), static_first(p), static_last(p), i)
end


function print_axis(io::IO, axis::PaddedAxis)
    start = Int(first(axis))
    stop = Int(last(axis))
    if haskey(io, :compact)
        print(io, start:stop)
    else
        p = parent(axis)
        print(io, "PaddedAxis($(pad_style(axis)), ")
        fp = first_pad(axis)
        if fp != 0
            print(io, "($(start))[$(Int(first_pad(axis)))]")
        end
        print(io, "$(Int(first(p))):$(Int(last(p)))")
        lp = last_pad(axis)
        if lp != 0
            print(io, "[$(Int(last_pad(axis)))]($(stop)))")
        end
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

check_axis_length(ks::PaddedAxis, inds, ::AxisArrayChecks{T}) where {T >: CheckedAxisLengths} = nothing
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
