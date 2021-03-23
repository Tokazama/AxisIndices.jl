
_new_axis_length(x::Integer) = x
_new_axis_length(x::AbstractUnitRange) = length(x)

const DimAxes = Union{AbstractVector,Integer}

# see this https://github.com/JuliaLang/julia/blob/33573eca1107531b3b33e8d20c08ef6db81c9f41/base/abstractarray.jl#L737 comment
# for why we do this type piracy
function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{AbstractUnitRange}) where {T}
    p = similar(a, T, (length(first(dims)),))
    return initialize_axis_array(p, (similar_axis(axes(p, 1), first(dims)),))
end
function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{DimAxes, Vararg{DimAxes,N}}) where {T,N}
    p = similar(a, T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Union{Integer, Base.OneTo}}) where {T}
    p = similar(parent(a), T, (length(first(dims)),))
    return initialize_axis_array(p,  (similar_axis(axes(p, 1), first(dims)),))
end
function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{AbstractUnitRange}) where {T}
    p = similar(parent(a), T, (length(first(dims)),))
    return initialize_axis_array(p,  (similar_axis(axes(p, 1), first(dims)),))
end

function Base.similar(
    a::AxisArray,
    ::Type{T},
    dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo},N}}
) where {T,N}
    p = similar(parent(a), T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{DimAxes, Vararg{DimAxes,N}}) where {T,N}
    p = similar(parent(a), T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(::Type{T}, dims::Tuple{DimAxes, Vararg{DimAxes}}) where {T<:AbstractArray}
    p = similar(T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(::Type{T}, dims::Tuple{DimAxes}) where {T<:AbstractArray}
    p = similar(T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Vararg{Int64, N}}) where {T,N}
    p = similar(parent(a), T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}) where {T}
    return initialize_axis_array(similar(parent(a), T, size(a)), axes(a))
end

###
### similar_axis 
### TODO choose better name for this b/c this assumes that they are the same size already
similar_axis(original, paxis, inds) = _similar_axis(original, paxis, inds)

# we can't be sure that the new indices aren't longer than the keys for Axis or StructAxis
# so we have to drop them
similar_axis(original::Axis, paxis, inds) = similar_axis(parent(axis), paxis, inds)
similar_axis(original::StructAxis, paxis, inds) = similar_axis(parent(axis), paxis, inds)

# If the original axis has an offset we should try to preserive that trait, but if the new
# type explicitly provides an offset then we should respect that
similar_axis(original::OffsetAxis, paxis, inds) =  _similar_offset_axis(original.offset, similar_axis(parent(original), paxis, inds))
similar_axis(original::PaddedAxis, paxis, inds) =  _similar_offset_axis(offset1(original), similar_axis(parent(original), paxis, inds))
function _similar_offset_axis(f, inds::I) where {I}
    if known_first(I) === 1
        return OffsetAxis(f, inds)
    else
        return inds
    end
end
similar_axis(original::CenteredAxis, paxis, inds) =  _similar_centered_axis(similar_axis(parent(original), paxis, inds))
function _similar_centered_axis(inds::I) where {I}
    if known_first(I) === 1
        return CenteredAxis(similar_axis(paxis, inds))
    else
        return similar_axis(paxis, inds)
    end
end
similar_axis(original::SimpleAxis, paxis, inds) = similar_axis(paxis, inds)
similar_axis(::OneTo, paxis, inds) = similar_axis(paxis, inds)

similar_axis(::OneTo, inds::Integer) = SimpleAxis(One():inds)
similar_axis(::OptionallyStaticUnitRange{One,Int}, inds::Integer) = SimpleAxis(One():inds)



# 2-args
similar_axis(paxis, dim::Integer) = SimpleAxis(One():dim)
function similar_axis(paxis::A, inds::I) where {A,I}
    if known_first(A) !== 1
        throw_offset_error(paxis)
    end
    return compose_axis(inds)
end



#=
function Base.similar(
    ::Type{T},
    dims::Tuple{Union{Integer, AbstractUnitRange}, Vararg{Union{Integer, AbstractUnitRange}}}
) where {T<:AxisArray}

    p = similar(parent_type(T), map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
function Base.similar(
    ::Type{T},
    dims::Tuple{Union{Integer, AbstractUnitRange}}
) where {T<:AxisArray}

    p = similar(parent_type(T), map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
=#
