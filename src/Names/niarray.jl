
function StaticRanges.axes_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A}
    return StaticRanges.axes_type(A)
end

StaticRanges.parent_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A} = A

named_axes(nda::NamedDimsArray{L}) where {L} = NamedTuple{L}(axes(nda))
function named_axes(a::AbstractArray{T,N}) where {T,N}
    return NamedTuple{default_names(Val(N))}(axes(a))
end

@generated function default_names(::Val{N}) where {N}
    :($(ntuple(i -> Symbol(:dim_, i), N)))
end

"""
    NamedIndicesArray

Type alias for `NamedDimsArray` whose parent array is a subtype of `AxisIndicesArray`.
"""
const NamedIndicesArray{L,T,N,P,AI} = NamedDimsArray{L,T,N,AxisIndicesArray{T,N,P,AI}}

"""
    NIArray((parent::AbstractArray; kwargs...) = NIArray(parent, kwargs)
    NIArray((parent::AbstractArray, axes::NamedTuple{L,AbstractAxes}))

An abbreviated alias and constructor for [`NamedIndicesArray`](@ref). If key word
arguments are provided then each key word becomes the name of a dimension and its
assigned value is sent to the corresponding axis when constructing the underlying
`AxisIndicesArray`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = NIArray(reshape(1:24, 2, 3, 4), x=["a", "b"], y =["one", "two", "three"], z=2:5)
NamedDimsArray{Int64,3,Base.ReshapedArray{Int64,3,UnitRange{Int64},Tuple{}}...}
 • x - Axis(["a", "b"] => Base.OneTo(2))
 • y - Axis(["one", "two", "three"] => Base.OneTo(3))
 • z - Axis(2:5 => Base.OneTo(4))
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
NamedDimsArray{Int64,2,Array{Int64,2}...}
 • y - Axis(["one", "two", "three"] => OneToMRange(3))
 • z - Axis(2:5 => Base.OneTo(4))
          2    3    4    5
    one   1    7   13   19
    two   3    9   15   21
  three   5   11   17   23


julia> C = B["one",:]
NamedDimsArray{Int64,1,Array{Int64,1}...}
 • z - Axis(2:5 => Base.OneTo(4))

  2    1
  3    7
  4   13
  5   19


```
"""
const NIArray{L,T,N,P,AI} = NamedIndicesArray{L,T,N,P,AI}

NIArray(x::AbstractArray; kwargs...) = NIArray(x, kwargs.data)
function NIArray(x::AbstractArray, axs::NamedTuple{L}) where {L}
    return NamedDimsArray{L}(AxisIndicesArray(x, values(axs)))
end

#=
for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::NIArray, inds...)
            return $_f(a, to_indices(parent(a), inds))
        end

        @propagate_inbounds function Base.$f(a::NIArray, inds::Vararg{<:Integer})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function Base.$f(a::NIArray, inds::CartesianIndex)
            return Base.$f(parent(a), inds)
        end

        @propagate_inbounds function $_f(a::NIArray, inds::Tuple{Vararg{<:Integer}})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::NIArray{T,N}, inds::Tuple{Vararg{<:Any,M}}) where {T,N,M}
            data = Base.$f(parent(a), inds...)
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            return NamedDims.NamedDimsArray{L}(data)
        end
    end
end

@propagate_inbounds function Base.getindex(A::NIArray{T,N}, args::Integer...) where {T,N,M}
    inds = to_indices(A, args)
    p = AxisIndexing.unsafe_getindex(parent(A), args, inds)
    L = NamedDims.remaining_dimnames_from_indexing(dimnames(A), inds)
    return NamedDims.NamedDimsArray{L}(p)
end
=#

Base.show(io::IO, x::NIArray; kwargs...) = show(io, MIME"text/plain"(), x, kwargs...)
function Base.show(io::IO, m::MIME"text/plain", x::NIArray{L,T,N}; kwargs...) where {L,T,N}
    println(io, "$(typeof(x).name.name){$T,$N,$(parent_type(parent(x)))...}")
    return show_array(io, x, axes(x), dimnames(x); kwargs...)
end

