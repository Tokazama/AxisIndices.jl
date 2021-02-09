
Base.getindex(axis::AbstractAxis, ::Colon) = copy(axis)
Base.getindex(axis::AbstractAxis, ::Ellipsis) = copy(axis)
@propagate_inbounds Base.getindex(axis::AbstractAxis, arg::Integer) = to_index(axis, arg)
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{I}) where {I<:Integer}
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{I}) where {I<:Integer}
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractArray{I}) where {I<:Integer}
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end

ArrayInterface.unsafe_get_element(axis::AbstractAxis, inds) = eltype(axis)(first(inds))

@inline function ArrayInterface.unsafe_get_collection(axis::AbstractAxis, inds::Tuple)
    return _unsafe_get_axis_collection(axis, first(inds))
end
_unsafe_get_axis_collection(axis, i::Integer) = Int(i)
@inline function _unsafe_get_axis_collection(axis, inds)
    if known_step(inds) === one(eltype(inds))
        return index_axis_to_axis(axis, inds)
    else
        return __unsafe_get_axis_collection(index_axis_to_array(axis, inds), inds)
    end
end
@inline function __unsafe_get_axis_collection(axis, inds::AbstractRange)
    T = eltype(axis)
    if eltype(inds) <: T
        return initialize_axis_array(inds, (axis,))
    else
        return __unsafe_get_axis_collection(axis, AbstractRange{T}(inds))
    end
end
@inline function __unsafe_get_axis_collection(axis, inds)
    T = eltype(axis)
    if eltype(inds) <: T
        return initialize_axis_array(inds, (axis,))
    else
        # FIXME doesn't this create stack overflow?
        return __unsafe_get_axis_collection(axis, AbstractArray{T}(inds))
    end
end

#= 
    index_axis_to_array(axis, inds)

An axis may have other axis types nested within it so we need to propagate the indexing,
but we can usually just use unsafe_reconstruct.
=#
@inline function index_axis_to_axis(axis::SimpleAxis, inds)
    return SimpleAxis(static_first(inds):static_last(inds))
end
@inline function index_axis_to_axis(axis, inds)
    return unsafe_reconstruct(axis, index_axis_to_axis(parent(axis), _sub_offset(axis, inds)))
end
@inline function index_axis_to_axis(axis::IdentityAxis, inds)
    return IdentityAxis(inds, index_axis_to_axis(parent(axis),  _sub_offset(axis, inds)))
end

# TODO this might be worth making part of official API if a better name and more thought out
# documentation/implementation accompanies it b/c eventually all axis types have to deal
# with non unit range indexing.
#= 
    index_axis_to_array(axis, inds)

An axis cannot be preserved if the elements with any collection that doesn't have a step of 1.
=#
index_axis_to_array(axis::SimpleAxis, inds) = SimpleAxis(eachindex(inds))
function index_axis_to_array(axis::Axis, inds)
    if allunique(inds)  # propagate keys corresponds to inds
        return initialize_axis(@inbounds(keys(axis)[inds]), index_axis_to_array(parent(axis), inds))
    else  # b/c not all indices are unique it will result in non-unique keys so drop keys
        return index_axis_to_array(parent(axis), inds)
    end
end
function index_axis_to_array(axis, inds)
    return unsafe_reconstruct(axis, index_axis_to_array(parent(axis), _sub_offset(axis, inds)))
end

