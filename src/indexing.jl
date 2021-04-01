
##################
### checkindex ###
##################
Base.checkindex(::Type{Bool}, axis::Axis, ::Fix2) = true
Base.checkindex(::Type{Bool}, axis::Axis, arg::LogicalIndex) = (axis,) == axes(arg.mask)
Base.checkindex(::Type{Bool}, axis::Axis, ::Interval) = true
Base.checkindex(::Type{Bool}, axis::Axis, ::Colon) = true
Base.checkindex(::Type{Bool}, axis::Axis, ::Slice) = true
function Base.checkindex(::Type{Bool}, axis::Axis, arg::AbstractArray{T}) where {T<:Integer}
    return checkindex(Bool, eachindex(axis), arg)
end
Base.checkindex(::Type{Bool}, axis::Axis, ::AbstractArray{Bool}) = false
function Base.checkindex(::Type{Bool}, axis::Axis, arg::AbstractVector{Bool})
    return checkindex(Bool, eachindex(axis), arg)
end
Base.checkindex(::Type{Bool}, axis::Axis, arg::Function) = true
Base.checkindex(::Type{Bool}, axis::Axis, arg::In) = all(in(keys(axis)), arg.x) # TODO test this
Base.checkindex(::Type{Bool}, axis::Axis, arg::Equal) = in(arg.x, axis)
Base.checkindex(::Type{Bool}, axis::Axis, arg::Approx) = !(find_first(arg, keys(axis)) === nothing)
function Base.checkindex(::Type{Bool}, axis::Axis, arg::AbstractRange{T}) where {T}
    return checkindex(Bool, axis, static_first(arg)) && checkindex(Bool, axis, static_last(arg))
end
Base.checkindex(::Type{Bool}, axis::Axis, arg::Real) = _checkindex(axis, arg)
Base.checkindex(::Type{Bool}, axis::Axis, arg) = _checkindex(axis, arg)
_checkindex(axis::Axis, arg::Integer) = in(arg, axis)
_checkindex(axis::Axis, arg) = _check_key_index(keys(axis), axis, arg)
_check_key_index(k::AbstractArray{T}, axis, arg) where {T} = checkindex(Bool, axis, ==(arg))
function _check_key_index(k::AbstractArray{T1}, axis, arg::AbstractArray{T2}) where {T1,T2}
    return checkindex(Bool, axis, in(arg))
end
function _check_key_index(k::AbstractArray{T1}, axis, arg::AbstractArray{T2}) where {T1<:AbstractArray,T2}
    return checkindex(Bool, axis, ==(arg))
end
function _check_key_index(k::AbstractArray{T1}, axis, arg::AbstractArray{T2}) where {T1<:AbstractArray,T2<:AbstractArray}
    return checkindex(Bool, axis, in(arg))
end

################
### getindex ###
################
Base.getindex(axis::Axis, ::Colon) = copy(axis)
Base.getindex(axis::Axis, ::Ellipsis) = copy(axis)
@propagate_inbounds function Base.getindex(axis::Axis, arg::Integer)
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    return Int(arg)
end

# we don't use parent(axis) because if we call keys(axis) then we need offsets to be attached
# to the key indexing
@propagate_inbounds function Base.getindex(axis::Axis, arg::AbstractUnitRange{<:Integer})
    return _axis_to_axis(param(axis), axis, arg)
end
@propagate_inbounds function _axis_to_axis(pds::AxisPads, axis, inds)
    p = parent(axis)
    start_index = static_first(inds)
    stop_index = static_last(inds)
    start_parent = static_first(p)
    stop_parent = static_last(p)

    nbefore = start_parent - start_index
    if nbefore > 0
        fpad = nbefore
        start = conform_dynamic(start_parent, start_index)
    else
        fpad = zero(nbefore)
        start = conform_dynamic(start_index, start_parent)
    end

    nafter = stop_index - stop_parent
    if nafter > 0
        lpad = nafter
        stop = conform_dynamic(stop_parent, stop_index)
    else
        lpad = zero(nafter)
        stop = conform_dynamic(stop_index, stop_parent)
    end
    @boundscheck if (lpad > last_pad(pds)) || (fpad > first_pad(pds))
        throw(BoundsError(axis, inds))
    end
    return initialize(
        reparam(pds)(_Pad(int(fpad), int(lpad))),
        @inbounds(_axis_to_axis(p, start:stop))
    )
