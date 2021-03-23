# things that don't directly have anything to do with this package but are necessary

@generated unsafe_initialize(::Type{T}, args::Tuple) where {T} = Expr(:splatnew, :T, :args)

# Val wraps the number of axes to retain
naxes(A::AbstractArray, v::Val) = naxes(axes(A), v)
naxes(axs::Tuple, v::Val{N}) where {N} = _naxes(axs, N)
@inline function _naxes(axs::Tuple, i::Int)
    if i === 0
        return ()
    else
        return (first(axs), _naxes(tail(axs), i - 1)...)
    end
end

@inline function _naxes(axs::Tuple{}, i::Int)
    if i === 0
        return ()
    else
        return (SimpleAxis(1), _naxes((), i - 1)...)
    end
end

known_offset1(x) = known_offset1(typeof(x))
known_offset1(::Type{T}) where {T} = first(ArrayInterface.known_offsets(T))
@inline function offset1(x)
    o = known_offset1(x)
    if o === nothing
        return first(ArrayInterface.offsets(x))
    else
        return static(o)
    end
end

function assign_indices(axis, inds)
    if can_change_size(axis) && !((known_length(inds) === nothing) || known_length(inds) === known_length(axis))
        return unsafe_reconstruct(axis, inds)
    else
        return axis
    end
end

function throw_offset_error(@nospecialize(axis))
    throw("Cannot wrap axis $axis due to offset of $(first(axis))")
end

int(x::Integer) = Int(x)
int(x::StaticInt) = x

const DUnitRange = OptionallyStaticUnitRange{Int,Int}
const DOneTo = OptionallyStaticUnitRange{StaticInt{1},Int}

const StepSRange{F,S,L} = ArrayInterface.OptionallyStaticStepRange{StaticInt{F},StaticInt{S},StaticInt{L}}
const UnitSRange{F,L} = OptionallyStaticUnitRange{StaticInt{F},StaticInt{L}}
const SOneTo{L} = UnitSRange{1,L}

# TODO this should probably be in ArrayInterface.jl "dimensions.jl"
#=
    dims_indicators(cat_dims, array_dims) -> Tuple

This turns a tuple of dimensions passed to something like `reduce` into a tuple of
true/false indicators. If possible, values are preserved as `StaticBool` to help with
type stability.
=#
@inline function dims_indicators(x::Tuple, dims::Tuple)
    return (static_in(first(x), dims), dims_indicators(tail(x), dims)...)
end
dims_indicators(::Tuple{}, dims::Tuple) = ()
dims_indicators(::Tuple{}, dims::Integer) = ()
function dims_indicators(axs::Tuple, dims::Integer)
    return (static_in(first(axs), dims), dims_indicators(tail(axs), dims)...)
end
dims_indicators(axs::Tuple{Vararg{Any,N}}, ::Colon) where {N} = __ntuple(_->static(true), Val(N))

static_in(i::StaticInt{N}, dim::Int) where {N} = N === dim
static_in(i::StaticInt{N}, ::StaticInt{N}) where {N} = static(true)
static_in(i::StaticInt{N}, ::StaticInt) where {N} = static(false)
static_in(i::StaticInt{N}, ::Tuple{}) where {N} = static(false)
static_in(i::StaticInt{N}, dims::Tuple{StaticInt{N},Vararg{Any}}) where {N} = static(true)
@inline function static_in(i::StaticInt{N}, dims::Tuple{StaticInt,Vararg{Any}}) where {N}
    return static(false) | static_in(i, tail(dims))
end
@inline function static_in(i::StaticInt{N}, dims::Tuple{Int,Vararg{Any}}) where {N}
    # if any StaticInt match then we can preserve a static True
    return (first(dims) === N)  | static_in(i, tail(dims))
end

# if we could return on of the two values we need to ensure they they are both static for
# type stability, otherwise drop to dynamic
conform_dynamic(x::X, y::Y) where {X,Y} = _conform_static(is_static(Y), x)
_conform_dynamic(::True, x) = x
_conform_dynamic(::False, x) = dynamic(x)

###
### ERRORS
###
function check_axis_length(ks, inds)
    if length(ks) != length(inds)
        throw(DimensionMismatch(
            "keys and indices must have same length, got length(keys) = $(length(ks))" *
            " and length(indices) = $(length(inds)).")
        )
    end
    return nothing
end

function check_unique_keys(ks)
    if allunique(ks)
        return nothing
    else
        error("All keys must be unique")
    end
end
function check_offsets(ks, inds)
    if firstindex(inds) === firstindex(ks)
        return nothing
    else
        throw(ArgumentError("firstindex of $ks and $inds are not the same."))
    end
end

