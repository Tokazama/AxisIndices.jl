
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{I<:Integer,Inds} <: AbstractUnitRange{I} end

Base.keytype(::Type{T}) where {I,T<:AbstractAxis{I}} = I
Base.keys(axis::AbstractAxis) = eachindex(axis)

"""
    AbstractOffsetAxis{I,Inds}

Supertype for axes that begin indexing offset from one. All subtypes of `AbstractOffsetAxis`
use the keys for indexing and only convert to the underlying indices when
`to_index(::OffsetAxis, ::Integer)` is called (i.e. when indexing the an array
with an `AbstractOffsetAxis`. See [`OffsetAxis`](@ref), [`CenteredAxis`](@ref),
and [`IdentityAxis`](@ref) for more details and examples.
"""
abstract type AbstractOffsetAxis{I,Inds,F} <: AbstractAxis{I,Inds} end

"""
    IndexAxis

Index style for mapping keys to an array's parent indices.
"""
struct IndexAxis <: IndexStyle end

Base.valtype(::Type{T}) where {I,T<:AbstractAxis{I}} = I

Base.IndexStyle(::Type{T}) where {T<:AbstractAxis} = IndexAxis()

Base.parent(axis::AbstractAxis) = getfield(axis, :parent)

ArrayInterface.parent_type(::Type{T}) where {I,Inds,T<:AbstractAxis{I,Inds}} = Inds

Base.eachindex(axis::AbstractAxis) = static_first(axis):static_last(axis)

for f in (:(==), :isequal)
    @eval begin
        Base.$(f)(x::AbstractAxis, y::AbstractAxis) = $f(eachindex(x), eachindex(y))
        Base.$(f)(x::AbstractArray, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::AbstractArray) = $f(eachindex(x), y)
        Base.$(f)(x::AbstractRange, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::AbstractRange) = $f(eachindex(x), y)
        Base.$(f)(x::StaticRanges.GapRange, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::StaticRanges.GapRange) = $f(eachindex(x), y)
        Base.$(f)(x::OrdinalRange, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::OrdinalRange) = $f(eachindex(x), y)
    end
end

Base.allunique(a::AbstractAxis) = true

Base.empty!(axis::AbstractAxis) = set_length!(axis, 0)

@inline Base.in(x::Integer, axis::AbstractAxis) = !(x < first(axis) || x > last(axis))
@inline Base.length(axis::AbstractAxis) = length(parent(axis))

Base.pairs(axis::AbstractAxis) = Base.Iterators.Pairs(a, keys(axis))

# This is required for performing `similar` on arrays
Base.to_shape(axis::AbstractAxis) = length(axis)

Base.haskey(axis::AbstractAxis, key) = key in keys(axis)

@inline Base.axes(axis::AbstractAxis) = (Base.axes1(axis),)

@inline Base.axes1(axis::AbstractAxis) = copy(axis)

@inline Base.unsafe_indices(axis::AbstractAxis) = (axis,)

Base.isempty(axis::AbstractAxis) = isempty(parent(axis))
Base.empty(axis::AbstractAxis) = unsafe_reconstruct(axis, _empty(parent(axis)))
_empty(axis::AbstractAxis) = empty(axis)
_empty(axis::AbstractUnitRange) = One():Zero()

Base.sum(axis::AbstractAxis) = sum(eachindex(axis))

function ArrayInterface.can_change_size(::Type{T}) where {T<:AbstractAxis}
    return can_change_size(parent_type(T))
end

Base.collect(a::AbstractAxis) = collect(eachindex(a))

Base.step(axis::AbstractAxis) = oneunit(eltype(axis))

Base.step_hp(axis::AbstractAxis) = 1

Base.size(axis::AbstractAxis) = (length(axis),)

Base.:-(axis::AbstractAxis) = maybe_unsafe_reconstruct(axis, -eachindex(axis))

function Base.:+(r::AbstractAxis, s::AbstractAxis)
    indsr = axes(r, 1)
    if indsr == axes(s, 1)
        data = eachindex(r) + eachindex(s)
        axs = (unsafe_reconstruct(r, eachindex(data); keys=keys(data)),)
        return  AxisArray{eltype(data),ndims(data),typeof(data),typeof(axs)}(data, axs)
    else
        throw(DimensionMismatch("axes $indsr and $(axes(s, 1)) do not match"))
    end
end
function Base.:-(r::AbstractAxis, s::AbstractAxis)
    indsr = axes(r, 1)
    if indsr == axes(s, 1)
        data = eachindex(r) - eachindex(s)
        axs = (unsafe_reconstruct(r, eachindex(data); keys=keys(data)),)
        return  AxisArray{eltype(data),ndims(data),typeof(data),typeof(axs)}(data, axs)
    else
        throw(DimensionMismatch("axes $indsr and $(axes(s, 1)) do not match"))
    end
end