end
@propagate_inbounds function _axis_to_axis(p::AxisStruct{T}, axis, inds) where {T}
    len = known_length(inds)
    a = getindex(parent(axis), inds)
    if len === nothing
        pa = _AxisKeys(@inbounds(keys(axis)[inds]))
    elseif known_length(axis) === len
        pa = p
    else
        pa = AxisStruct{NamedTuple{__names(T, inds), __types(T, inds)}}()
    end
    return _initialize(pa, a)
end
@generated function __names(::Type{T}, ::StepSRange{F,S,L}) where {T,F,S,L}
    e = Expr(:tuple)
    for i in F:S:L
        push!(e.args, QuoteNode(fieldname(T, i)))
    end
    return e
end
@generated function __names(::Type{T}, ::UnitSRange{F,L}) where {T,F,L}
    e = Expr(:tuple)
    for i in F:L
        push!(e.args, QuoteNode(fieldname(T, i)))
    end
    return e
end

@generated function __types(::Type{T}, ::StepSRange{F,L}) where {T,F,L}
    return Tuple{[fieldtype(T, i) for i in F:S:L]...}
end
@generated function __types(::Type{T}, ::UnitSRange{F,L}) where {T,F,L}
    return Tuple{[fieldtype(T, i) for i in F:L]...}
end

@propagate_inbounds function _axis_to_axis(p::AxisKeys, axis, arg)
    p = getindex(parent(axis), arg)
    return _initialize(_AxisKeys(@inbounds(keys(axis)[arg])), p)
end

#= have parents offset axes check bounds
@propagate_inbounds function _axis_to_axis(axis::Axis, arg::A) where {A}
    return initialize(param(axis), _axis_to_axis(parent(axis), _sub_offset(axis, arg)))
end
=#

@propagate_inbounds function _axis_to_axis(p::SimpleParam, axis, arg)
    @boundscheck if (first(axis) > first(arg)) || (last(axis) < last(arg))
        throw(BoundsError(axis, arg))
    end
    return SimpleAxis(static_first(arg):static_last(arg))
end

###
### axis -> array
###
@propagate_inbounds function Base.getindex(axis::Axis, arg::StepRange{<:Integer})
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::Axis, arg::AbstractArray{<:Integer})
    return ArrayInterface.unsafe_getindex(axis, (to_index(axis, arg),))
end
@propagate_inbounds function Base.getindex(axis::Axis, arg)
    i = to_index(axis, arg)
    return @inbounds(axis[i])
end

# if we do have an offset then it is propagated in the keys
@inline function _axis_to_array(axis, inds)
    new_axis, array = _axis_to_array(parent(axis), inds)
    return initialize(drop_offset(param(axis)), new_axis), array
end
@inline function _axis_to_array(axis::SimpleAxis, inds)
    return SimpleAxis(static(1):static_length(inds)), @inbounds(parent(axis)[inds])
end
@inline function _axis_to_array(axis::KeyedAxis, inds)
    new_axis, array = _axis_to_array(parent(axis), inds)
    k = @inbounds(drop_offset(getfield(axis, :keys))[inds])
    return initialize(_AxisKeys(k), new_axis), array
end
@inline function _axis_to_array(axis::StructAxis{T}, inds::UnitSRange{F,L}) where {T,F,L}
    new_axis, array = _axis_to_array(parent(axis), inds)
    return _StructAxis(NamedTuple{__names(T, inds), __types(T, inds)}, new_axis), array
end
@inline function _axis_to_array(axis::StructAxis{T}, inds::StepSRange{F,S,L}) where {T,F,S,L}
    new_axis, array = _axis_to_array(parent(axis), inds)
    return _StructAxis(NamedTuple{__names(T, inds), __types(T, inds)}, new_axis), array
end
@inline function _axis_to_array(axis::StructAxis{T}, inds) where {T}
    new_axis, array = _axis_to_array(parent(axis), inds)
    return _Axis([fieldname(T, i) for i in inds], new_axis), array
end

################
### to_index ###
################
ArrayInterface.to_index(::IndexAxis, axis, arg::CartesianIndices{0}) = arg
ArrayInterface.to_index(::IndexAxis, axis, arg::Colon) = indices(axis)

@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{Bool})
    @boundscheck checkbounds(axis, arg)
    return @inbounds(to_index(parent(axis), arg))
end

