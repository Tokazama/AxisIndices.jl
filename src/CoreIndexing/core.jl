
_maybe_tail(::Tuple{}) = ()
_maybe_tail(x::Tuple) = tail(x)

abstract type IndexingMarker{T} end

struct MarkIndices{T} <: IndexingMarker{T}
    arg::T
end

struct MarkKeys{T} <: IndexingMarker{T}
    arg::T
end

drop_marker(arg) = arg
drop_marker(arg::IndexingMarker) = drop_marker(arg.arg)
drop_marker(arg::CartesianIndex{1}) = first(arg.I)

"""
    as_indices(x)

Mark `x` as being an index.
"""
as_indices(x) = MarkIndices(x)
as_indices(x::MarkIndices) = x

"""
    as_indices(x)

Forces `arg` to refer to keys when indexing.
"""
as_keys(x) = MarkKeys(x)
as_keys(x::MarkKeys) = x

"""
    is_key([collection,] arg) -> Bool

Whether `arg` refers to a key of `axis`.
"""
is_key(arg) = is_key(IndexLinear(), typeof(arg))
is_key(collection, arg) = is_key(IndexStyle(collection), typeof(arg))
is_key(collection, ::Type{I}) where {I} = is_key(IndexStyle(collection), I)
is_key(::IndexStyle, ::Type{T}) where {T<:Colon} = false
is_key(::IndexStyle, ::Type{T}) where {T<:Integer} = false
is_key(::IndexStyle, ::Type{T}) where {X,T<:MarkIndices{X}} = false
is_key(::IndexStyle, ::Type{T}) where {X,T<:MarkKeys{X}} = true
is_key(S::IndexStyle, ::Type{T}) where {T<:AbstractArray} = is_key(S, eltype(T))
is_key(::IndexStyle, ::Type{T}) where {T} = true

@inline function get_target(axis, arg)
    if is_key(axis, arg)
        return keys(axis)
    else
        return eachindex(axis)
    end
end

#
#    to_indices(A, args)
#
function to_indices end

@propagate_inbounds to_indices(A, args::Tuple) = to_indices(A, axes(A), args)
@propagate_inbounds function to_indices(A, args::Tuple{Arg}) where {Arg}
    if argdims(Arg) > 1
        return to_indices(A, axes(A), args)
    else
        if ndims(A) === 1
            return (to_index(eachindex(A), first(args)),)
        else
            return to_indices(A, (eachindex(A),), args)
        end
    end
end
@propagate_inbounds function to_indices(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {Arg}
    if argdims(Arg) > 1
        axes_front, axes_tail = Base.IteratorsMD.split(axs, Val(argdims(Arg)))
        return (to_multi_index(axes_front, first(args)), to_indices(A, axes_tail, tail(args))...)
    else
        return (to_index(first(axs), first(args)), to_indices(A, tail(axs), tail(args))...)
    end
end
@propagate_inbounds function to_indices(A, axs::Tuple, args::Tuple{})
    @boundscheck if length(first(axs)) == 1
        throw(BoundsError(first(axs), ()))
    end
    return to_indices(A, tail(axs), args)
end
@propagate_inbounds function to_indices(A, ::Tuple{}, args::Tuple{Arg,Vararg{Any}}) where {Arg}
    return (to_index(OneTo(1), first(args)), to_indices(A, (), tail(args))...)
end
to_indices(A, axs::Tuple{}, args::Tuple{}) = ()

function to_multi_index(axs::Tuple, arg)
    @boundscheck if !Base.checkbounds_indices(Bool, axs, (arg,))
        throw(BoundsError(axs, arg))
    end
    return arg
end
 
"""
    to_index([::IndexStyle, ]axis, arg) -> index

Convert the argument `arg` that was originally passed to `getindex` for the dimension
corresponding to `axis` into a form for native indexing (`Int`, Vector{Int}, ect). New
axis types with unique behavior should use an `IndexStyle` trait:

```julia
to_index(axis::MyAxisType, arg) = to_index(IndexStyle(axis), axis, arg)
to_index(::MyIndexStyle, axis, arg) = ...
```
"""
@propagate_inbounds to_index(axis, arg) = to_index(IndexStyle(axis), axis, arg)
# Colons get converted to slices by `indices`
to_index(axis, arg::Colon) = indices(axis)
# used to drop dimensions
to_index(axis, arg::CartesianIndices{0}) = arg
@propagate_inbounds to_index(axis, arg::CartesianIndex{1}) = to_index(axis, first(arg.I))


@propagate_inbounds function to_index(::IndexLinear, axis, arg::Integer)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return Int(arg)
end
@propagate_inbounds function to_index(::IndexLinear, axis, arg::AbstractArray{Bool})
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return @inbounds(axis[arg])
end
@propagate_inbounds function to_index(::IndexLinear, axis, arg::AbstractArray)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end
to_index(::IndexLinear, axis, arg::Function) = findall(arg, axis)
@propagate_inbounds function to_index(S::IndexLinear, axis, arg::IndexingMarker)
    return to_index(S, axis, drop_marker(arg))
end
@propagate_inbounds function to_index(::IndexLinear, axis, arg::Union{<:Equal,Approx})
    idx = findfirst(arg, axis)
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, first(getargs(drop_marker(arg)))))
    end
    return Int(idx)
