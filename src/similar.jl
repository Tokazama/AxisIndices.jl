function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{Int}}) where {T}
    p = similar(parent(A), T, dims)
    return unsafe_reconstruct(A, p; axes=SimpleAxis.(axes(p)))
end

@inline function Base.similar(A::AxisArray{T}, dims::Tuple{Vararg{Int}}) where {T}
    return similar(A, T, dims)
end
function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{Union{Integer,OneTo}}}) where {T}
    p = similar(parent(A), T, dims)
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), dims, axes(p)); checks=c)
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Union{Integer, Base.OneTo},Vararg{Union{Integer, Base.OneTo}}}) where {T}
    p = similar(parent(A), T, dims)
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), dims, axes(p)); checks=c)
end

function Base.similar(A::AxisArray, ::Type{T}, ks::Tuple{AbstractUnitRange,Vararg{AbstractUnitRange}}) where {T}
    p = similar(parent(A), T, map(length, ks))
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), ks, axes(p)); checks=c)
end


const DimOrAxes = Union{<:AbstractAxis,Base.DimOrInd}


function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{Vararg{DimOrAxes}}) where {T}
    return _similar(a, T, dims)
end

function _similar(a::AxisArray, ::Type{T}, dims::Tuple) where {T}
    p = similar(parent(a), T, map(Base.to_shape, dims))
    axs = map((key, axis) -> compose_axis(key, axis, NoChecks), dims, axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end
function _similar(a, ::Type{T}, dims::Tuple) where {T}
    p = similar(a, T, map(Base.to_shape, dims))
    axs = map((key, axis) -> compose_axis(key, axis, NoChecks), dims, axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end

function Base.similar(A::AxisArray)
    p = similar(parent(A))
    return unsafe_reconstruct(A, p; axes=map(assign_indices, axes(A), axes(p)))
end

function Base.similar(::Type{T}, shape::Tuple{DimOrAxes,Vararg{DimOrAxes}}) where {T<:AbstractArray}
    p = similar(T, Base.to_shape(shape))
    axs = map((key, axis) -> compose_axis(key, axis, NoChecks), shape, axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end

function Base.similar(::Type{T}, ks::Tuple{Vararg{<:AbstractAxis}}) where {T<:AbstractArray}
    p = similar(T, map(length, ks))
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), ks, axes(p)); checks=c)
end

#=
function reaxis_by_offset_dynamic(axis::AbstractAxis, inds::AbstractRange)
    if is_dynamic(axis) ||                         # need to copy something if part of it is dynamic
        first(known_offsets(axis)) === nothing ||  # ensure offsets are known to match at compile time
        first(known_offsets(axis)) !== first(known_offsets(inds))
        return unsafe_reconstruct(axis, inds)
    else
        return axis
    end
end

Base.similar(A::AxisArray{T}) where {T} = similar(A, T)
function Base.similar(A::AxisArray, ::Type{T}) where {T}
    p = similar(parent(A), T)
    return _unsafe_axis_array(p, map(reaxis_by_offset_dynamic, axes(A), axes(p)))
end


Base.similar(A::AxisArray{T}, dims::Tuple{Vararg{Int}}) where {T} = similar(A, T, dims)

function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{Int,N}}) where {T,N}
    p = similar(parent(A), T, dims)
    axs = compose_axes(naxes(a, StaticInt(N)), axes(p))
    return _unsafe_axis_array(p, axs)
end

_new_axis_length(x::Integer) = x
_new_axis_length(x::AbstractRange) = length(x)

# 1. if the axis return from the similar(A, ::Int...) is...
#   a. ...OneTo, then we use that for as_axis
similar_axis(axis, inds, dimarg) = similar_axis(axis, as_axis(inds, dimarg))
similar_axis(axis, inds, dimarg::Integer) = similar_axis(axis, inds, as_axis(dimarg))
function similar_axis(old_axis::AbstractAxis, new_axis)
    # if we just constructed an offset axis don't do it again
    if old_axis isa AbstractOffsetAxis && new_axis isa AbstractOffsetAxis
        return similar_axis(parent(old_axis), new_axis)
    else
        return unsafe_reconstruct(old_axis, new_axis)
    end
end
similar_axis(old_axis, new_axis) = as_axis(new_axis)

# see this https://github.com/JuliaLang/julia/blob/33573eca1107531b3b33e8d20c08ef6db81c9f41/base/abstractarray.jl#L737 comment
# for why we do this type piracy
function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{AbstractUnitRange}) where {T}
    p = similar(a, T, (length(first(dims)),))
    axs = map(similar_axis, naxes(a, StaticInt(1)), axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{Union{Integer, AbstractUnitRange}, Vararg{Union{Integer, AbstractUnitRange},N}}) where {T,N}
    p = similar(a, T, map(_new_axis_length, dims))
    axs = map(similar_axis, naxes(a, StaticInt(1 + N)), axes(p), dims)
    return _unsafe_axis_array(p, axs)
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{AbstractUnitRange}) where {T}
    p = similar(parent(a), T, (length(first(dims)),))
    axs = map(similar_axis, naxes(a, StaticInt(1)), axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Union{Integer, AbstractUnitRange}, Vararg{Union{Integer, AbstractUnitRange},N}}) where {T,N}
    p = similar(parent(a), T, map(_new_axis_length, dims))
    axs = map(similar_axis, naxes(a, StaticInt(1 + N)), axes(p), dims)
    return _unsafe_axis_array(p, axs)
end

function Base.similar(::Type{T}, dims::Tuple{Union{Integer, AbstractUnitRange}, Vararg{Union{Integer, AbstractUnitRange}}}) where {T<:AbstractArray}
    p = similar(T, map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
function Base.similar(::Type{T}, dims::Tuple{Union{Integer, AbstractUnitRange}}) where {T<:AbstractArray}
    p = similar(T, map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end

function Base.similar(::Type{T}, dims::Tuple{Union{Integer, AbstractUnitRange}, Vararg{Union{Integer, AbstractUnitRange}}}) where {T<:AxisArray}
    p = similar(parent_type(T), map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
function Base.similar(::Type{T}, dims::Tuple{Union{Integer, AbstractUnitRange}}) where {T<:AxisArray}
    p = similar(parent_type(T), map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end

=#
