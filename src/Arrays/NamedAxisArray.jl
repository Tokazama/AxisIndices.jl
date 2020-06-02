
function StaticRanges.axes_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A}
    return StaticRanges.axes_type(A)
end

StaticRanges.parent_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A} = A

Interface.metadata(A::NamedDimsArray) = metadata(parent(A))
Interface.metadata_type(::Type{A}) where {A<:NamedDimsArray} = metadata_type(parent_type(A))



const NamedAxisArray{L,T,N,P,AI} = NamedDimsArray{L,T,N,AxisArray{T,N,P,AI}}

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

julia> A = NamedAxisArray(reshape(1:24, 2, 3, 4), x=["a", "b"], y =["one", "two", "three"], z=2:5)
2×3×4 NamedDimsArray{Int64,3}
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
3×4 NamedDimsArray{Int64,2}
 • y - ["one", "two", "three"]
 • z - 2:5
          2    3    4    5
    one   1    7   13   19
    two   3    9   15   21
  three   5   11   17   23

julia> C = B["one",:]
4-element NamedDimsArray{Int64,1}
 • z - 2:5

  2    1
  3    7
  4   13
  5   19

```
"""
const NamedAxisArray{L,T,N,P,AI} = NamedAxisArray{L,T,N,P,AI}

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

NamedAxisArray(x::AbstractArray; kwargs...) = NamedAxisArray(x, kwargs.data)

#=
for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::NamedAxisArray, inds...)
            return $_f(a, to_indices(parent(a), inds))
        end

        @propagate_inbounds function Base.$f(a::NamedAxisArray, inds::Vararg{<:Integer})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function Base.$f(a::NamedAxisArray, inds::CartesianIndex)
            return Base.$f(parent(a), inds)
        end

        @propagate_inbounds function $_f(a::NamedAxisArray, inds::Tuple{Vararg{<:Integer}})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::NamedAxisArray{T,N}, inds::Tuple{Vararg{<:Any,M}}) where {T,N,M}
            data = Base.$f(parent(a), inds...)
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            return NamedDims.NamedDimsArray{L}(data)
        end
    end
end

@propagate_inbounds function Base.getindex(A::NamedAxisArray{T,N}, args::Integer...) where {T,N,M}
    inds = to_indices(A, args)
    p = AxisIndexing.unsafe_getindex(parent(A), args, inds)
    L = NamedDims.remaining_dimnames_from_indexing(dimnames(A), inds)
    return NamedDims.NamedDimsArray{L}(p)
end
=#

Base.show(io::IO, x::NamedAxisArray; kwargs...) = show(io, MIME"text/plain"(), x, kwargs...)
function Base.show(io::IO, m::MIME"text/plain", x::NamedAxisArray{L,T,N}; kwargs...) where {L,T,N}
    PrettyArrays.print_array_summary(io, x)
    return show_array(io, x; kwargs...)
end