Base.UnitRange(axis::AbstractAxis) = UnitRange(eachindex(axis))
function Base.AbstractUnitRange{T}(axis::AbstractAxis) where {T<:Integer}
    if eltype(axis) <: T && !can_change_size(axis)
        return axis
    else
        return unsafe_reconstruct(axis, AbstractUnitRange{T}(parent(axis)); keys=keys(axis))
    end
end

Base.pop!(axis::AbstractAxis) = pop!(parent(axis))
Base.popfirst!(axis::AbstractAxis) = popfirst!(parent(axis))

# TODO check for existing key first
function push_key!(axis::AbstractAxis, key)
    grow_last!(parent(axis), 1)
    return nothing
end

function pushfirst_axis!(axis::AbstractAxis, key)
    grow_last!(parent(axis), 1)
    return nothing
end

function popfirst_axis!(axis::AbstractAxis)
    shrink_last!(parent(axis), 1)
    return nothing
end

Base.lastindex(a::AbstractAxis) = last(a)
Base.last(axis::AbstractAxis) = last(parent(axis))
Base.last(axis::AbstractOffsetAxis) = last(parent(axis)) + static_offset(axis)

ArrayInterface.known_last(::Type{T}) where {T<:AbstractAxis} = known_last(parent_type(T))
@inline function ArrayInterface.known_last(::Type{T}) where {T<:AbstractOffsetAxis}
    if known_last(parent_type(T)) === nothing || known_offset(T) === nothing
        return nothing
    else
        return known_last(parent_type(T)) + known_offset(T)
    end
end

###
### first
###
Base.firstindex(axis::AbstractAxis) = first(axis)
Base.first(axis::AbstractAxis) = first(parent(axis))
Base.first(axis::AbstractOffsetAxis) = first(parent(axis)) + static_offset(axis)

ArrayInterface.known_first(::Type{T}) where {T<:AbstractAxis} = known_first(parent_type(T))
@inline function ArrayInterface.known_first(::Type{T}) where {T<:AbstractOffsetAxis}
    if known_first(parent_type(T)) === nothing || known_offset(T) === nothing
        return nothing
    else
        return known_first(parent_type(T)) + known_offset(T)
    end
end

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function reverse_keys(axis::AbstractAxis, newinds::AbstractUnitRange)
    return Axis(reverse(keys(axis)), newinds; checks=NoChecks)
end

###
### to_index
###
@propagate_inbounds ArrayInterface.to_index(::IndexAxis, axis, arg) = _to_index(axis, arg)
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Integer)
    @boundscheck checkbounds(axis, arg)
    return Int(arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{Bool})
    return to_index(eachindex(axis), arg)
end
@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::AbstractArray{I}) where {I<:Integer}
    return to_index(eachindex(axis), arg)
end
ArrayInterface.to_index(::IndexAxis, axis, ::Colon) = indices(axis)
@propagate_inbounds function ArrayInterface.to_index(
    ::IndexAxis,
    axis,
    arg::AbstractUnitRange{I}
) where I<:Integer

    @boundscheck if !checkindex(Bool, axis, arg)
        throw(BoundsError(axis, arg))
    end
    return AbstractUnitRange{Int}(arg)
end
@propagate_inbounds function _to_index(axis, arg::CartesianIndex)
    @boundscheck checkbounds(axis, arg)
    return arg
end
@propagate_inbounds function _to_index(axis, arg)
    if arg isa keytype(axis)
        idx = find_first(==(arg), keys(axis))
    else
        idx = find_first(==(keytype(axis)(arg)), keys(axis))
    end
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(@inbounds(indices(axis)[idx]))
end

@propagate_inbounds function _to_index(axis, arg::Fix2)
    return @inbounds(eachindex(axis)[find_all(arg, keys(axis))])
end

@propagate_inbounds function _to_index(axis, arg::Union{<:Equal,Approx})
    idx = findfirst(arg, keys(axis))
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(@inbounds(eachindex(axis)[idx]))
end

@propagate_inbounds function _to_index(axis, arg::AbstractArray)
    return map(arg_i -> _to_index(axis, arg_i), arg)
end

@propagate_inbounds function _to_index(axis, arg::AbstractRange)
    if eltype(arg) <: keytype(axis)
        inds = find_all(in(arg), keys(axis))
    else
        inds = find_all(in(AbstractRange{keytype(axis)}(arg)), keys(axis))
    end
    # if `inds` is same length as `arg` then all of `arg` was found and is inbounds
    @boundscheck if length(inds) != length(arg)
        throw(BoundsError(axis, arg))
    end
    return @inbounds(eachindex(axis)[idx])
end