end

@propagate_inbounds function to_index(S::IndexStyle, axis, arg::CartesianIndex{1})
    return to_index(S, axis, first(arg.I))
end


"""
    IndexAxis

Index style for mapping keys to an array's parent indices.
"""
struct IndexAxis <: IndexStyle end

@propagate_inbounds function to_index(S::IndexAxis, axis, arg)
    if is_key(axis, arg)
        ks = to_index_keys(axis, drop_marker(arg))
        return @inbounds(to_index(parentindices(axis), ks))
    else
        return to_index(parentindices(axis), arg)
    end
end

@propagate_inbounds function to_index_keys(axis, arg::CartesianIndex{1})
    return to_index_keys(axis, first(arg.I))
end
to_index_keys(axis, arg::Function) = findall(arg, keys(axis))

@propagate_inbounds function to_index_keys(axis, arg)
    if arg isa keytype(axis)
        idx = findfirst(==(arg), keys(axis))
    else
        idx = findfirst(==(keytype(axis)(arg)), keys(axis))
    end
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(idx)
end

@propagate_inbounds function to_index_keys(axis, arg::Union{<:Equal,Approx})
    idx = findfirst(arg, keys(axis))
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(idx)
end

@propagate_inbounds function to_index_keys(axis, arg::AbstractVector)
    return map(arg_i -> to_index_keys(axis, arg_i), arg)
    #=
    inds = Vector{Int}(undef, length(arg))
    ks = keys(axis)
    i = 1
    for arg_i in arg
        idx = to_index_key(axis, arg_i)
        @inbounds(setindex!(inds, idx, i))
        i += 1
    end
    return inds
    =#
end

@propagate_inbounds function to_index_keys(axis, arg::AbstractRange)
    if eltype(arg) <: keytype(axis)
        inds = find_all(in(arg), keys(axis))
    else
        inds = find_all(in(AbstractRange{keytype(axis)}(arg)), keys(axis))
    end
    # if `inds` is same length as `arg` then all of `arg` was found and is inbounds
    @boundscheck if length(inds) != length(arg)
        throw(BoundsError(axis, arg))
    end
    return inds
end

"""
    IndexOffsetStyle

Index style where the user provided index must be offset before passing to internal
functions that return stored value.
"""
abstract type IndexOffsetStyle <: IndexStyle end

struct IndexOffset <: IndexOffsetStyle end

"""
    IndexCentered

Index style where the indices are centered around zero.
"""
struct IndexCentered <: IndexOffsetStyle end

# TODO document IndexIdentity
struct IndexIdentity <: IndexOffsetStyle end

@propagate_inbounds function to_index(S::IndexOffsetStyle, axis, arg::Integer)
    return to_index(parentindices(axis), arg - offsets(axis))
end

@propagate_inbounds function to_index(S::IndexOffsetStyle, axis, arg::AbstractArray{I}) where {I<:Integer}
    return to_index(parentindices(axis), arg .- offsets(axis))
end

"""
    IndexPaddedStyle

Index style that pads a set number of indices on each side of an axis.
"""
abstract type IndexPaddedStyle <: IndexOffsetStyle end

"""
    IndexFillPad{F}(fxn::F)

Index style that pads a set number of indices on each side of an axis.
`fxn`(eltype(A))` returns the padded value.

"""
struct IndexFillPad{F} <: IndexPaddedStyle
    fxn::F
end

const IndexZeroPad = IndexFillPad(zero)

const IndexOnePad = IndexFillPad(oneunit)

(p::IndexFillPad)(x) = p.fxn(eltype(x))

