
Base.allunique(a::AbstractAxis) = true

Base.in(x::Integer, a::AbstractAxis) = in(x, values(a))

Base.collect(a::AbstractAxis) = collect(values(a))

Base.eachindex(a::AbstractAxis) = values(a)

function reverse_keys(old_axis::AbstractAxis, new_index::AbstractUnitRange)
    return similar(old_axis, reverse(keys(old_axis)), new_index, false)
end

function reverse_keys(old_axis::AbstractSimpleAxis, new_index::AbstractUnitRange)
    return Axis(reverse(keys(old_axis)), new_index, false)
end

function Base.push!(A::AbstractAxisIndices{T,1}, items...) where {T}
    StaticRanges.grow_last!(axes(A, 1), length(items))
    push!(parent(A), items...)
    return A
end

function Base.pushfirst!(A::AbstractAxisIndices{T,1}, items...) where {T}
    StaticRanges.grow_first!(axes(A, 1), length(items))
    pushfirst!(parent(A), items...)
    return A
end

function Base.empty!(a::AbstractAxisIndices)
    for ax_i in axes(a)
        if !StaticRanges.can_set_length(ax_i)
            error("Cannot perform `empty!` on AbstractAxisIndices that has an axis with a fixed size.")
        end
    end

    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end

function Base.empty!(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs}
    empty!(keys(a))
    empty!(values(a))
    return a
end

function Base.empty!(a::AbstractSimpleAxis{V,Vs}) where {V,Vs}
    empty!(values(a))
    return a
end

Base.isempty(a::AbstractAxis) = isempty(values(a))

###
### resize
###
# Note that all `grow_*`/`shrink_*` functions ignore the possibility that `d` is
# negative. Although these are documented, they should probably be considered
# unsafe and only used internally.


# This file is for code that is only relevant to AbstractAxis 
# * TODO list for AbstractAxis
# - Is this necessary `Base.UnitRange{T}(a::AbstractAxis) where {T} = UnitRange{T}(values(a))`
# - Should AbstractAxes be a formal type?
# - is `nothing` what we want when there isn't a step in the keys
# - specialize `collect` on first type argument


#Base.axes(a::AbstractAxis) = values(a)


# This is required for performing `similar` on arrays
Base.to_shape(r::AbstractAxis) = length(r)


#Base.convert(::Type{T}, a::T) where {T<:AbstractAxis} = a
#Base.convert(::Type{T}, a) where {T<:AbstractAxis} = T(a)

###
### static traits
###
# for when we want the same underlying memory layout but reversed keys

# TODO should this be a formal abstract type?
const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}


# TODO this should all be derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

# FIXME
# When I use Val(N) on the tuple the it spits out many lines of extra code.
# But without it it loses inferrence
function Base.reinterpret(::Type{Tnew}, A::AbstractAxisIndices{Told,N}) where {Tnew,Told,N}
    p = reinterpret(Tnew, parent(A))
    axs = ntuple(N) do i
        StaticRanges.resize_last(axes(A, i), size(p, i))
    end
    return unsafe_reconstruct(A, p, axs)
end

function Base.resize!(x::AbstractAxisIndices{T,1}, n::Integer) where {T}
    resize!(parent(x), n)
    StaticRanges.resize_last!(axes(x, 1), n)
    return x
end

function Base.reverse(x::AbstractAxisIndices{T,1}) where {T}
    p = reverse(parent(x))
    return unsafe_reconstruct(x, p, (reverse_keys(axes(x, 1), axes(p, 1)),))
end

function Base.reverse(x::AbstractAxisIndices{T,N}; dims::Integer) where {T,N}
    p = reverse(parent(x), dims=dims)
    axs = ntuple(Val(N)) do i
        if i in dims
            reverse_keys(axes(x, i), axes(p, i))
        else
            similar_axis(axes(x, i), nothing, axes(p, i), false)
        end
    end
    return unsafe_reconstruct(x, p, axs)
end

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))


"""
    deleteat!(a::AbstractAxisIndicesVector, arg)

Remove the items corresponding to `A[arg]`, and return the modified `a`. Subsequent
items are shifted to fill the resulting gap. If the axis of `a` is an `AbstractSimpleAxis`
then it is shortened to match the length of `a`. If the 

  inds can be either an iterator or a collection of sorted and unique integer indices, or a boolean vector of the same length as a with true indicating entries to delete.

## Examples
```jldoctest
julia> using AxisIndices

julia> x = AxisIndicesArray([1, 2, 3, 4]);

julia> deleteat!(x, 3)
AxisIndicesArray{Int64,1,Array{Int64,1}...}
 • dim_1 - SimpleAxis(OneToMRange(3))

  1   1
  2   2
  3   4


julia> x = AxisIndicesArray([1, 2, 3, 4], ["a", "b", "c", "d"]);

julia> deleteat!(x, "c")
AxisIndicesArray{Int64,1,Array{Int64,1}...}
 • dim_1 - Axis(["a", "b", "d"] => OneToMRange(3))

  a   1
  b   2
  d   4


```
"""
function Base.deleteat!(A::AbstractAxisIndices{T,1,P,Tuple{Ax1}}, arg) where {T,P,Ax1<:AbstractSimpleAxis}
    inds = to_index(axes(A, 1), arg)
    StaticRanges.shrink_last!(axes(A, 1), length(inds))
    deleteat!(parent(A), inds)
    return A
end

function Base.deleteat!(A::AbstractAxisIndices{T,1,P,Tuple{Ax1}}, arg) where {T,P,Ax1<:AbstractAxis}
    inds = to_index(axes(A, 1), arg)
    deleteat!(axes_keys(A, 1), inds)
    StaticRanges.shrink_last!(indices(A, 1), length(inds))
    deleteat!(parent(A), inds)
    return A
end

