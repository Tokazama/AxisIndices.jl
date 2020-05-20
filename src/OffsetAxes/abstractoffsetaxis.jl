
"""
    AbstractOffsetAxis{V,Vs}
"""
abstract type AbstractOffsetAxis{V,Vs} <: AbstractSimpleAxis{V,Vs} end

function Base.show(io::IO, ::MIME"text/plain", axis::A) where {A<:AbstractOffsetAxis}
    return print(io, "$(A.name)($(keys(axis)))")
end

StaticRanges.axes_type(::Type{<:AbstractOffsetAxis{V,Vs}}) where {V,Vs} = UnitRange{V}

Base.firstindex(axis::AbstractOffsetAxis) = first(axis)

Base.lastindex(axis::AbstractOffsetAxis) = last(axis)

@inline Base.first(axis::AbstractOffsetAxis) = first(values(axis)) + offset(axis)

@inline Base.last(axis::AbstractOffsetAxis) = last(values(axis)) + offset(axis)

function Base.keys(axis::AbstractOffsetAxis{V,Vs}) where {V,Vs}
    return UnitRange(firstindex(axis), lastindex(axis))
end

function AxisCore.unsafe_reconstruct(axis::AbstractOffsetAxis, ks, inds::I) where {I}
    return similar_type(axis, I)(ks, inds)
end

function AxisCore.unsafe_reconstruct(axis::AbstractOffsetAxis, inds::I) where {I}
    return similar_type(axis, I)(inds)
end

function AxisCore.assign_indices(axis::AbstractOffsetAxis, inds::I) where {I}
    return similar_type(axis, I)(offset(axis), values(inds))
end

offset(r::OneToUnion) = 0
offset(r::AbstractUnitRange) = 1 - first(r)

@inline function Base.iterate(axis::AbstractOffsetAxis)
    ret = iterate(values(axis))
    ret === nothing && return nothing
    return (ret[1] + offset(axis), ret[2])
end

@inline function Base.iterate(axis::AbstractOffsetAxis, i)
    ret = iterate(values(axis), i)
    ret === nothing && return nothing
    return (ret[1] + offset(axis), ret[2])
end

Base.eachindex(axis::AbstractOffsetAxis) = keys(axis)

Base.collect(axis::AbstractOffsetAxis) = collect(keys(axis))

@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, i::Integer)
    return values(axis)[i - offset(axis)] + offset(axis)
end
@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, s::AbstractUnitRange{<:Integer})
    return values(axis)[s .- offset(axis)] .+ offset(axis)
end
@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, s::AbstractOffsetAxis)
    return OffsetAxis(offset(axis), values(axis)[s .- offset(axis)])
end

function Base.checkindex(::Type{Bool}, axis::AbstractOffsetAxis, i::Integer)
    return checkindex(Bool, values(axis), values(axis) - offset(axis))
end

#function Base.checkindex(::Type{Bool}, axis::AbstractOffsetAxis, i::AbstractUnitRange{<:Integer})
#    return checkindex(Bool, values(axis), values(axis) .- offset(axis))
#end

@inline function Base.compute_offset1(parent, stride1::Integer, dims::Tuple{Int}, inds::Tuple{<:AbstractOffsetAxis}, I::Tuple)
    return Base.compute_linindex(parent, I) - stride1*first(axes(parent, dims[1]))
end
@inline Base.axes(axis::AbstractOffsetAxis) = (Base.axes1(axis),)
@inline function Base.axes1(axis::AbstractOffsetAxis)
    return unsafe_reconstruct(axis, offset(axis), Base.axes1(values(axis)))
end
@inline Base.unsafe_indices(axis::AbstractOffsetAxis) = (axis,)

"""
    OffsetStyle{S}

A subtype of `AxisIndicesStyle` indicating that the axis is a subtype `AbstractOffsetAxis`.
"""
struct OffsetStyle{S} <: AxisCore.AxisIndicesStyle end

OffsetStyle(S::AxisIndicesStyle) = OffsetStyle{S}()
OffsetStyle(S::IndicesCollection) =  OffsetStyle{KeysCollection()}()
OffsetStyle(S::IndexElement) = OffsetStyle{KeyElement()}()

function AxisCore.AxisIndicesStyle(::Type{<:AbstractOffsetAxis}, ::Type{T}) where {T}
    return OffsetStyle(AxisIndices.AxisIndicesStyle(T))
end

AxisCore.is_element(::Type{OffsetStyle{T}}) where {T} = AxisCore.is_element(T)

AxisCore.to_index(::OffsetStyle{S}, axis, arg) where {S} = AxisCore.to_index(S, axis, arg)

AxisCore.to_keys(::OffsetStyle{S}, axis, arg, index) where {S} = AxisCore.to_keys(S, axis, arg, index)

