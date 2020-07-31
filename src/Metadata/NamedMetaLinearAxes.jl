"""
    NamedMetaLinearAxes

Conveniently construct a `LinearAxes` that has metadata and each dimension has a name.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = NamedMetaLinearAxes{(:dimx,:dimy)}(([:a, :b], ["one", "two"]); metadata="some metadata")
2×2 NamedMetaLinearAxes{Int64,2}
 • dimx - [:a, :b]
 • dimy - ["one", "two"]
metadata: String
 • some metadata
      one   two
  a     1     3
  b     2     4

julia> x == NamedMetaLinearAxes((dimx = [:a, :b], dimy = ["one", "two"]); metadata="some metadata")
true

```
"""
const NamedMetaLinearAxes{L,N,M,Axs} = NamedDimsArray{L,Int,N,MetaLinearAxes{N,M,Axs}}

function NamedMetaLinearAxes{L}(axs::Tuple; metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaLinearAxes(axs; metadata=metadata, kwargs...))
end

function NamedMetaLinearAxes{L}(axs::Union{AbstractVector,Integer}...;  metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaLinearAxes(axs, metadata=metadata, kwargs...))
end

function NamedMetaLinearAxes(axs::NamedTuple{L};  metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaLinearAxes(values(axs);  metadata=metadata, kwargs...))
end

function NamedMetaLinearAxes(A::AbstractArray;  metadata=metadata(A), kwargs...)
    return NamedMetaLinearAxes(named_axes(A);  metadata=metadata, kwargs...)
end