@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Integer)
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    return int(arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Union{Equal,Approx})
    k = keys(axis)
    i = find_first(arg, k)
    @boundscheck if i === nothing
        throw(BoundsError(axis, arg.x))
    end
    return sub_keys_parent_diff(axis, i)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractRange{<:Integer})
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    return int(static_first(arg)):int(static_step(arg)):int(static_last(arg))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::In)
    inds = find_all(arg, keys(axis))
    @boundscheck if length(arg.x) != length(inds)
        throw(BoundsError(axis, arg.x))
    end
    return sub_keys_parent_diff(axis, inds)
end
function ArrayInterface.to_index(::IndexAxis, axis, arg::Function)
    return sub_keys_parent_diff(axis, find_all(arg, keys(axis)))
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{<:Integer})
    @boundscheck checkindex(Bool, axis, arg) || throw(BoundsError(axis, arg))
    return arg
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg)
    inds = _k2i(has_keys(axis), axis, arg)
    @boundscheck inds === nothing && throw(BoundsError(axis, arg))
end

# _k2i digs to the keys and converts the keys to indices.
_k2i(::False, axis, arg) = ___k2i(eachindex(axis), arg)
_k2i(::True, axis, arg) = __k2i(param(axis), parent(axis), arg)
__k2i(p, a, arg) = __k2i(param(axis), parent(axis), arg)
# Once we find keys we check to see if any of the nested axes have offsets
function __k2i(p::AxisKeys, a, arg)
    inds = ___k2i(param(p), arg)
    if known(has_offset(a))
        return _maybe_offset(static_first(a), inds)
    else
        return inds
    end
end
function __k2i(p::AxisStruct, a, arg)
    inds = ___key_to_index(keys(p), arg)
    if known(has_offset(a))
        return _maybe_offset(static_first(a), inds)
    else
        return inds
    end
end
# If offsets are found before reaching the keys then we hold onto those and apply them
__k2i(p::AxisOffset, a, arg) = _maybe_offset(param(p), __k2i(param(a), parent(a), arg))
function __k2i(p::AxisOrigin, a, arg)
    return _maybe_offset(
        _sub(_sub(param(p), _half(static_length(a))), static_first(a)), 
        __k2i(param(a), parent(a), arg)
    )
end

__key_to_index(k::AbstractArray{T}, arg) where {T} = find_first(==(arg), k)
function __key_to_index(k::AbstractArray{T1}, arg::AbstractArray{T2}) where {T1,T2}
    inds = find_all(in(arg), k)
    if length(inds) === length(k)
        return inds
    else
        return nothing
    end
end
__key_to_index(k::AbstractArray{T1}, arg::AbstractArray{T2}) where {T1<:AbstractArray,T2} = find_first(==(arg), k)
function key_to_index(k::AbstractArray{T1}, arg::AbstractArray{T2}) where {T1<:AbstractArray,T2<:AbstractArray}
    inds = find_all(in(arg), k)
    if length(inds) === length(k)
        return inds
    else
        return nothing
    end
end

#######################
### to_parent_index ###
#######################
to_parent_index(axis, i::Integer) = i
to_parent_index(a::Axis, i::Integer) = _to_parent_index(param(a), parent(a), i)
_to_parent_index(p, a, i::Integer) = to_parent_index(a, i::Integer)
_to_parent_index(p::AxisOffset, a, i::Integer) = to_parent_index(a, i - param(p))
function _to_parent_index(p::AxisOrigin, a, i::Integer)
    return to_parent_index(a, i - ((param(p) - _half(static_length(a))) - static_first(a)))
end
function _to_parent_index(p::AxisPads, a, i::Integer)
    return pad_index(p, static_first(a), static_last(a), i)
end
function pad_index(p::FillPads, start, stop, i)
    if start > i
        return -1
    elseif stop < i
        return -1
    else
        return i
    end
end
function pad_index(::ReplicatePads, start, stop, i)
    if start > i
        return start
    elseif stop < i
        return stop
    else
        return i
    end
end
function pad_index(::SymmetricPads, start, stop, i)
    if start > i
        return 2start - i
    elseif stop < i
        return 2stop - i
    else
        return int(i)
    end
end
function pad_index(::CircularPads, start, stop, i)
    if start > i
        return stop - start + i + one(start)
    elseif stop < i
        return start + i - stop - one(stop)
    else
        return i
    end
end
function pad_index(::ReflectPads, start, stop, i)
    if start > i
        return 2start - i - one(start)
    elseif stop < i
        return 2stop - i + one(stop)
    else
        return int(i)
    end
end

