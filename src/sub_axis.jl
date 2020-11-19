
struct SubAxis{G,I,Inds<:AbstractRange{I}} <: AbstractAxis{I,Inds}
    getindices::G
    parent::Inds
end

_getindices(axis::SubAxis) = getfield(axis, :getindices)
Base.first(::SubAxis) = One()
Base.last(axis::SubAxis) = static_length(_getindices(axis))
Base.eachindex(axis::SubAxis) = first(axis):last(axis)

@propagate_inbounds function Base.view(axis::AbstractAxis, arg::AbstractUnitRange{<:Integer})
    return SubAxis(to_index(axis, arg), axis)
end
@propagate_inbounds function Base.view(axis::AbstractAxis, arg::StepRange{<:Integer})
    return SubAxis(to_index(axis, arg), axis)
end
@propagate_inbounds function Base.view(axis::AbstractAxis, arg)
    return SubAxis(to_index(axis, arg), axis)
end

_sub_offset(axis::SubAxis, arg) = @inbounds(_getindices(axis)[arg])

