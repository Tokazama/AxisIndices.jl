
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
const MetaCartesianAxes{N,M,Axs} = MetadataArray{CartesianIndex{N},N,M,CartesianAxes{N,Axs}}

function MetaCartesianAxes(args...; metadata=nothing, kwargs...)
    return MetadataArray(CartesianAxes(args...), _construct_meta(metadata; kwargs...))
end