#= to_parent_indices =#
to_parent_indices(A, inds) = to_parent_indices(IndexStyle(A), A, inds)
to_parent_indices(::IndexLinear, x::AbstractArray, inds::Tuple) = to_linear(x, inds)
to_parent_indices(::IndexCartesian, A, inds) = to_cartesian(axes(A), inds)
#to_cartesian(::Tuple{}, ::Tuple{}) = ()
to_cartesian(::Tuple{}, i::Tuple) = () # trailing inbounds can only be 1 or 1:1
to_cartesian(a::Tuple, i::Tuple) = (to_parent_index(first(a), first(i)), to_cartesian(tail(a), tail(i))...)
# FIXME `first(inds)-1` only makes sense if transforming from a linear indexing that starts at 1
function to_cartesian(axes::Tuple{Vararg{Any,N}}, indices::Tuple{Any}) where {N}
    return _to_cartesian(axes, first(indices) - static(1))
end
function _to_cartesian(axs::Tuple{Any,Vararg{Any}}, i)
    axis = first(axs)
    len = static_length(axis)
    inext = div(i, len)
    return (i - len * inext + static_first(axis), _to_cartesian(tail(axs), inext)...)
end
_to_cartesian(axs::Tuple{Any}, i) = i + static_first(first(axs))

#= to_linear =#
to_linear(x, inds::Tuple{Integer}) = to_parent_index(eachindex(x), first(inds))
#to_linear(x, inds::Tuple{AbstractCartesianIndex}) = to_linear()
@inline function to_linear(x, inds::Tuple{Integer,Vararg})
    first(inds)
    o = ArrayInterface.offsets(x)
    s = ArrayInterface.size(x)
    return first(inds) - first(o) + _to_linear(first(s), tail(s), tail(o), tail(inds)) + static(1)
end
@inline function _to_linear(stride, s::Tuple{Any,Vararg}, o::Tuple{Any,Vararg}, inds::Tuple{Any,Vararg})
    return ((first(inds) - first(o)) * stride) + _to_linear(stride * first(s), tail(s), tail(o), tail(inds))
end
_to_linear(stride, s::Tuple{Any}, o::Tuple{Any}, inds::Tuple{Any}) = (first(inds) - first(o)) * stride
# trailing inbounds can only be 1 or 1:1
_to_linear(stride, ::Tuple{}, ::Tuple{}, ::Tuple{Any}) = static(0)

##########################
### unsafe_get_element ###
##########################
function ArrayInterface.unsafe_get_element(A::AxisArray, inds::Tuple{})
    return @inbounds(getindex(parent(A)))
end
function ArrayInterface.unsafe_get_element(A::AxisArray, inds)
    return ArrayInterface.unsafe_get_element(IndexStyle(A), A, inds)
end
function ArrayInterface.unsafe_get_element(::IndexLinear, A::AxisArray, inds)
    return @inbounds(getindex(parent(A), to_parent_indices(A, inds)))
end
function ArrayInterface.unsafe_get_element(::IndexCartesian, A::AxisArray, inds)
    return _get_element(A, to_parent_indices(A, inds))
end

_get_element(A, inds::Tuple{Vararg{Union{Integer,ZeroPads}}}) = zero(eltype(A))
_get_element(A, inds::Tuple{Vararg{Union{Integer,OnePads}}}) = oneunit(eltype(A))
_get_element(A, inds::Tuple{Vararg{Integer}}) = @inbounds(getindex(parent(A), inds...))


ArrayInterface.unsafe_get_element(axis::AbstractAxis, inds) = eltype(axis)(first(inds))

@inline function ArrayInterface.unsafe_get_collection(axis::AbstractAxis, inds::Tuple)
    return _unsafe_get_axis_collection(axis, first(inds))
end
_unsafe_get_axis_collection(axis, i::Integer) = Int(i)
@inline function _unsafe_get_axis_collection(axis, inds)
    if known_step(inds) === 1
        return _axis_to_axis(axis, inds)
    else
        new_axis, array = _axis_to_array(axis, inds)
        return _AxisArray(array, (new_axis,))
    end
end

@inline function _axis_to_axis(axis::StructAxis{T}, inds::StepSRange{F,S,L}) where {T,F,S,L}
    new_axis = _axis_to_axis(parent(axis), inds)
    return _StructAxis(NamedTuple{__names(T, inds), __types(T, inds)}, new_axis)
end

#############################
### unsafe_get_collection ###
#############################