"""
    SymmetricPad <: IndexPaddedStyle

The border elements reflect relative to a position between elements. That is, the
border pixel is omitted when mirroring.

```math
\\boxed{
\\begin{array}{l|c|r}
  e\\, d\\, c\\, b  &  a \\, b \\, c \\, d \\, e \\, f & e \\, d \\, c \\, b
\\end{array}
}
```
"""
struct SymmetricPad <: IndexPaddedStyle end

to_first_pad(::SymmetricPad, inds, arg) = Int(2first(inds) - arg)
to_last_pad(::SymmetricPad, inds, arg) = Int(2last(inds) - arg)

"""
    ReplicatePad

The border elements extend beyond the image boundaries.

```math
\\boxed{
\\begin{array}{l|c|r}
  a\\, a\\, a\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, f \\, f \\, f
\\end{array}
}
```
"""
struct ReplicatePad <: IndexPaddedStyle end

to_first_pad(::ReplicatePad, inds, arg) = Int(firstindex(inds))
to_last_pad(::ReplicatePad, inds, arg) = Int(lastindex(inds))

"""
    CircularPad

The border elements wrap around. For instance, indexing beyond the left border
returns values starting from the right border.

```math
\\boxed{
\\begin{array}{l|c|r}
  c\\, d\\, e\\, f  &  a \\, b \\, c \\, d \\, e \\, f & a \\, b \\, c \\, d
\\end{array}
}
```

"""
struct CircularPad <: IndexPaddedStyle end

to_first_pad(::CircularPad, inds, arg) = Int(last(inds) - (firstindex(inds) - (arg - 1)))
to_last_pad(::CircularPad, inds, arg) = Int(first(inds) + (lastindex(inds) - (arg - 1)))

"""
    ReflectPad

The border elements reflect relative to the edge itself.

```math
\\boxed{
\\begin{array}{l|c|r}
  d\\, c\\, b\\, a  &  a \\, b \\, c \\, d \\, e \\, f & f \\, e \\, d \\, c
\\end{array}
}
```
"""
struct ReflectPad <: IndexPaddedStyle end

to_first_pad(::ReflectPad, inds, arg) = Int(first(inds) + (last(inds) - (arg - 1)))
to_last_pad(::ReflectPad, inds, arg) = Int(last(inds) - (first(inds) - (arg - 1)))

@propagate_inbounds function to_index_element(::IndexPaddedStyle, axis, arg::Function)
    idx = findfirst(arg, axis)
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, first(getargs(drop_marker(arg)))))
    end
    return @inbounds(to_index(axis, idx))
end

@propagate_inbounds function to_index(S::IndexPaddedStyle, axis, arg::AbstractArray{I}) where {I<:Integer}
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return as_keys(arg)
end

@propagate_inbounds function to_index(S::IndexPaddedStyle, axis, arg::Integer)
    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end

    pinds = parentindices(axis)
    if first(pinds) > arg
        return to_first_pad(S, axis, arg)
    elseif last(pinds) < arg
        return to_last_pad(S, axis, arg)
    else
        return Int(arg)
    end
end

"""
    to_axes(A, args, inds)
    to_axes(A, old_axes, args, inds) -> new_axes

Construct new axes given the index arguments `args` and the corresponding `inds`
constructed after `to_indices(A, old_axes, args) -> inds`
"""
@inline to_axes(A, args, inds) = to_axes(A, axes(A), args, inds)
to_axes(A, ::Tuple{Ax,Vararg{Any}}, ::Tuple{Arg,Vararg{Any}}, ::Tuple{}) where {Ax,Arg} = ()
to_axes(A, ::Tuple{}, ::Tuple{}, ::Tuple{}) = ()
@propagate_inbounds function to_axes(A, axs::Tuple{Ax,Vararg{Any}}, args::Tuple{Arg,Vararg{Any}}, inds::Tuple) where {Ax,Arg}
    if argdims(Arg) === 0
        # drop this dimension
        return to_axes(A, tail(axs), tail(args), tail(inds))
    elseif argdims(Arg) === 1
        return (to_axis(first(axs), first(args), first(inds)), to_axes(A, tail(axs), tail(args), tail(inds))...)
    else
        # Only multidimensional AbstractArray{Bool} and AbstractVector{CartesianIndex{N}}
        # make it to this point. They collapse several dimensions into one.
        axes_front, axes_tail = Base.IteratorsMD.split(axs, Val(argdims(Arg)))
        return (to_axis(axes_front, first(args), first(inds)), to_axes(A, axes_tail, tail(args), tail(inds))...)
    end
end

