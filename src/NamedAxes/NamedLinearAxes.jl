
"""
    NamedLinearAxes

Provides `LinearAxes` where each dimension has a name.

## Examples

```jldoctest
julia> using AxisIndices

julia> x = NamedLinearAxes{(:dimx,:dimy)}(([:a, :b], ["one", "two"]))
2×2 NamedLinearAxes{Int64,2}
 • dimx - [:a, :b]
 • dimy - ["one", "two"]
      one   two
  a     1     3
  b     2     4

julia> x == NamedLinearAxes((dimx = [:a, :b], dimy = ["one", "two"]))
true

```
"""
const NamedLinearAxes{L,N,Axs} = NamedDimsArray{L,Int,N,LinearAxes{N,Axs}}

NamedLinearAxes{L}(axs::Tuple) where {L} = NamedDimsArray{L}(LinearAxes(axs))

function NamedLinearAxes{L}(axs::Union{AbstractVector,Integer}...) where {L}
    return NamedDimsArray{L}(LinearAxes(axs))
end

NamedLinearAxes(axs::NamedTuple{L}) where {L} = NamedDimsArray{L}(LinearAxes(values(axs)))

NamedLinearAxes(A::AbstractArray) = NamedLinearAxes(named_axes(A))

