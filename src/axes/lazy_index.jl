
# TODO document
struct SubAxis{A<:AbstractAxis,I<:AbstractVector} <: AbstractVector{Int}
    axis::A
    indices::I
end

@propagate_inbounds function Base.getindex(axis::SubAxis, i::Integer)
    ii = axis.indices[i]
    @inbounds(to_index())
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

###
### LazyIndex - different from SubAxis b/c getindex(::LazyIndex, i) calls to_index
###

# TODO document
struct LazyIndex{A<:AbstractUnitRange,I<:AbstractVector} <: AbstractArray{Int,1}
    axis::A
    indices::I
end
ArrayInterface.known_length(::Type{LazyIndex{A,I}}) where {A,I} = known_length(I)
ArrayInterface.known_size(::Type{T}) where {T<:LazyIndex} = (known_length(T),)
Base.size(x::LazyIndex) = size(x.indices)
Base.axes(x::LazyIndex) = axes(x.indices)
Base.axes(x::LazyIndex, i::Integer) = axes(x.indices, i)

@propagate_inbounds function Base.getindex(axis::LazyIndex, i::Integer)
    ii = axis.indices[i]
    return @inbounds(to_index(axis.axis, ii))
end

