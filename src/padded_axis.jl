
# TODO doc AbstractPad
"""
    AbstractPad
"""
abstract type AbstractPad end

"""
    IndexFillPad{F}(fxn::F)

Index style that pads a set number of indices on each side of an axis.
`fxn`(eltype(A))` returns the padded value.

"""
struct IndexFillPad{F} <: AbstractPad
    fxn::F
end

const IndexZeroPad = IndexFillPad(zero)

const IndexOnePad = IndexFillPad(oneunit)

(p::IndexFillPad)(x) = p.fxn(eltype(x))

"""
    SymmetricPad <: AbstractPad

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
struct SymmetricPad <: AbstractPad end

to_first_pad(::SymmetricPad, inds, arg) = Int(2first(inds) - arg)
to_last_pad(::SymmetricPad, inds, arg) = Int(2last(inds) - arg)

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
struct ReplicatePad <: AbstractPad end

to_first_pad(::ReplicatePad, inds, arg) = Int(firstindex(inds))
to_last_pad(::ReplicatePad, inds, arg) = Int(lastindex(inds))

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
struct CircularPad <: AbstractPad end

to_first_pad(::CircularPad, inds, arg) = Int(last(inds) - (firstindex(inds) - (arg - 1)))
to_last_pad(::CircularPad, inds, arg) = Int(first(inds) + (lastindex(inds) - (arg - 1)))

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
struct ReflectPad <: AbstractPad end

to_first_pad(::ReflectPad, inds, arg) = Int(first(inds) + (last(inds) - (arg - 1)))
to_last_pad(::ReflectPad, inds, arg) = Int(last(inds) - (first(inds) - (arg - 1)))

# TODO PaddedAxis
struct PaddedAxis{P,FP,LP,I,Inds} <: AbstractAxis{I,Inds}
    pad::P
    first_pad::FP
    last_pad::LP
    parent::Inds
end

@inline function apply_offset(axis::PaddedAxis, i::Integer)
    pinds = parent(axis)
    if first(pinds) > i
        return to_first_pad(S, axis, i)
    elseif last(pinds) < i
        return to_last_pad(S, axis, i)
    else
        return Int(i)
    end
end

