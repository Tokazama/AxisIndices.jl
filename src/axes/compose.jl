
function _dim_length_error(@nospecialize(x), @nospecialize(y))
    throw(DimensionMismatch(
        "keys and indices must have same length, got length(keys) = $(x)" *
        " and length(indices) = $(y).")
    )
end

as_axes(x::Tuple) = map(as_axis, x)
function as_axes(::Tuple{}, x::AbstractVector)
    if can_change_size(x)
        return (SimpleAxis(DynamicAxis(length(x))),)
    else
        return (SimpleAxis(static_length(x)),)
    end
end
# FIXME we shouldn't initialize the DynamicAxis if the parameter is static
as_axes(ps::Tuple{Any}, x::AbstractVector) = _maybe_dynamic_axes(first(ps), x)

_maybe_dynamic_axes(p::StaticInt, x) = as_axis(as_axis(p), indices(x))
function _maybe_dynamic_axes(::Nothing, x)
    if can_change_size(x)
        return (SimpleAxis(DynamicAxis(length(x))),)
    else
        return (SimpleAxis(static_length(x)),)
    end
end

as_axes(::Tuple{}, x::AbstractArray) = map(SimpleAxis, ArrayInterface.size(x))
as_axes(ps::Tuple{Vararg{Any,N}}, x::AbstractArray{Any,N}) where {N} = as_axes(ps, axes(x))
function as_axes(ps::Tuple, x::AbstractArray)
    throw(DimensionMismatch("Number of axis arguments provided ($(length(ps))) does " *
                            "not match number of parent axes ($(ndims(x)))."))
end
@inline function as_axes(ps::Tuple{Vararg{Any,N}}, as::Tuple{Vararg{Any,N}}) where {N}
    return (as_axis(first(ps), first(as)), as_axes(tail(ps), tail(as))...)
end
as_axes(::Tuple{}, ::Tuple) = ()

###
### as_axis
###
#=

1. `as_axis(param)`
2. `as_axis(param, axis)`: try to convert `param` to some subtype of `AxisParameter`.
  This is primarily used to convert axis arguments passed to `AxisArray` into their obvious
  `AxisParameter` counterparts. This is useful for saving users from verbose code (e.g.,
  explicitly calling `AxisKeys(keys)` for each axis), but means we are guessing what the
  user wants. Therefore, this application is limited to construction of `AxisArray`.
  - `Integer`
=#
## initialize(p) ##
as_axis(stop::Integer) = initialize(SimpleAxis, static(1):stop)
as_axis(axis::Axis) = axis
function as_axis(x::AbstractUnitRange{Int})
    if known_first(x) === 1
        return initialize(SimpleAxis, x)
    else
        return initialize(AxisOffset(_sub1(static_first(x))), static(1):static_length(x))
    end
end
function as_axis(x::AbstractVector{T}) where {T}
    return unsafe_initialize(AxisKeys(x), initialize(SimpleAxis, indices(x)))
end

## initialize(p, a) ##
# function as_axis(p::StaticInt{N}, axis::DynamicAxis) where {N}
#    N === length(axis) || _dim_length_error(N, length(axis))
# end
as_axis(::Nothing, axis) = as_axis(axis)
function as_axis(p::Integer, axis)
    Int(p) === length(axis) || _dim_length_error(p, length(axis))
    return as_axis(p)
end
function as_axis(p::AbstractVector, axis)
    if known_step(p) === 1
        length(p) === length(axis) || _dim_length_error(length(p), length(axis))
        if known_first(p) === 1
            return as_axis(p)
        else
            return initialize(AxisOffset(_sub1(static_first(x))), axis)
        end
    else
        return AxisKeys(p)(axis)
    end
end
as_axis(p::AxisParameter, axis) = initialize(p, axis)

#=
    initialize(param, axis) -> Axis


Binds a parameter to an axis, performing the appropriate checks. These checks may be
bypassed by directly calling `unsafe_initialize`.

`initialize` may be called recursively up to 2 times.
1. `initialize(param::AxisParameter, axis)` : With the exception `SimpleParam`, `axis` should
  always be an instance of `Axis`. Therefore we need to convert `axis`.
2. `initialize(param::AxisParameter, axis::Axis)`: This is the final where we ensure `axis`
  is compatible with `param` before binding the two. Some of the checks here include:
  - `AxisKeys` : ensure there aren't any other keys (other `AxisKeys` or `AxisStruct`)
    nested within `axis`. The keys and length of `axis` are also checked for the same length.
  - `AxisStruct{T}` : essentially the same checks as `AxisKeys` but we also ensure that `T`
    is concrete type.
  - `AxisOffset`: if `axis` contains another instance of `AxisOffset` or `AxisOrigin` then
    the original offsets are stripped of and consolidated in the new parameter.
  - `AxisOrigin`:  if `axis` contains another instance of `AxisOffset` or `AxisOrigin` then
    the original offsets are removed entirely.
  - `AxisName`: if `axis` has any names they are removed.

