
is_key(collection, k) = is_key(keytype(collection), typeof(k))
is_key(::Type{KeyType}, ::Type{ArgType}) where {KeyType, ArgType} = static(0)
is_key(::Type{KeyType}, ::Type{KeyType}) where {KeyType<:Integer} = static(0)
is_key(::Type{KeyType}, ::Type{<:Equal}) where {KeyType} = static(1)
is_key(::Type{KeyType}, ::Type{<:Approx}) where {KeyType} = static(1)
is_key(::Type{KeyType}, ::Type{ArgType}) where {KeyType,ArgType<:Function} = static(2)
is_key(::Type{KeyType}, ::Type{KeyType}) where {KeyType} = static(1)
function is_key(::Type{KeyType}, ::Type{KeyType}) where {KeyType<:AbstractVector}
    return is_key(eltype(KeyType), eltype(KeyType))
end
function is_key(::Type{KeyType}, ::Type{ArgType}) where {KeyType,ArgType<:AbstractVector}
    return is_key(KeyType, eltype(ArgType)) * static(2)
end

@propagate_inbounds function keys_to_index(::StaticInt{1}, axis, arg::Union{<:Equal,Approx})
    k = keys(axis)
    i = find_first(arg, k)
    @boundscheck if i === nothing
        throw(BoundsError(axis, arg.x))
    end
    return sub_keys_parent_diff(axis, i)
end
@propagate_inbounds function keys_to_index(::StaticInt{2}, axis, arg)
    k = keys(axis)
    inds = find_all(in(arg), k)
    @boundscheck if length(arg) != length(inds)
        throw(BoundsError(axis, arg))
    end
    return sub_keys_parent_diff(axis, inds)
end
function keys_to_index(::StaticInt{2}, axis, arg::Function)
    return sub_keys_parent_diff(axis, find_all(arg, keys(axis)))
end


function keys_to_index(::StaticInt{1}, axis, arg)
    return keys_to_index(static(1), axis, ==(arg))
end


# need to subtract the different between the first index of the keys and the parent axis
function sub_keys_parent_diff(axis::StructAxis, inds::Integer)
    return int(inds + (static_first(axis) - static(1)))
end
function sub_keys_parent_diff(axis::StructAxis, inds)
    return inds .+ (static_first(axis) - static(1))
end

function sub_keys_parent_diff(axis, inds::Integer)
    return int(inds + (static_first(axis) - offset1(keys(axis))))
end
function sub_keys_parent_diff(axis, inds)
    return inds .+ (static_first(axis) - offset1(keys(axis)))
end


###
### keys
###
function Base.keys(axis::StructAxis{T}) where {T}
    return _AxisArray(Symbol[fieldnames(T)...], (SimpleAxis(One():static_length(axis)),))
end
function Base.keys(axis::KeyedAxis)
    k = getfield(axis, :keys)
    return _offset_keys(offset1(axis) - offset1(k), k)
end
_offset_keys(::StaticInt{0}, k::AbstractVector) = k
function _offset_keys(o::StaticInt{O}, k::AbstractVector) where {O}
    axis = _OffsetAxis(o, compose_axis(eachindex(k)))
    return _AxisArray(k, (axis,))
end
function _offset_keys(o::Int, k::AbstractVector)
    axis = _OffsetAxis(o, compose_axis(eachindex(k)))
    return _AxisArray(k, (axis,))
end
Base.keys(axis::AbstractAxis) = _keys(has_keys(axis), axis)
_keys(::False, axis) = eachindex(axis)
function _keys(::True, axis::OffsetAxis)
    k = keys(axis)
    return _offset_keys(offset1(axis) - offset1(k), k)
end
function _keys(::True, axis::CenteredAxis)
    k = keys(axis)
    return _offset_keys(offset1(axis) - offset1(k), k)
end

#= keytype =#
Base.keytype(::Type{T}) where {T<:AbstractAxis} = keytype(parent_type(T))
Base.keytype(::Type{T}) where {T<:StructAxis} = Symbol
Base.keytype(::Type{T}) where {K,T<:KeyedAxis{K}} = eltype(K)

#= keys_type(::Type{T}) - returns the type of keys collection for `T` =#
keys_type(::Type{Axis{K,P}}) where {K,P} = K
function keys_type(::Type{StructAxis{T,P}}) where {T,P}
    return AxisArray{Symbol,1,Vector{Symbol},Tuple{SimpleAxis{UnitSRange{1,known_length(T)}}}}
end
keys_type(::Type{MutableAxis}) = OptionallyStaticUnitRange{StaticInt{1},Int}
keys_type(::Type{OneToAxis}) = OptionallyStaticUnitRange{StaticInt{1},Int}
keys_type(::Type{StaticAxis{L}}) where {L} = UnitSRange{1,L}
keys_type(::Type{T}) where {T<:AbstractAxis} = _keys_type(has_offset(T), T)
keys_type(::False, ::Type{T}) where {T} = keys_type(parent_type(T))
function keys_type(::True, ::Type{T}) where {T}
    return _offset_keys_type(known_offset1(T), keys_type(parent_type(T)))
end
_offset_keys_type(::Nothing, ::Type{T}) where {T}  = OffsetAxis{Int,T}
_offset_keys_type(::StaticInt{O}, ::Type{T}) where {O,T} = OffsetAxis{StaticInt{O},T}

#= has_keys - do we have StructAxis or Axis in a parent field?=#
has_keys(x) = has_keys(typeof(x))
has_keys(::Type{T}) where {T} = static(false)
has_keys(::Type{T}) where {T<:AbstractAxis} = has_keys(parent_type(T))
has_keys(::Type{T}) where {T<:StructAxis} = static(true)
has_keys(::Type{T}) where {T<:KeyedAxis} = static(true)
function has_keys(::Type{T}) where {T<:AxisArray}
    return static(any(eachop_tuple(_has_keys, nstatic(Val(ndims)), axes_types(T))))
end
_has_keys(::Type{T}, i::StaticInt{I}) where {T,I} = has_keys(Static._get_tuple(T, i))

#= strip_keys(x) - return keys and instance of x stripped of keys =#
strip_keys(x::Axis) = keys(x), parent(x)
strip_keys(x::StructAxis) = keys(x), parent(x)
strip_keys(x) = _strip_keys(has_keys(x), x)
function _strip_keys(::True, x)
    k, p = strip_keys(parent(x))
    return k, initialize(x, param(x), p)
end
_strip_keys(::False, x) = nothing, x

#= drop_keys(x) - return instance of x without keys =#
drop_keys(x::KeyedAxis) = parent(x)
drop_keys(x::StructAxis) = parent(x)
drop_keys(x) = _drop_keys(has_keys(x), x)
_drop_keys(::True, x) =initialize(x, param(x), drop_keys(parent(x)))
_drop_keys(::False, x) = x
_drop_keys(::True, x::AxisArray) = _AxisArray(parent(x), map(drop_keys, axes(x)))

