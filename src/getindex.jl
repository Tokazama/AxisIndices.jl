
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

###
### AxisArray
###
function ArrayInterface.unsafe_get_element(A::AxisArray, inds)
    return ArrayInterface.unsafe_get_element(IndexStyle(A), A, inds)
end
function ArrayInterface.unsafe_get_element(::IndexLinear, A::AxisArray, inds)
    return @inbounds(getindex(parent(A), inds...))
end
function ArrayInterface.unsafe_get_element(::IndexCartesian, A::AxisArray, inds)
    return _get_element(A, inds, get_fill_pad(axes(A), inds))
end

_get_element(A, inds::Tuple, ::Nothing) = @inbounds(getindex(parent(A), inds...))
_get_element(A, inds::Tuple, p::FillPads) = pad_with(A, p)

# FIXME change this so that it only checks when we are looking at padded axes
get_fill_pad(::Tuple{}, ::Tuple{}) = nothing
function get_fill_pad(axs::Tuple{Any,Vararg}, inds::Tuple{Any,Vararg})
    p = get_fill_pad(first(axs), first(inds))
    if p === nothing
        return get_fill_pad(tail(axs), tail(inds))
    else
        return p
    end
end
get_fill_pad(axis, i) = nothing
get_fill_pad(axis::PaddedAxis, i) = _get_fill_pad(pads(axis), i)

_get_fill_pad(::PadsParameter, ::Int) = nothing
_get_fill_pad(::PadsParameter, ::StaticInt) = nothing
_get_fill_pad(::PadsParameter, ::StaticInt{0}) = nothing
_get_fill_pad(p::FillPads, ::StaticInt{0}) = p
_get_fill_pad(p::FillPads, i::StaticInt{I}) where {I} = i
function _get_fill_pad(p::FillPads, i::Int)
    if i === -1
        return p
    else
        return nothing
    end
end
function ArrayInterface.unsafe_get_collection(A::AxisArray, inds)
    axs = to_axes(A, inds)
    dest = similar(A, axs)
    if map(Base.unsafe_length, axes(dest)) == map(Base.unsafe_length, axs)
        _unsafe_getindex!(dest, A, inds...) # usually a generated function, don't allow it to impact inference result
    else
        Base.throw_checksize_error(dest, axs)
    end
    return dest
end

function ArrayInterface.unsafe_set_collection!(A::AxisArray, val, inds)
    return _unsafe_setindex!(IndexStyle(A), A, val, inds...)
end

@generated function _unsafe_getindex!(
    dest::AbstractArray,
    src::AbstractArray,
    I::Vararg{Union{Real,AbstractArray},N}
) where {N}
    return _generate_unsafe_getindex!_body(N)
end
function _generate_unsafe_getindex!_body(N::Int)
    quote
        Base.@_inline_meta
        D = eachindex(dest)
        Dy = iterate(D)
        @inbounds Base.Cartesian.@nloops $N j d -> I[d] begin
            # This condition is never hit, but at the moment
            # the optimizer is not clever enough to split the union without it
            Dy === nothing && return dest
            (idx, state) = Dy
            dest[idx] = ArrayInterface.unsafe_get_element(src, Base.Cartesian.@ntuple($N, j))
            Dy = iterate(D, state)
        end
        return dest
    end
end

@generated function _unsafe_setindex!(::IndexStyle, A::AbstractArray, x, I::Vararg{Union{Real,AbstractArray}, N}) where N
    _generate_unsafe_setindex!_body(N)
end

function _generate_unsafe_setindex!_body(N::Int)
    quote
        x′ = Base.unalias(A, x)
        Base.Cartesian.@nexprs $N d -> (I_d = Base.unalias(A, I[d]))
        idxlens = Base.Cartesian.@ncall $N Base.index_lengths I
        Base.Cartesian.@ncall $N Base.setindex_shape_check x′ (d -> idxlens[d])
        Xy = iterate(x′)
        @inbounds Base.Cartesian.@nloops $N i d->I_d begin
            # This is never reached, but serves as an assumption for
            # the optimizer that it does not need to emit error paths
            Xy === nothing && break
            (val, state) = Xy
            ArrayInterface.unsafe_set_element!(A, val, Base.Cartesian.@ntuple($N, i))
            Xy = iterate(x′, state)
        end
        A
    end
end

