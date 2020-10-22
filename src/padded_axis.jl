
"""
    PadStyle

Abstract type for padding styles.
"""
abstract type PadStyle end

# TODO PaddedAxis
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

_length_padded_axis(start::Integer, stop::Integer) = (stop - start) - one(start)
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

to_start_pad(s::FillPad, p, start, stop, i) = p
to_last_pad(s::FillPad, p, start, stop, i) = p

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

to_first_pad(::SymmetricPad, p, start, stop, i) = 2start - i
to_last_pad(::SymmetricPad, p, start, stop, i) = 2stop - i

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

to_first_pad(::ReplicatePad, p, start, stop, i) = start
to_last_pad(::ReplicatePad, p, start, stop, i) = stop

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

to_first_pad(::CircularPad, p, start, stop, i) = stop - (start - (i - 1))
to_last_pad(::CircularPad, p, start, stop, i) = start + (stop - (i - 1))

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

to_first_pad(::ReflectPad, p, start, stop, i) = start + (stop - (i - 1))
to_last_pad(::ReflectPad, p, start, stop, i) = stop - (start - (i - 1))

for (f, P) in (
    (:zero_pad, ZeroPad),
    (:one_pad, OnePad),
    (:replicate_pad, ReplicatePad),
    (:symmetric_pad, SymmetricPad),
    (:reflect_pad, ReflectPad),
    (:circular_pad, CircularPad)
   )
    @eval begin
        function $f(; first_pad=Zero(), last_pad=Zero())
            inds -> PaddedAxis($P(), first_pad, last_pad, inds)
        end
    end
end

@inline function apply_offset(axis::PaddedAxis{S}, i::Integer) where {S}
    pinds = parent(axis)
    if first(pinds) > i
        return to_first_pad(pad_style(axis), first_pad(axis), static_first(axis), static_last(axis), i)
    elseif last(pinds) < i
        return to_last_pad(pad_style(axis), last_pad(axis), static_first(axis), static_last(axis), i)
    else
        return Int(i)
    end
end

function print_axis(io::IO, axis::PaddedAxis)
    start = Int(first(axis))
    stop = Int(last(axis))
    if haskey(io, :compact)
        print(io, start:stop)
    else
        p = parent(axis)
        print(io, "PaddedAxis($(pad_style(axis)), ")
        print(io, "$(start)←$(Int(first_pad(axis)))|")
        print(io, "$(Int(first(p))):$(Int(last(p)))")
        print(io, "|$(Int(last_pad(axis)))→$(stop))")
    end
end
