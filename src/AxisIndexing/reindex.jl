
"""
    reindex(a::AbstractAxis, inds::AbstractVector{Integer}) -> AbstractAxis

Returns an `AbstractAxis` of the same type as `a` where the keys of the axis are
constructed by indexing into the keys of `a` with `inds` (`keys(a)[inds]`) and the
values have the same first element as `first(values(a))` but a length matching `inds`.

## Examples
Note how in all cases the keys may change but values are still 1-based
```jldoctest
julia> using AxisIndices

julia> x, y, z = Axis(2:11, 1:10), Axis(1:10), SimpleAxis(1:10);

julia> reindex(x, 2:5)
Axis(3:6 => 1:4)

julia> reindex(y, 2:5)
Axis(2:5 => Base.OneTo(4))

julia> reindex(z, 2:5)
SimpleAxis(1:4)
```
"""
@propagate_inbounds reindex(a::AbstractAxis, inds) = unsafe_reindex(a, to_index(a, inds))
@propagate_inbounds function reindex(axs::Tuple, inds::Tuple{Integer,Vararg{Any}})
    return reindex(tail(axs), tail(inds))
end
@propagate_inbounds function reindex(axs::Tuple, inds::Tuple{AbstractVector{<:Integer},Vararg{Any}})
    return (unsafe_reindex(first(axs), first(inds)), reindex(tail(axs), tail(inds))...)
end
reindex(axs::Tuple{}, inds::Tuple{}) = ()


"""
    unsafe_reindex(a::AbstractAxis, inds::AbstractVector) -> AbstractAxis

Similar to `reindex` this function returns an index of the same type as `a` but
doesn't check that `inds` is inbounds.

See also: [`reindex`](@ref)

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.unsafe_reindex(SimpleAxis(OneToMRange(10)), 1:5)
SimpleAxis(OneToMRange(5))

julia> AxisIndices.unsafe_reindex(SimpleAxis(OneToSRange(10)), 1:5)
SimpleAxis(OneToSRange(5))
```
"""
function unsafe_reindex(a::AbstractAxis, inds)
    return unsafe_reconstruct(a, @inbounds(keys(a)[inds]), _reindex(values(a), inds))
end
function unsafe_reindex(a::AbstractSimpleAxis, inds)
    return unsafe_reconstruct(a, _reindex(values(a), inds))
end

_reindex(a::OneTo{T}, inds) where {T} = OneTo{T}(length(inds))
_reindex(a::OneToMRange{T}, inds) where {T} = OneToMRange{T}(length(inds))
_reindex(a::OneToSRange{T}, inds) where {T} = OneToSRange{T}(length(inds))
_reindex(a::T, inds) where {T<:AbstractUnitRange} = T(first(a), first(a) + length(inds) - 1)

