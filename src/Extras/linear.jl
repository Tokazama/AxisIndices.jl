
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
const MetaLinearAxes{N,M,Axs} = MetaArray{Int,N,M,LinearAxes{N,Axs}}

function MetaLinearAxes(args...; metadata=nothing, kwargs...)
    return MetaArray(LinearAxes(args...); metadata=metadata, kwargs...)
end


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