!!! warning

    This method is not considered part of the public API and may change in the future.

=#
initialize(p::AxisParameter, a) = initialize(p, as_axis(a))
initialize(p::AxisParameter, a::Axis) = unsafe_initialize(p, a)
# ComposedFunction is assumed to hold chained AxisParameter
initialize(p::ComposedFunction, a) = p(a)
initialize(::SimpleParam, a::DynamicAxis) = unsafe_initialize(SimpleAxis, a)
initialize(::SimpleParam, a::OptionallyStaticUnitRange) = unsafe_initialize(SimpleAxis, a)
initialize(::SimpleParam, a::IdentityUnitRange) = initialize(SimpleAxis, a.indices)
initialize(::SimpleParam, a) = initialize(SimpleAxis, OptionallyStaticUnitRange(a))

initialize(p::AxisName, a::Axis) = unsafe_initialize(p, unname(a))
initialize(p::AxisOrigin, axis::Axis) = unsafe_initialize(p, drop_offset(axis))
function initialize(p::AxisKeys, axis::Axis)
    length(param(p)) === length(axis) || _dim_length_error(length(param(p)), length(axis))
    return unsafe_initialize(p, drop_keys(axis))
end
function initialize(p::AxisStruct{T}, axis::Axis) where {T}
    typeof(T) <: DataType || throw(ArgumentError("Type must be have all field fully paramterized, got $T"))
    return unsafe_initialize(p, drop_keys(axis))
end

initialize(p::AxisOffset, a::Axis) = _offset_axis(has_offset(x), p, a)
function _offset_axis(::True, p, a)
    o2, paxis = strip_offset(a)
    return unsafe_initialize(AxisOffset(_sub1(param(p) + o2)), paxis)
end
_offset_axis(::False, p, x) = unsafe_initialize(p, x)


function initialize(p::SymmetricPads, axis::Axis)
    len = static_length(axis)
    if first_pad(p) > len
        throw(ArgumentError("cannot have pad that is larger than length of parent indices +1 for SymmetricPads, " *
                            "first pad is $(first_pad(p)) and indices are of length $len"))
    elseif last_pad(p) > len
        throw(ArgumentError("cannot have pad that is larger than length of parent indices +1 for SymmetricPads, " *
                            "first pad is $(last_pad(p)) and indices are of length $len"))
    else
        return unsafe_initialize(p, axis)
    end
end
function initialize(p::CircularPads, axis::Axis)
    len = static_length(axis)
    if first_pad(p) > len
        throw(ArgumentError("cannot have pad of size $(first_pad(p)) and indices of length $len for CircularPads"))
    elseif last_pad(p) > len
        throw(ArgumentError("cannot have pad of size $(last_pad(p)) and indices of length $len for CircularPads"))
    else
        return unsafe_initialize(p, axis)
    end
end
function initialize(p::ReflectPads, axis::Axis)
    len = static_length(axis)
    if first_pad(p) > len
        throw(ArgumentError("cannot have pad of size $(first_pad(p)) and indices of length $len for ReflectPads"))
    elseif last_pad(p) > len 
        throw(ArgumentError("cannot have pad of size $(first_pad(p)) and indices of length $len for ReflectPads"))
    else
        return unsafe_initialize(p, axis)
    end
end

unsafe_initialize(p::AxisParameter, a::Axis) = _Axis(p, a)
unsafe_initialize(::SimpleParam, a::Axis{SimpleParam}) = a
unsafe_initialize(::SimpleParam, a::AbstractUnitRange) = SimpleAxis(OptionallyStaticUnitRange(a))
unsafe_initialize(::SimpleParam, a::OptionallyStaticUnitRange) = _Axis(SimpleAxis, a)
unsafe_initialize(::SimpleParam, a::DynamicAxis) = _Axis(SimpleAxis, a)

(p::AxisParameter)(stop::Integer) = p(static(1):stop)
(p::AxisParameter)(start::Integer, stop::Integer) = p(OptionallyStaticUnitRange(start, stop))
(p::AxisParameter)(x::AxisParameter) = ComposedFunction(p, x)
(p::AxisParameter)(x::ComposedFunction) = ComposedFunction(p, x)
function (p::AxisParameter)(collection::AbstractArray)
    if known_step(collection) === 1
        return initialize(p, collection)
    else
        return AxisArray(collection, ntuple(_ -> p, Val(ndims(collection))))
    end
end

