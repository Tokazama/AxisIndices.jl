
###
### unsafe_getindex
###
function unsafe_getindex(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(getindex(parent(A), inds...))
end

function unsafe_getindex(A, args::Tuple, inds::Tuple)
    p = @inbounds(getindex(parent(A), inds...))
    return unsafe_reconstruct(A, p, to_axes(A, args, inds, axes(p), false, Staticness(p)))
end

function unsafe_view(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.view(parent(A), inds...))
end

function unsafe_view(A, args::Tuple, inds::Tuple)
    p = view(parent(A), inds...)
    return unsafe_reconstruct(A, p, to_axes(A, args, inds, axes(p), false, Staticness(p)))
end

function unsafe_dotview(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.dotview(parent(A), inds...))
end

function unsafe_dotview(A, args::Tuple, inds::Tuple)
    p = Base.dotview(parent(A), inds...)
    return unsafe_reconstruct(A, p, to_axes(A, args, inds, axes(p), false, Staticness(p)))
end

###
### checkbounds
###
Base.checkbounds(x::AbstractAxis, i) = checkbounds(Bool, x, i)
#=
@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg::CartesianIndex)
    return checkindex(Bool, axis, arg)
end
function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, i::AbstractArray{<:CartesianIndex})
    return Base.checkbounds_indices(Bool, (axis,), (i,))
end
=#
@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg::Base.LogicalIndex)
    return checkindex(Bool, axis, arg)
end
@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg)
    return checkindex(Bool, axis, arg)
end
@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg::AbstractVector)
    return checkindex(Bool, axis, arg)
end

@inline function Base.checkbounds(
    ::Type{Bool},
    axis::AbstractAxis,
    i::Union{CartesianIndex, AbstractArray{<:CartesianIndex}}
)

    return Base.checkbounds_indices(Bool, (axis,), (i,))
end

#@inline function Base.checkbounds(::Type{Bool}, axis::AbstractAxis, arg::Base.LogicalIndex)
#    return checkindex(Bool, axis, arg)
#end
@inline function Base.checkbounds(::Type{Bool}, A::AbstractAxis, I::Base.LogicalIndex{<:Any,<:AbstractArray{Bool,1}})
    return eachindex(eachindex) == eachindex(IndexLinear(), I.mask)
end

for T in (AbstractVector{Bool},
          AbstractArray,
          AbstractRange,
          Base.Slice,
          AbstractUnitRange,
          Integer,
          CartesianIndex{1},
          Base.LogicalIndex,
          AbstractArray{Bool},
          Colon,
          Real,
          Any)
    @eval begin
        function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::$T)
            return Interface.check_index(axis, arg)
        end
    end
end

function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::StaticIndexing)
    return Interface.check_index(axis, arg.ind)
end

###
### getindex
###

#=
We have to define several index types (AbstractUnitRange, Integer, and i...) in
order to avoid ambiguities.
=#
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{<:Integer})
    inds = to_index(axis, arg)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, to_keys(axis, arg, inds), inds)
    end
end

@propagate_inbounds Base.getindex(axis::AbstractAxis, i::Integer) = to_index(axis, i)

@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{<:Integer})
    return to_index(axis, arg)
end

@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    return _axis_getindex(axis, arg, to_index(axis, arg))
end

Base.getindex(axis::AbstractAxis, ::Ellipsis) = axis

@inline function _axis_getindex(axis::AbstractAxis, arg, inds::AbstractUnitRange)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, to_keys(axis, arg, inds), inds)
    end
end
_axis_getindex(axis::AbstractAxis, arg, index) = index

Base.getindex(axis::AbstractAxis, arg::Colon) = copy(axis)

"""
    CartesianAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> cartaxes = CartesianAxes((Axis(2.0:5.0), Axis(1:4)));

julia> cartinds = CartesianIndices((1:4, 1:4));

julia> cartaxes[2, 2]
CartesianIndex(2, 2)

julia> cartinds[2, 2]
CartesianIndex(2, 2)
```
"""
const CartesianAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = CartesianIndices{N,R}

_cartesian_axes(axs::Tuple{}) = ()
_cartesian_axes(axs::Tuple) = (to_axis(first(axs)), _cartesian_axes(tail(axs))...)

CartesianAxes(axs::Tuple{Vararg{Any,N}}) where {N} = CartesianIndices(_cartesian_axes(axs))

Base.axes(A::CartesianAxes) = getfield(A, :indices)

@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}},
    inds::Vararg{Int}
) where {N}

    return CartesianIndex(map(getindex, axes(A), inds))
end

Base.getindex(A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}}, ::Ellipsis) where {N} = A

@propagate_inbounds function Base.getindex(
    A::CartesianAxes{N,<:NTuple{N,<:AbstractAxis}},
    inds...
) where {N}

    return Base._getindex(IndexStyle(A), A, Interface.to_indices(A, Tuple(inds))...)
end

@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}},
    inds::Vararg{Int,N}
) where {N}

    return CartesianIndex(Interface.to_indices(A, Tuple(inds)))
end

#=
@inline function Base.getindex(iter::CartesianIndices{N,R}, I::Vararg{Int, N}) where {N,R}
    @boundscheck checkbounds(iter, I...)
    CartesianIndex(I .- first.(Base.axes1.(iter.indices)) .+ first.(iter.indices))
end

CartesianIndices{N,NTuple{N,<:AbstractAxis}} where N
=#



"""
    LinearAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> linaxes = LinearAxes((Axis(2.0:5.0), Axis(1:4)));

julia> lininds = LinearIndices((1:4, 1:4));

julia> linaxes[2, 2]
6

julia> lininds[2, 2]
6
```
"""
const LinearAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = LinearIndices{N,R}

LinearAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = LinearIndices(map(to_axis, ks))

Base.axes(A::LinearAxes) = getfield(A, :indices)

@boundscheck function Base.getindex(iter::LinearAxes, i::Int)
    @boundscheck if !in(i, eachindex(iter))
        throw(BoundsError(iter, i))
    end
    return i
end

@propagate_inbounds function Base.getindex(A::LinearAxes, inds...)
    return Base._getindex(IndexStyle(A), A, Interface.to_indices(A, Tuple(inds))...)
end

Base.getindex(A::LinearAxes, ::Ellipsis) = A

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

###
### Generate show methods
###

PrettyArrays.@assign_show CartesianAxes

PrettyArrays.@assign_show LinearAxes

PrettyArrays.@assign_show MetaCartesianAxes

PrettyArrays.@assign_show MetaLinearAxes

PrettyArrays.@assign_show NamedCartesianAxes

PrettyArrays.@assign_show NamedLinearAxes

PrettyArrays.@assign_show NamedMetaCartesianAxes

PrettyArrays.@assign_show NamedMetaLinearAxes