###
### maybe_unsafe_reconstruct
###
maybe_unsafe_reconstruct(axis, inds::Integer; kwargs...) = eltype(axis)(inds)
function maybe_unsafe_reconstruct(axis, inds::AbstractArray; keys=nothing)
    if known_step(inds) === 1 && eltype(inds) <: Integer
        return unsafe_reconstruct(axis, inds; keys=keys)
    else
        axs = (unsafe_reconstruct(axis, eachindex(inds)),)
        return AxisArray{eltype(inds),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
    end
end
function maybe_unsafe_reconstruct(axis::AbstractOffsetAxis, inds::AbstractArray; keys=nothing) where {I<:Integer}
    if known_step(inds) === 1 && eltype(inds) <: Integer
        f = offsets(axis, 1)
        new_inds = (static_first(inds) - f):(static_last(inds) - f)
        if keys === nothing
            return unsafe_reconstruct(axis, new_inds; keys=inds)
        else
            return unsafe_reconstruct(axis, new_inds; keys=keys)
        end
    else
        axs = (unsafe_reconstruct(axis, eachindex(inds)),)
        return AxisArray{eltype(inds),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
    end
end

###
### getindex
###
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::Integer)
    @boundscheck checkbounds(axis, arg)
    return eltype(axis)(arg)
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    return unsafe_reconstruct(axis, apply_offset(axis, arg); keys=arg)
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    return maybe_unsafe_reconstruct(axis, StepRange{eltype(axis),eltype(axis)}(arg))
end

Base.getindex(axis::AbstractAxis, ::Colon) = copy(axis)
Base.getindex(axis::AbstractAxis, ::Ellipsis) = copy(axis)
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    return maybe_unsafe_reconstruct(axis, _to_index(axis, arg))
end

###
### checkindex
###
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg)
    if is_key(axis, arg)
        return arg in keys(axis)
    else
        return arg in eachindex(axis)
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Interval) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Colon) = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Slice) = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractArray) 
    if is_key(axis, arg)
        return length(find_all_in(arg, keys(axis))) == length(arg)
    else
        return checkindex(Bool, eachindex(axis), arg)
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::AbstractArray{Bool}) = false
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractVector{Bool})
    return checkindex(Bool, eachindex(axis), arg)
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Real)
    if is_key(axis, arg)
        return in(arg, keys(axis))
    else
        return in(arg, eachindex(axis))
    end
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Union{<:Equal,<:Approx})
    return !(find_first(arg, keys(axis)) === nothing)
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::AbstractRange{T}) where {T}
    if is_key(axis, arg)
        return length(find_all_in(arg, keys(axis))) == length(axis)
    else
        return checkindex(Bool, eachindex(axis), arg)
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, ::Fix2) = true
@inline function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::LogicalIndex)
    return (axis,) == axes(arg.mask)
end

###
### append
###
# TODO document append_keys!
#= append_keys!(x, y) =#
append_keys!(x::AbstractRange, y) = set_length!(x, length(x) + length(y))
function append_keys!(x, y)
    if eltype(x) <: eltype(y)
        for x_i in x
            if x_i in y
                error("Element $x_i appears in both collections in call to append_axis!(collection1, collection2). All elements must be unique.")
            end
        end
        return append!(x, y)
    else
        return append_axis!(x, promote_axis_collections(y, x))
    end
end

known_offset(x) = known_offset(typeof(x))
function known_offset(::Type{T}) where {T<:AbstractUnitRange}
    if known_first(T) === nothing
        return nothing
    else
        f = known_first(T)
        return  f - one(f)
    end
end
known_offset(::Type{T}) where {F,T<:AbstractOffsetAxis{<:Any,<:Any,StaticInt{F}}} = F
known_offset(::Type{T}) where {T<:AbstractOffsetAxis} = nothing

@inline static_offset(x) = ArrayInterface.maybe_static(known_offset, i -> offsets(i, 1), x)

@inline ArrayInterface.offsets(axis::AbstractAxis, i) = offsets(axis)[i]
ArrayInterface.offsets(axis::AbstractAxis) = (offsets(parent(axis)),)

ArrayInterface.offsets(axis::AbstractOffsetAxis) = (getfield(axis, :offset),)

###
### offsets
###
# known_offset

@inline apply_offset(axis::AbstractUnitRange, i::Integer) = Int(i)
@inline apply_offset(axis::AbstractAxis, i::Integer) = apply_offset(parent(axis), i)
@inline apply_offset(axis::AbstractOffsetAxis, i::Integer) = Int(i - offsets(axis, 1))
# when this happens it means that we had eachindex(A) for linear indexing but it has a
# IndexCartesian
@inline apply_offset(axis::CartesianIndices, i::Integer) = Int(i)

apply_offset(axis::AbstractUnitRange, i) = i
apply_offset(axis::AbstractAxis, i) = i
@inline apply_offset(axis::AbstractOffsetAxis, i) = i .- offsets(axis, 1)
@inline function apply_offset(axis::AbstractOffsetAxis, i::AbstractRange)
    f = offsets(axis, 1)
    if known_step(i) === 1
        return (static_first(i) - f):(static_last(i) - f)
    else
        return i .- f
    end
end

