Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg) = _check_index_any(axis, arg)
_check_index_any(axis, arg) = checkindex(Bool, parent(axis), arg)
_check_index_any(axis::Axis, arg) = in(arg, keys(axis))

Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Interval) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Colon) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Slice) = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractArray{T}) where {T}
    return _check_index_array(axis, arg)
end
_check_index_array(axis, arg) = checkindex(Bool, eachindex(axis), arg)
function _check_index_array(axis::Axis, arg::AbstractArray{T}) where {T}
    if T <: Integer
        return checkindex(Bool, eachindex(axis), arg)
    else
        return all(in(keys(axis)), arg)
    end
end

Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::AbstractArray{Bool}) = false
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractVector{Bool})
    return checkindex(Bool, eachindex(axis), arg)
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Real) = _check_index_real(axis, arg)
_check_index_real(axis, arg) = checkindex(Bool, parent(axis), arg)
function _check_index_real(axis::AbstractOffsetAxis, arg)
    return checkindex(Bool, parent(axis), _sub_offset(axis, arg))
end
function _check_index_real(axis::Axis, arg)
    if arg isa Integer
        return checkindex(Bool, parent(axis), arg)
    else
        return _check_index_any(axis, arg)
    end
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Union{<:Equal,<:Approx})
    return !(find_first(arg, keys(axis)) === nothing)
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractRange{T}) where {T}
    return _check_index_range(axis, arg)
end
_check_index_range(axis, arg) = checkindex(Bool, parent(axis), arg)
function _check_index_range(axis::AbstractOffsetAxis, arg)
    return checkindex(Bool, parent(axis), _sub_offset(axis, arg))
end
function _check_index_range(axis::Axis, arg::AbstractRange{T}) where {T}
    if T <: Integer
        return checkindex(Bool, parent(axis), arg)
    else
        return length(find_all_in(arg, keys(axis))) == length(axis)
    end
end

Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Fix2) = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::LogicalIndex)
    return (axis,) == axes(arg.mask)
end

