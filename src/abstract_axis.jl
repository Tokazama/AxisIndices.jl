
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
Base.to_shape(r::IdentityUnitRange) = length(r)

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
        axs = (unsafe_reconstruct(r, eachindex(data)),)
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

ArrayInterface.known_last(::Type{T}) where {T<:AbstractAxis} = known_last(parent_type(T))

###
### first
###
Base.firstindex(axis::AbstractAxis) = first(axis)
Base.first(axis::AbstractAxis) = first(parent(axis))

ArrayInterface.known_first(::Type{T}) where {T<:AbstractAxis} = known_first(parent_type(T))

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
Base.summary(io::IO, axis::AbstractAxis) = show(io, axis)

function reverse_keys(axis::AbstractAxis, newinds::AbstractUnitRange)
    return Axis(reverse(keys(axis)), newinds; checks=NoChecks)
end

###
### maybe_unsafe_reconstruct
###
maybe_unsafe_reconstruct(axis, inds::Integer; kwargs...) = eltype(axis)(inds)
function maybe_unsafe_reconstruct(axis, inds::AbstractArray; keys=nothing)
    if known_step(inds) === 1 && eltype(inds) <: Integer
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=keys)
    else
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds))),)
        return AxisArray{eltype(inds),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
    end
end
function maybe_unsafe_reconstruct(axis::AbstractOffsetAxis, inds::AbstractArray; keys=nothing)
    if known_step(inds) === 1 && eltype(inds) <: Integer
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=keys)
    else
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds))),)
        return AxisArray{eltype(inds),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
    end
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

@inline ArrayInterface.offsets(axis::AbstractAxis) = (first(axis),)

Base.show(io::IO, axis::AbstractAxis) = _show(io, axis)
Base.show(io::IO, ::MIME"text/plain", axis::AbstractAxis) = _show(io, axis)
function _show(io::IO, axis::AbstractAxis)
    if haskey(io, :compact)
        ks = keys(axis)
        if known_step(ks) === 1
            # this prevents StaticInt from creating long prints to REPL
            print(io, "$(Int(first(ks))):$(Int(last(ks)))")
        else
            print(io, ks)
        end
    else
        print_axis(io, axis)
    end
end

