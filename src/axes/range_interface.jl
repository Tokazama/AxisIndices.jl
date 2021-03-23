
@inline Base.getproperty(axis::AbstractAxis, k::Symbol) = getproperty(parent(axis), k)

#= length =#
@inline Base.length(axis::AbstractAxis) = length(parent(axis))

function ArrayInterface.known_length(::Type{T}) where {T<:PaddedAxis}
    return _length_padded_axis(known_first(T), known_last(T))
end
@inline function Base.length(axis::PaddedAxis)
    return _length_padded_axis(static_first(axis), static_last(axis))
end

_length_padded_axis(start::Integer, stop::Integer) = (stop - start) + one(start)
_length_padded_axis(::Nothing, ::Integer) = nothing
_length_padded_axis(::Integer, ::Nothing) = nothing
_length_padded_axis(::Nothing, ::Nothing) = nothing

@inline function Base.length(axis::KeyedAxis{K,P}) where {K,P}
    if known_length(K) !== nothing
        return known_length(K)
    elseif known_length(P) !== nothing
        return known_length(P)
    else
        return length(parent(axis))
    end
end

#= known_last =#
ArrayInterface.known_last(::Type{T}) where {T<:AbstractAxis} = known_last(parent_type(T))
ArrayInterface.known_last(::Type{T}) where {T<:OffsetAxis{Int}} = nothing
function ArrayInterface.known_last(::Type{T}) where {O,T<:OffsetAxis{StaticInt{O}}}
    if known_last(parent_type(T)) === nothing
        return nothing
    else
        return known_last(parent_type(T)) + O
    end
end
function ArrayInterface.known_last(::Type{T}) where {F,L,P<:PadsParameter{F,L},T<:PaddedAxis{P}}
    return _padded_known_last(Pads{F,L}, known_last(parent_type(T)))
end
_padded_known_last(::Type{Pads{F,L}}, ::Nothing) where {F,L} = nothing
_padded_known_last(::Type{Pads{F,L}}, ::Int) where {F,L} = nothing
_padded_known_last(::Type{Pads{F,StaticInt{L}}}, x::Int) where {F,L} = x + L
_padded_known_last(::Type{Pads{F,StaticInt{L}}}, ::Nothing) where {F,L} = nothing

#= last =#
Base.lastindex(a::AbstractAxis) = last(a)
Base.last(axis::AbstractAxis) = last(parent(axis))
Base.last(axis::OffsetAxis) = last(parent(axis)) + getfield(axis, :offset)
Base.last(axis::PaddedAxis) = last(parent(axis)) + last_pad(axis)


#= known_first =#
ArrayInterface.known_first(::Type{T}) where {T<:AbstractAxis} = known_first(parent_type(T))
ArrayInterface.known_first(::Type{T}) where {T<:OffsetAxis{Int}} = nothing
function ArrayInterface.known_first(::Type{T}) where {O,T<:OffsetAxis{StaticInt{O}}}
    if known_first(parent_type(T)) === nothing
        return nothing
    else
        return known_first(parent_type(T)) + O
    end
end
function ArrayInterface.known_first(::Type{T}) where {F,L,P<:PadsParameter{F,L},T<:PaddedAxis{P}}
    return _padded_known_first(Pads{F,L}, known_first(parent_type(T)))
end
_padded_known_first(::Type{Pads{F,L}}, ::Nothing) where {F,L} = nothing
_padded_known_first(::Type{Pads{F,L}}, ::Int) where {F,L} = nothing
_padded_known_first(::Type{Pads{StaticInt{F},L}}, x::Int) where {F,L} = x - F
_padded_known_first(::Type{Pads{StaticInt{F},L}}, ::Nothing) where {F,L} = nothing

#= first =#
Base.firstindex(axis::AbstractAxis) = first(axis)
Base.first(axis::AbstractAxis) = first(parent(axis))
Base.first(axis::OffsetAxis) = first(parent(axis)) + getfield(axis, :offset)
Base.first(axis::PaddedAxis) = first(parent(axis)) - first_pad(axis)

#= offsets =#
#= strip_offsets(x) - return offset and instance of x stripped of offset =#
has_offset(x) = has_offset(typeof(x))
has_offset(::Type{T}) where {T} = static(false)
has_offset(::Type{T}) where {T<:AbstractAxis} = has_offset(parent_type(T))
has_offset(::Type{T}) where {T<:OffsetAxis} = static(true)
has_offset(::Type{T}) where {T<:CenteredAxis} = static(true)
function has_offset(::Type{T}) where {T<:AxisArray}
    return static(any(eachop_tuple(_has_offset, nstatic(Val(ndims)), axes_types(T))))
end
_has_offset(::Type{T}, i::StaticInt{I}) where {T,I} = has_offset(Static._get_tuple(T, i))

#= strip_offset - return offset and instance of x stripped of offset =#
strip_offset(x::OffsetAxis) = param(x), parent(x)
strip_offset(x::CenteredAxis) = param(x), parent(x)
strip_offset(x) = _strip_offset(has_offset(x), x)
function _strip_offset(::True, x)
    o, p = strip_offset(parent(x))
    return o, initialize(x, param(x), p)
end
_strip_offset(::False, x) = nothing, x

#= drop_offset(x) - return instance of x without an offset =#
drop_offset(x::StructAxis{T}) where {T} = parent(x)
drop_offset(x) = _drop_offset(has_offset(x), x)
drop_offset(x::KeyedAxis) = _Axis(keys(x), drop_offset(parent(x)))
_drop_offset(::False, x) = x
_drop_offset(::True, x) = initialize(x, param(x), drop_offset(parent(x)))
_drop_offset(::True, x::AxisArray) = _AxisArray(parent(x), map(drop_offset, axes(x)))

_maybe_offset(odiff::Int, x::AbstractAxis) = OffsetAxis(odiff, x)
_maybe_offset(odiff::Int, x::AbstractVector) = _AxisArray(x, (OffsetAxis(odiff, axes(x, 1)),))
_maybe_offset(odiff::Zero, x::AbstractAxis) = x
_maybe_offset(odiff::Zero, x::AbstractVector) = x
_maybe_offset(odiff::StaticInt{O}, x::AbstractAxis) where {O} = OffsetAxis(odiff, x)
function _maybe_offset(odiff::StaticInt{O}, x::AbstractVector) where {O}
    return _AxisArray(x, (OffsetAxis(odiff, axes(x, 1)),))
end

