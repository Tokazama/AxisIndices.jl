
"""
    MetaLinearAxes

Conveniently construct a `LinearAxes` that has metadata.

## Examples

```jldoctest
julia> using AxisIndices

julia> MetaLinearAxes(([:a, :b], ["one", "two"]); metadata="some metadata")
2×2 MetaLinearAxes{Int64,2}
 • dim_1 - [:a, :b]
 • dim_2 - ["one", "two"]
metadata: String
 • some metadata
      one   two
  a     1     3
  b     2     4

```
"""
const MetaLinearAxes{N,M,Axs} = MetadataArray{Int,N,M,LinearAxes{N,Axs}}

function MetaLinearAxes(args...; metadata=nothing, kwargs...)
    return MetadataArray(LinearAxes(args...), _construct_meta(metadata; kwargs...))
end

