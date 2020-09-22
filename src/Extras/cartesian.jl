
"""
    NamedCartesianAxes

Conveniently construct a `CartesianAxes` where each dimension has a name.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = NamedCartesianAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]))
2×2 NamedCartesianAxes{CartesianIndex{2},2}
 • dimx - [:a, :b]
 • dimy - ["one", "two"]
                       one                    two
  a   CartesianIndex(1, 1)   CartesianIndex(1, 2)
  b   CartesianIndex(2, 1)   CartesianIndex(2, 2)

julia> x == NamedCartesianAxes((dimx = [:a, :b], dimy = ["one", "two"]))
true

```
"""
const NamedCartesianAxes{L,N,Axs} = NamedDimsArray{L,CartesianIndex{N},N,CartesianAxes{N,Axs}}

NamedCartesianAxes{L}(axs::Tuple) where {L} = NamedDimsArray{L}(CartesianAxes(axs))

function NamedCartesianAxes{L}(axs::Union{AbstractVector,Integer}...) where {L}
    return NamedDimsArray{L}(CartesianAxes(axs))
end

NamedCartesianAxes(axs::NamedTuple{L}) where {L} = NamedDimsArray{L}(CartesianAxes(values(axs)))

NamedCartesianAxes(A::AbstractArray) = NamedCartesianAxes(named_axes(A))

"""
    MetaCartesianAxes

Conveniently construct a `CartesianAxes` that has metadata.

## Examples

```jldoctest
julia> using AxisIndices

julia> MetaCartesianAxes(([:a, :b], ["one", "two"]); metadata="some metadata")
2×2 MetaCartesianAxes{CartesianIndex{2},2}
 • dim_1 - [:a, :b]
 • dim_2 - ["one", "two"]
metadata: String
 • some metadata
                       one                    two
  a   CartesianIndex(1, 1)   CartesianIndex(1, 2)
  b   CartesianIndex(2, 1)   CartesianIndex(2, 2)

```
"""
const MetaCartesianAxes{N,M,Axs} = MetaArray{CartesianIndex{N},N,M,CartesianAxes{N,Axs}}

function MetaCartesianAxes(args...; metadata=nothing, kwargs...)
    return MetaArray(CartesianAxes(args...), _construct_meta(metadata; kwargs...))
end

"""
    NamedMetaCartesianAxes

Conveniently construct a `CartesianAxes` that has metadata and each dimension has a name.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = NamedMetaCartesianAxes{(:dimx,:dimy)}(([:a, :b], ["one", "two"]); metadata="some metadata")
2×2 NamedMetaCartesianAxes{CartesianIndex{2},2}
 • dimx - [:a, :b]
 • dimy - ["one", "two"]
metadata: String
 • some metadata
                       one                    two
  a   CartesianIndex(1, 1)   CartesianIndex(1, 2)
  b   CartesianIndex(2, 1)   CartesianIndex(2, 2)

julia> x == NamedMetaCartesianAxes((dimx = [:a, :b], dimy = ["one", "two"]); metadata="some metadata")
true

```
"""
const NamedMetaCartesianAxes{L,N,M,Axs} = NamedDimsArray{L,CartesianIndex{N},N,MetaCartesianAxes{N,M,Axs}}

function NamedMetaCartesianAxes{L}(axs::Tuple; metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaCartesianAxes(axs; metadata=metadata, kwargs...))
end

function NamedMetaCartesianAxes{L}(axs::Union{AbstractVector,Integer}...;  metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaCartesianAxes(axs, metadata=metadata, kwargs...))
end

function NamedMetaCartesianAxes(axs::NamedTuple{L};  metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaCartesianAxes(values(axs);  metadata=metadata, kwargs...))
end

function NamedMetaCartesianAxes(A::AbstractArray;  metadata=metadata(A), kwargs...)
    return NamedMetaCartesianAxes(named_axes(A);  metadata=metadata, kwargs...)
end

