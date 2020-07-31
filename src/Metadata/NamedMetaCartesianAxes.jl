
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