"""
    to_axis(old_axis, arg, index) -> new_axis

Construct an `new_axis` for a newly constructed array that corresponds to the
previously executed `to_index(old_axis, arg) -> index`.
"""
to_axis(axis, arg, inds) = to_axis(IndexStyle(axis), axis, arg, inds)
to_axis(::IndexStyle, axis, arg, inds) = SimpleAxis(static_length(inds))
# TODO Do we need a special pass for handling `to_axis(axs::Tuple, arg, inds)` where `axs`
# are the axes being collapsed?
to_axis(axs::Tuple, arg, inds) = SimpleAxis(static_length(inds))

"""
    argdims(::Type{T}) -> Int

Whats the dimensionality of the indexing argument of type `T`?
"""
argdims(x) = argdims(typeof(x))
# single elements initially map to 1 dimension but are that dimension is subsequently dropped.
argdims(::Type{T}) where {T} = 0
argdims(::Type{T}) where {T<:Colon} = 1
argdims(::Type{T}) where {T<:AbstractArray} = ndims(T)
argdims(::Type{T}) where {N,T<:CartesianIndex{N}} = N
argdims(::Type{T}) where {N,T<:AbstractArray{CartesianIndex{N}}} = N
argdims(::Type{T}) where {N,T<:AbstractArray{<:Any,N}} = N
argdims(::Type{T}) where {N,T<:LogicalIndex{<:Any,<:AbstractArray{Bool,N}}} = N

"""
    is_element([collection, ] arg) -> Bool

Whether `arg` maps to a single element from `collection`.
"""
is_element(arg) = is_element(IndexLinear(), typeof(arg))
is_element(collection, arg) = is_element(IndexStyle(collection), typeof(arg))
is_element(collection, ::Type{I}) where {I} = is_element(IndexStyle(collection), I)
is_element(::IndexStyle, ::Type{T}) where {T} = false
is_element(::IndexStyle, ::Type{T}) where {T<:Number} = true
is_element(::IndexStyle, ::Type{T}) where {T<:CartesianIndex} = true
is_element(::IndexStyle, ::Type{T}) where {T<:Symbol} = true
is_element(::IndexStyle, ::Type{T}) where {T<:AbstractChar} = true
is_element(::IndexStyle, ::Type{T}) where {T<:AbstractString} = true
is_element(::IndexStyle, ::Type{T}) where {T<:Equal} = true
is_element(::IndexStyle, ::Type{T}) where {T<:Approx} = true
is_element(S::IndexStyle, ::Type{T}) where {X,T<:IndexingMarker{X}} = is_element(S, X)
is_element(::IndexStyle, ::Type{<:IndexPaddedStyle}) = true

can_flatten(::Type{T}) where {T} = false
can_flatten(::Type{T}) where {I<:CartesianIndex,T<:AbstractArray{I}} = false
can_flatten(::Type{T}) where {T<: CartesianIndices} = true
can_flatten(::Type{T}) where {N,T<:AbstractArray{<:Any,N}} = N > 1
can_flatten(::Type{T}) where {N,T<:CartesianIndex{N}} = true

should_flatten(x) = should_flatten(typeof(x))
@generated function should_flatten(::Type{T}) where {T<:Tuple}
    for i in T.parameters
        can_flatten(i) && return true
    end
    return false
end

