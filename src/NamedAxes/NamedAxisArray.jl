
function StaticRanges.axes_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A}
    return StaticRanges.axes_type(A)
end

ArrayInterface.parent_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A} = A

"""
    NamedAxisArray(parent::AbstractArray; kwargs...) = NamedAxisArray(parent, kwargs)
    NamedAxisArray(parent::AbstractArray, axes::NamedTuple{L,AbstractAxes})

Type alias for `NamedDimsArray` whose parent array is a subtype of `AxisArray`.
An abbreviated alias and constructor for [`NamedAxisArray`](@ref). If key word
arguments are provided then each key word becomes the name of a dimension and its
assigned value is sent to the corresponding axis when constructing the underlying
`AxisArray`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = NamedAxisArray{(:x, :y, :z)}(reshape(1:24, 2, 3, 4), ["a", "b"], ["one", "two", "three"], 2:5)
2×3×4 NamedAxisArray{Int64,3}
 • x - ["a", "b"]
 • y - ["one", "two", "three"]
 • z - 2:5
[x, y, z[2]] =
      one   two   three
  a     1     3       5
  b     2     4       6

[x, y, z[3]] =
      one   two   three
  a     7     9      11
  b     8    10      12

[x, y, z[4]] =
      one   two   three
  a    13    15      17
  b    14    16      18

[x, y, z[5]] =
      one   two   three
  a    19    21      23
  b    20    22      24

julia> dimnames(A)
(:x, :y, :z)

julia> axes_keys(A)
(["a", "b"], ["one", "two", "three"], 2:5)

julia> B = A["a", :, :]
3×4 NamedAxisArray{Int64,2}
 • y - ["one", "two", "three"]
 • z - 2:5
          2    3    4    5
    one   1    7   13   19
    two   3    9   15   21
  three   5   11   17   23

julia> C = B["one",:]
4-element NamedAxisArray{Int64,1}
 • z - 2:5

  2    1
  3    7
  4   13
  5   19

```
"""
const NamedAxisArray{L,T,N,P,AI} = NamedDimsArray{L,T,N,AxisArray{T,N,P,AI}}

NamedAxisArray{L}(x::AxisArray) where {L} = NamedDimsArray{L}(x)

function NamedAxisArray{L}(x::AbstractArray, axs::Tuple) where {L}
    return NamedAxisArray{L}(AxisArray(x, axs))
end

function NamedAxisArray{L}(x::AbstractArray, args::AbstractVector...) where {L}
    return NamedAxisArray{L}(x, args)
end

function NamedAxisArray(x::AbstractArray, axs::NamedTuple{L}) where {L}
    return NamedAxisArray{L}(x, values(axs))
end

function NamedAxisArray{L,T,N}(init::ArrayInitializer, axs::Tuple) where {L,T,N}
    return NamedAxisArray{L}(AxisArray{T,N}(init, axs))
end

function NamedAxisArray{L,T,N}(init::ArrayInitializer, args::AbstractVector...) where {L,T,N}
    return NamedAxisArray{L,T,N}(init, args)
end

function NamedAxisArray{L,T}(init::ArrayInitializer, axs::Tuple) where {L,T}
    return NamedAxisArray{L}(AxisArray{T}(init, axs))
end

function NamedAxisArray{L,T}(init::ArrayInitializer, args::AbstractVector...) where {L,T}
    return NamedAxisArray{L,T}(init, args)
end

NamedAxisArray(x::AbstractArray; kwargs...) = NamedAxisArray(x, kwargs.data)

for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds function Base.$f(A::NamedAxisArray; named_inds...)
            inds = NamedDims.order_named_inds(A; named_inds...)
            return Base.$f(A, inds...)
        end

        @propagate_inbounds function Base.$f(a::NamedAxisArray, raw_inds...)
            inds = Interface.to_indices(parent(a), raw_inds)  # checkbounds happens within to_indices
            data = @inbounds(Base.$f(parent(a), inds...))
            data isa AbstractArray || return data # Case of scalar output
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            if L === ()
                # Cases that merge dimensions down to vector like `mat[mat .> 0]`,
                # and also zero-dimensional `view(mat, 1,1)`
                return data
            else
                return NamedDimsArray{L}(data)
            end
        end
    end
end

Base.getindex(A::NamedAxisArray, ::Ellipsis) = A

const ReinterpretNamedAxisArray{T,N,S,L,A<:NamedAxisArray{L,S,N}} = ReinterpretArray{T,N,S,A}

function Base.axes(A::ReinterpretNamedAxisArray{T,N,S}) where {T,N,S}
    paxs = axes(parent(A))
    axis_1 = first(paxs)
    len = div(length(axis_1) * sizeof(S), sizeof(T))
    return tuple(StaticRanges.resize_last(axis_1, len), tail(paxs)...)
end

