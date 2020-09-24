
"""
    IndexPaddedStyle

Index style that pads a set number of indices on each side of an axis.
"""
abstract type IndexPaddedStyle <: IndexOffsetStyle end

"""
    IndexFillPad{F}(fxn::F)

Index style that pads a set number of indices on each side of an axis.
`fxn`(eltype(A))` returns the padded value.

"""
struct IndexFillPad{F} <: IndexPaddedStyle
    fxn::F
end

const IndexZeroPad = IndexFillPad(zero)

const IndexOnePad = IndexFillPad(oneunit)

(p::IndexFillPad)(x) = p.fxn(eltype(x))

"""
    SymmetricPad <: IndexPaddedStyle

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
struct SymmetricPad <: IndexPaddedStyle end

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
struct ReplicatePad <: IndexPaddedStyle end

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
struct CircularPad <: IndexPaddedStyle end

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
struct ReflectPad <: IndexPaddedStyle end

to_first_pad(::ReflectPad, inds, arg) = Int(first(inds) + (last(inds) - (arg - 1)))
to_last_pad(::ReflectPad, inds, arg) = Int(last(inds) - (first(inds) - (arg - 1)))

@propagate_inbounds function to_index_element(::IndexPaddedStyle, axis, arg::Function)
    idx = findfirst(arg, axis)
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, first(getargs(drop_marker(arg)))))
    end
    return @inbounds(to_index(axis, idx))
end

@propagate_inbounds function to_index(S::IndexPaddedStyle, axis, arg::AbstractArray{I}) where {I<:Integer}
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return as_keys(arg)
end

@propagate_inbounds function to_index(S::IndexPaddedStyle, axis, arg::Integer)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end

    pinds = parentindices(axis)
    if first(pinds) > arg
        return to_first_pad(S, axis, arg)
    elseif last(pinds) < arg
        return to_last_pad(S, axis, arg)
    else
        return Int(arg)
    end
end


is_element(::IndexStyle, ::Type{<:IndexPaddedStyle}) = true

struct UnsafePadElement <: UnsafeIndex end
const unsafe_pad_element = UnsafePadElement()

struct UnsafePadCollection <: UnsafeIndex end
const unsafe_pad_collection = UnsafePadCollection()

UnsafeIndex(x::UnsafePadElement, y::UnsafeIndex) = x
UnsafeIndex(x::UnsafeIndex, y::UnsafePadElement) = y
UnsafeIndex(x::UnsafePadElement, y::UnsafePadElement) = x
UnsafeIndex(x::UnsafePadCollection, y::UnsafePadCollection) = x
UnsafeIndex(x::UnsafeIndex, y::UnsafePadCollection) = y
UnsafeIndex(x::UnsafePadCollection, y::UnsafeIndex) = x
UnsafeIndex(x::UnsafePadElement, y::UnsafePadCollection) = y
UnsafeIndex(x::UnsafePadCollection, y::UnsafePadElement) = x
UnsafeIndex(x::UnsafePadElement, y::UnsafeElement) = x
UnsafeIndex(x::UnsafeElement, y::UnsafePadElement) = y
UnsafeIndex(x::UnsafePadCollection, y::UnsafeElement) = x
UnsafeIndex(x::UnsafeElement, y::UnsafePadCollection) = y
UnsafeIndex(x::UnsafeCollection, y::UnsafeCollection) = x


# TODO PaddedAxis
struct PaddedAxis{P,FP,LP,I,Inds} <: AbstractOffsetAxis{I}
    pad::P
    first_pad::FP
    last_pad::LP
    parent_indices::Inds
end
