
###
### unsafe_getindex
###
function unsafe_getindex(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(getindex(parent(A), inds...))
end

@inline function unsafe_getindex(A, args::Tuple, inds::Tuple)
    p = @inbounds(getindex(parent(A), inds...))
    if any(typeof.(inds) .<: AbstractArray{<:Bool})
        return p
    elseif (p isa AbstractVector) && is_dynamic(p)
        return unsafe_reconstruct(A, p, to_axes(A, args, inds, (as_dynamic(axes(p, 1)),), false))
    else
        return unsafe_reconstruct(A, p, to_axes(A, args, inds, axes(p), false))
    end
end

function unsafe_view(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.view(parent(A), inds...))
end

function unsafe_view(A, args::Tuple, inds::Tuple)
    p = view(parent(A), inds...)
    if any(typeof.(inds) .<: AbstractArray{<:Bool})
        return p
    end
    return unsafe_reconstruct(A, p, to_axes(A, args, inds, axes(p), false))
end

function unsafe_dotview(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.dotview(parent(A), inds...))
end

function unsafe_dotview(A, args::Tuple, inds::Tuple)
    p = Base.dotview(parent(A), inds...)
    if any(typeof.(inds) .<: AbstractArray{<:Bool})
        return p
    end
    return unsafe_reconstruct(A, p, to_axes(A, args, inds, axes(p), false))
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

function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractAxis)
    return Interface.check_index(axis, eachindex(arg))
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
