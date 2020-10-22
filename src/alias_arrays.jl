
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

function CartesianAxes(axs::Tuple{Vararg{Any,N}}) where {N}
    c = AxisArrayChecks{CheckedAxisLengths}()
    return CartesianIndices(map(axis -> compose_axis(axis, _inds(axis), c), axs))
end

# compose_axis(axis, checks) doesn't assume one based indexing in case a range is
# passed without it, but we want to assume that's what we have here unless an axplicit
# instance of AbstractAxis is passed
_inds(axis::Integer) = One():axis
_inds(axis::AbstractVector) = One():static_length(axis)
_inds(axis::AbstractAxis) = parent(axis)


Base.axes(A::CartesianAxes) = getfield(A, :indices)

#=

@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:NTuple{N,<:AbstractAxis}},
    inds::Vararg{Int,N}
) where {N}

    return CartesianIndex(to_indices(A, Tuple(inds)))
end

@inline function Base.getindex(iter::CartesianIndices{N,<:NTuple{N,Base.OneTo}}, I::Vararg{Int, N}) where {N}
    @boundscheck checkbounds(iter, I...)
    CartesianIndex(I)
end
@propagate_inbounds function Base.getindex(
    A::CartesianIndices{N,<:Tuple{Vararg{<:AbstractAxis,N}}},
    inds::Vararg{Int,N}
) where {N}

    return unsafe_getindex(IndexCartesian(), A, to_indices(A, inds))
end
=#


@propagate_inbounds function Base.getindex(A::CartesianIndices{N,R}, args::Vararg{Int, N}) where {N,R<:Tuple{Vararg{<:AbstractAxis,N}}}
    return ArrayInterface.getindex(A, args...)
end

@propagate_inbounds function Base.getindex(A::CartesianIndices{N,R}, args...) where {N,R<:Tuple{Vararg{<:AbstractAxis,N}}}
    return ArrayInterface.getindex(A, args...)
end
Base.getindex(A::CartesianIndices{N,R}, ::Ellipsis) where {N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = A
#=
@inline function Base.getindex(iter::CartesianIndices{N,R}, I::Vararg{Int, N}) where {N,R}
    @boundscheck checkbounds(iter, I...)
    CartesianIndex(I .- first.(Base.axes1.(iter.indices)) .+ first.(iter.indices))
end

CartesianIndices{N,NTuple{N,<:AbstractAxis}} where N

 (getindex(iter::CartesianIndices{N,R}, args...) where {N, R<:Tuple{Vararg{AbstractAxis,N}}} in AxisIndices at /Users/zchristensen/projects/AxisIndices.jl/src/alias_arrays.jl:355,
  getindex(iter::CartesianIndices{N,var"#s826"} where var"#s826"<:Tuple{Vararg{Base.OneTo,N}}, I::Vararg{Int64,N}) where N in Base.IteratorsMD at multidimensional.jl:321)
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

function LinearAxes(axs::Tuple{Vararg{<:Any,N}}) where {N}
    c = AxisArrayChecks{CheckedAxisLengths}()
    return LinearIndices(map(axis -> compose_axis(axis, _inds(axis), c), axs))
end

Base.axes(A::LinearAxes) = getfield(A, :indices)

@boundscheck function Base.getindex(iter::LinearAxes, i::Int)
    @boundscheck if !in(i, eachindex(iter))
        throw(BoundsError(iter, i))
    end
    return i
end

@propagate_inbounds function Base.getindex(A::LinearAxes, inds...)
    return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end

@propagate_inbounds function Base.getindex(A::LinearAxes, i::AbstractRange{I}) where {I<:Integer}
    return getindex(eachindex(A), i)
end

Base.getindex(A::LinearAxes, ::Ellipsis) = A

Base.eachindex(A::LinearAxes) = SimpleAxis(StaticInt(1):static_length(A))
#=
 (getindex(A::LinearIndices{N,R} where R<:Tuple{Vararg{AbstractAxis,N}} where N, inds...) in AxisIndices at /Users/zchristensen/projects/AxisIndices.jl/src/alias_arrays.jl:410,
 getindex(iter::LinearIndices, i::AbstractRange{var"#s91"} where var"#s91"<:Integer) in Base at indices.jl:475)
=#