# `flatten_args` handles the obnoxious indexing arguments passed to `getindex` that
# don't correspond to a single dimension (CartesianIndex, CartesianIndices,
# AbstractArray{Bool}). Splitting this up from `to_indices` has two advantages:
#
# 1. It greatly simplifies `to_indices` so that things like ambiguity errors aren't as
#    likely to occur. It should only occure at the top level of any given call to getindex
#    so it ensures that most internal multidim indexing is less complicated.
# 2. When `to_axes` runs back over the arguments to construct the axes of the new
#    collection all the the indices and args should match up so that less time is
#    wasted on `IteratorsMD.split`.
flatten_args(A, args::Tuple) = flatten_args(A, axes(A), args)
@inline function flatten_args(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {Arg}
    return (first(args), flatten_args(A, _maybe_tail(axs), tail(args))...)
end
@inline function flatten_args(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {N,Arg<:CartesianIndex{N}}
    _, axes_tail = Base.IteratorsMD.split(axs, Val(N))
    return (first(args).I..., flatten_args(A, _maybe_tail(axs), tail(args))...)
end
@inline function flatten_args(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {N,Arg<:CartesianIndices{0}}
    return (first(args), flatten_args(A, tail(axs), tail(args))...)
end
@inline function flatten_args(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {N,Arg<:CartesianIndices{N}}
    _, axes_tail = Base.IteratorsMD.split(axs, Val(N))
    return (first(args)..., flatten_args(A, axes_tail, tail(args))...)
end
@inline function flatten_args(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {N,Arg<:AbstractArray{<:Any,N}}
    _, axes_tail = Base.IteratorsMD.split(axs, Val(N))
    return (first(args), flatten_args(A, axes_tail, tail(args))...)
end
@inline function flatten_args(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {N,Arg<:AbstractArray{Bool,N}}
    axes_front, axes_tail = Base.IteratorsMD.split(axs, Val(N))
    if length(args) === 1
        if IndexStyle(A) isa IndexLinear
            return (LogicalIndex{Int}(first(args)),)
        else
            return (LogicalIndex(first(args)),)
        end
    else
        return (LogicalIndex(first(args)), flatten_args(A, axes_tail, tail(args)))
    end
end
flatten_args(A, axs::Tuple, args::Tuple{}) = ()

###
### getindex methods
###
"""
    UnsafeIndex <: Function

`UnsafeIndex` controls how indices that have been bounds checked and converted to
native axes' indices are used to return the stored values of an array. For example,
if the indices at each dimension are single integers than `UnsafeIndex(inds)` returns
`UnsafeElement()`. Conversely, if any of the indices are vectors then
`UnsafeCollection()` is returned, indicating that a new array needs to be
reconstructed.
"""
abstract type UnsafeIndex <: Function end

struct UnsafeElement <: UnsafeIndex end
const unsafe_element = UnsafeElement()

struct UnsafeCollection <: UnsafeIndex end
const unsafe_collection = UnsafeCollection()

struct UnsafePadElement <: UnsafeIndex end
const unsafe_pad_element = UnsafePadElement()

struct UnsafePadCollection <: UnsafeIndex end
const unsafe_pad_collection = UnsafePadCollection()

# 1-arg
UnsafeIndex(x) = UnsafeIndex(typeof(x))
UnsafeIndex(x::UnsafeIndex) = x
UnsafeIndex(::Type{T}) where {T<:Integer} = unsafe_element
UnsafeIndex(::Type{T}) where {T<:AbstractArray} = unsafe_collection

# 2-arg
UnsafeIndex(x::UnsafeIndex, y::UnsafeElement) = x
UnsafeIndex(x::UnsafeElement, y::UnsafeIndex) = y
UnsafeIndex(x::UnsafeElement, y::UnsafeElement) = x
UnsafeIndex(x::UnsafePadElement, y::UnsafeIndex) = x
UnsafeIndex(x::UnsafeIndex, y::UnsafePadElement) = y
UnsafeIndex(x::UnsafePadElement, y::UnsafePadElement) = x
UnsafeIndex(x::UnsafePadCollection, y::UnsafePadCollection) = x
UnsafeIndex(x::UnsafeIndex, y::UnsafePadCollection) = y
UnsafeIndex(x::UnsafePadCollection, y::UnsafeIndex) = x
UnsafeIndex(x::UnsafePadElement, y::UnsafePadCollection) = y
UnsafeIndex(x::UnsafePadCollection, y::UnsafePadElement) = x
UnsafeIndex(x::UnsafePadElement, y::UnsafeElement) = x
UnsafeIndex(x::UnsafeElement, y::UnsafePadElement) = y
UnsafeIndex(x::UnsafePadCollection, y::UnsafeElement) = x
UnsafeIndex(x::UnsafeElement, y::UnsafePadCollection) = y
UnsafeIndex(x::UnsafeCollection, y::UnsafeCollection) = x

# tuple
UnsafeIndex(x::Tuple{I}) where {I} = UnsafeIndex(I)
@inline function UnsafeIndex(x::Tuple{I,Vararg{Any}}) where {I}
    return UnsafeIndex(UnsafeIndex(I), UnsafeIndex(tail(x)))
end

unsafe_getindex(A, args, inds) = unsafe_getindex(UnsafeIndex(inds), A, args, inds)
unsafe_getindex(::UnsafeElement, A, args, inds) = unsafe_get_element(A, inds)
unsafe_getindex(::UnsafeCollection, A, args, inds) = unsafe_get_collection(A, args, inds)

# These methods need to be explicitly defined for some array types
function unsafe_get_element(a::A, inds::Tuple) where {A}
    if parent_type(A) <: A
        error("`unsafe_get_element not defined for type $A`")
    else
        return @inbounds(getindex(parent(a), inds...))
    end
end

function unsafe_get_collection(A, args, inds)
    return AxisArray(@inbounds(getindex(parent(A), inds...)), to_axes(A, args, inds))
end

