

function (p::AxisParameter)(collection::AbstractArray)
    if known_step(collection) === 1
        return initialize(p, collection)
    else
        return AxisArray(collection, ntuple(_ -> p, Val(ndims(collection))))
    end
end

struct AxisStruct{T} <: AxisParameter

    global _AxisStruct(::Type{T}) where {T} = new{T}()

    function AxisStruct{T}() where {T}
        if typeof(T) <: DataType
            return new{T}()
        else
            throw(ArgumentError("Type must be have all field fully paramterized, got $T"))
        end
    end
end


# TODO document AxisKeys
struct AxisKeys{K} <: AxisParameter
    keys::K

    global _AxisKeys(k::K) where {K} = new{K}(k)
    function AxisKeys(k::K) where {K}
        check_unique_keys(k)
        return new{K}(k)
    end
end

"""
    offset([collection,] x)


## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), offset(2))
3-element AxisArray(::Vector{Float64}
  • axes:
     1 = 3:5
)
     1
  3  1.0
  4  1.0
  5  1.0

```
"""
struct AxisOffset{O} <: AxisParameter
    offset::O

    AxisOffset{Int}(x) = new{Int}(x)
    AxisOffset{StaticInt{O}}(x) where {O} = new{StaticInt{O}}(x)
    AxisOffset(x::Int) = new{Int}(x)
    AxisOffset(x::StaticInt) = new{typeof(x)}(x)
end

"""
    center(collection, origin)
    center(collection, origin)

Shortcut for creating [`CenteredAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), center(0))
3-element AxisArray(::Vector{Float64}
  • axes:
     1 = -1:1
)
      1
  -1  1.0
  0   1.0
  1   1.0

```
"""
struct AxisOrigin{O} <: AxisParameter
    origin::O

    AxisOrigin{Int}(x) = new{Int}(x)
    AxisOrigin{StaticInt{O}}(x) where {O} = new{StaticInt{O}}(x)
    AxisOrigin(x::Int) = new{Int}(x)
    AxisOrigin(x::StaticInt) = new{typeof(x)}(x)
end
(p::AxisOrigin)(x::AbstractUnitRange{T}) where {T} = _CenteredAxis(p.origin, x)


(p::PadsParameter)(x::AbstractUnitRange{T}) where {T} = PaddedAxis(p, compose_axis(x))


"""
    zero_pad(; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements return `zero(eltype(A))`.
"""
struct ZeroPads{F,L} <: FillPads{F,L}
    pads::Pads{F,L}
end
pad_with(::AbstractArray{T}, ::ZeroPads) where {T} = zero(T)

"""
    one_pad(; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements return `oneunit(eltype(A))`, where `A` is the parent array being padded.
"""
struct OnePads{F,L} <: FillPads{F,L}
    pads::Pads{F,L}
end
pad_with(::AbstractArray{T}, ::OnePads) where {T} = oneunit(T)

"""
    nothing_pad(; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements return `nothing`, where `A` is the parent array being padded.
"""
struct NothingPads{F,L} <: FillPads{F,L}
    pads::Pads{F,L}
end
pad_with(::AbstractArray, ::NothingPads) = nothing

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
struct SymmetricPads{F,L} <: PadsParameter{F,L}
    pads::Pads{F,L}
end

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
struct ReplicatePads{F,L} <: PadsParameter{F,L}
    pads::Pads{F,L}
end

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
struct CircularPads{F,L} <: PadsParameter{F,L}
    pads::Pads{F,L}
end

"""
    reflect_pad(; first_pad=0, last_pad=0, sym_pad=nothing)

The border elements reflect relative to the edge itself.

```math
\\boxed{
\\begin{array}{l|c|r}
  d\\, c\\, b\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, e \\, d \\, c
\\end{array}
}
```
"""
struct ReflectPads{F,L} <: PadsParameter{F,L}
    pads::Pads{F,L}
end

