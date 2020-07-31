
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

