
function PaddedAxis(p::PadsParameter, inds::AbstractAxis)
    check_pads(p, first(inds), last(inds))
    return _PaddedAxis(p, inds)
end

@inline Base.axes1(axis::PaddedAxis) = OffsetAxis(static_first(axis):static_last(axis))

#=
    FillPads{F}(fxn::F)

Index style that pads a set number of indices on each side of an axis.
`fxn`(eltype(A))` returns the padded value.

=#
axis_method(p::SymmetricPads) = (pads, axis) -> PaddedAxis(p, pads, axis)

check_pads(::PadsParameter, ::Any, ::Any) = nothing
function check_pad(p::SymmetricPads, start, stop)
    len = stop - start
    if p.first_pad > len
        throw(ArgumentError("cannot have pad that is larger than length of parent indices +1 for SymmetricPads, " *
                            "first pad is $(p.first_pad) and indices are of length $len"))
    elseif last_pad > len
        throw(ArgumentError("cannot have pad that is larger than length of parent indices +1 for SymmetricPads, " *
                            "first pad is $(p.last_pad) and indices are of length $len"))
    else
        return nothing
    end
end
function check_pad(p::CircularPads, start, stop)
    len = stop - start + 1
    if p.first_pad > len
        throw(ArgumentError("cannot have pad of size $(p.first_pad) and indices of length $len for CircularPads"))
    elseif last_pad > len
        throw(ArgumentError("cannot have pad of size $(p.last_pad) and indices of length $len for CircularPads"))
    else
        return nothing
    end
end
function check_pad(p::ReflectPads, start, stop)
    len = stop - start + 1
    if pfirst_pad > len
        throw(ArgumentError("cannot have pad of size $(p.first_pad) and indices of length $len for ReflectPads"))
    elseif last_pad > len 
        throw(ArgumentError("cannot have pad of size $(p.last_pad) and indices of length $len for ReflectPads"))
    else
        return nothing
    end
end

function print_axis(io::IO, axis::PaddedAxis)
    print(io, pads(axis))
    print(io, "(")
    print(io, parent(axis))
    print(io, ")")
end

@noinline function Base.show(io::IO, ::MIME"text/plain", init::PadsParameter)
    print(io, pad_call_string(init))
    print(io, "(")
    fp = first_pad(init)
    lp = last_pad(init)
    if lp === fp
        print(io, "sym_pad=")
        print(io, fp)
        print(io, ")")
    else
        print(io, "first_pad=")
        print(io, fp)
        print(io, ", last_pad=")
        print(io, lp)
        print(io, ")")
    end
end

pad_call_string(@nospecialize(x)) = lowercase(string(nameof(typeof(x)))[1:end-4]) * "_pad"

@inline function _check_index_real(axis::PaddedAxis, arg)
    if first(axis) > arg
        return false
    elseif last(axis) < arg
        return false
    else
        return true
    end
end
_check_index_range(axis::PaddedAxis, arg) = checkindex(Bool, eachindex(axis), arg)

function check_axis_length(ks::PaddedAxis, inds)
    if length(parent(ks)) != length(inds)
        throw(DimensionMismatch(
            "keys and indices must have same length, got length(keys) = $(length(ks))" *
            " and length(indices) = $(length(inds)).")
        )
    end
    return nothing
end

is_dense_wrapper(::Type{T}) where {T<:PaddedAxis} = false

function ArrayInterface.unsafe_reconstruct(axis::PaddedAxis, data; kwargs...)
    return OffsetAxis(-first_pad(axis), data)
end

###
### pad methods
###
first_pad(p::Pads) = getfield(p, :first_pad)
first_pad(p::PadsParameter) = first_pad(pads(p))
first_pad(axis::PaddedAxis) = first_pad(pads(axis))

last_pad(p::Pads) = getfield(p, :last_pad)
last_pad(p::PadsParameter) = last_pad(pads(p))
last_pad(axis::PaddedAxis) = last_pad(pads(axis))

pads(axis::PadsParameter) = getfield(axis, :pads)
pads(axis::PaddedAxis) = getfield(axis, :pads)

#= has_pads =#
has_pads(x) = has_pads(typeof(x))
has_pads(::Type{T}) where {T} = static(false)
has_pads(::Type{T}) where {T<:AbstractAxis} = has_pads(parent_type(T))
has_pads(::Type{T}) where {T<:PaddedAxis} = static(true)
@inline function has_pads(::Type{T}) where {T<:AxisArray}
    return static(any(eachop_tuple(_has_pads, nstatic(Val(ndims)), axes_types(T))))
end
_has_pads(::Type{T}, i::StaticInt{I}) where {T,I} = has_pads(Static._get_tuple(T, i))

#= strip_pads - return offset and instance of x stripped of offset =#
function strip_pads(x::PaddedAxis)
    p = pads(x)
    return p, _grow_to_pads(p, parent(x))
end
strip_pads(x) = _strip_pads(has_pads(x), x)
function _strip_pads(::True, x)
    p, axis = strip_pads(parent(x))
    return p, initialize(x, param(x), axis)
end
_strip_pads(::False, x) = nothing, x

#= drop_pads(x) - return instance of x without an offset =#
drop_pads(x::Axis) = parent(x)
drop_pads(x::StructAxis) = parent(x)
drop_pads(x) = _drop_offset(has_offset(x), x)
_drop_pads(::True, x) =initialize(x, param(x), drop_offset(parent(x)))
_drop_pads(::False, x) = x
_drop_pads(::True, x::AxisArray) = _AxisArray(parent(x), map(drop_offset, axes(x)))

# when we take the pads of an indices and keys need to match their size
function _grow_to_pads(p::Pads, axis::SimpleAxis)
    return SimpleAxis(static(1):(static_length(axis) + first_pad(p) + last_pad(p)))
end
function _grow_to_pads(p::Pads, axis::KeyedAxis)
end


