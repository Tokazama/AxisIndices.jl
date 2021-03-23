
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

@inline Base.in(x::Integer, axis::AbstractAxis) = !(x < first(axis) || x > last(axis))

Base.pairs(axis::AbstractAxis) = Base.Iterators.Pairs(a, keys(axis))

# This is required for performing `similar` on arrays
Base.to_shape(axis::AbstractAxis) = length(axis)

Base.haskey(axis::AbstractAxis, key) = key in keys(axis)

@inline Base.axes(axis::AbstractAxis) = (Base.axes1(axis),)

@inline Base.axes1(axis::AbstractAxis) = copy(axis)

@inline Base.unsafe_indices(axis::AbstractAxis) = (axis,)

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

###
### first
###

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
Base.summary(io::IO, axis::AbstractAxis) = show(io, axis)

# FIXME this should have offset axes remain as the parent axis
function reverse_keys(axis::AbstractAxis, newinds::AbstractUnitRange{Int})
    return _Axis(reverse(keys(axis)), compose_axis(newinds))
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

