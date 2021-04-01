
#= length =#
@inline Base.length(axis::Axis) = _length(param(axis), parent(axis))
_length(p, a) = length(a)
_length(p::AxisPads, a) = first_pad(p) + last_pad(p) + length(a)

#= known_length =#
ArrayInterface.known_length(::Type{Axis{P,A}}) where {P,A} = known_length(A)
function ArrayInterface.known_length(::Type{Axis{P,A}}) where {F,L,P<:AxisPads{F,L},A}
    return _add(_padded_known_length(Pads{F,L}), known_length(A))
end
_padded_known_length(::Type{Pads{StaticInt{F},StaticInt{L}}}) where {F,L} = F + L
_padded_known_length(::Type{Pads{F,L}}) where {F,L} = nothing

#= known_first =#
ArrayInterface.known_first(::Type{Axis{P,A}}) where {P,A} = known_first(A)
ArrayInterface.known_first(::Type{Axis{AxisOffset{Int},A}}) where {A} = nothing
function ArrayInterface.known_first(::Type{Axis{AxisOffset{StaticInt{N}},A}}) where {N,A}
    return _add(known_first(A), N)
end
ArrayInterface.known_first(::Type{Axis{AxisOrigin{Int},A}}) where {A} = nothing
function ArrayInterface.known_first(::Type{Axis{AxisOrigin{StaticInt{N}},A}}) where {N,A}
    return _sub(N, _half(known_length(A)))
end

function ArrayInterface.known_first(::Type{Axis{P,A}}) where {F,L,P<:AxisPads{F,L},A}
    return _padded_known_first(Pads{F,L}, known_first(A))
end
_padded_known_first(::Type{Pads{F,L}}, x) where {F,L} = nothing
_padded_known_first(::Type{Pads{StaticInt{F},L}}, x) where {F,L} = _sub(x, F)

#= first =#
Base.firstindex(axis::Axis) = first(axis)
Base.first(axis::Axis) = Int(_first(param(axis), parent(axis)))
_first(p, axis) = first(axis)
_first(p::AxisOffset, axis) = first(axis) + param(p)
_first(p::AxisPads, axis) = first(axis) - first_pad(p)
_first(p::AxisOrigin, axis) = param(p) - div(length(parent(axis)), 2)

#= known_last =#
ArrayInterface.known_last(::Type{Axis{P,A}}) where {P,A} = known_last(A)
ArrayInterface.known_last(::Type{Axis{AxisOffset{Int},A}}) where {A} = nothing
function ArrayInterface.known_last(::Type{Axis{AxisOffset{StaticInt{N}},A}}) where {N,A}
    return _add(known_last(A), N)
end
ArrayInterface.known_last(::Type{Axis{AxisOrigin{Int},A}}) where {A} = nothing
function ArrayInterface.known_last(::Type{Axis{AxisOrigin{StaticInt{N}},A}}) where {N,A}
    len = known_length(A)
    return _sub1(_add(_sub(N, _half(len)), len))
end
function ArrayInterface.known_last(::Type{Axis{P,A}}) where {F,L,P<:AxisPads{F,L},A}
    return _padded_known_last(Pads{F,L}, known_last(A))
end
_padded_known_last(::Type{Pads{F,L}}, x) where {F,L} = nothing
_padded_known_last(::Type{Pads{F,StaticInt{L}}}, x) where {F,L} = _add(x, L)

#= last =#
Base.lastindex(a::Axis) = last(a)
Base.last(axis::Axis) = Int(_last(param(axis), parent(axis)))
_last(p, axis) = last(axis)
_last(p::AxisOffset, axis) = last(axis) + param(p)
_last(p::AxisPads, axis) = last(axis) + last_pad(p)
function _last(p::AxisOrigin, axis)
    len = length(axis)
    return _sub1(_add(_sub(param(p), _half(len)), len))
end

############
### misc ###
############
Base.eachindex(axis::Axis) = static_first(axis):static_last(axis)
@inline Base.axes1(axis::PaddedAxis) = OffsetAxis(static_first(axis):static_last(axis))
@inline Base.axes1(axis::Axis) = copy(axis)

for f in (:(==), :isequal)
    @eval begin
        Base.$(f)(x::Axis, y::Axis) = $f(eachindex(x), eachindex(y))
        Base.$(f)(x::AbstractArray, y::Axis) = $f(x, eachindex(y))
        Base.$(f)(x::Axis, y::AbstractArray) = $f(eachindex(x), y)
        Base.$(f)(x::AbstractRange, y::Axis) = $f(x, eachindex(y))
        Base.$(f)(x::Axis, y::AbstractRange) = $f(eachindex(x), y)
        Base.$(f)(x::StaticRanges.GapRange, y::Axis) = $f(x, eachindex(y))
        Base.$(f)(x::Axis, y::StaticRanges.GapRange) = $f(eachindex(x), y)
        Base.$(f)(x::OrdinalRange, y::Axis) = $f(x, eachindex(y))
        Base.$(f)(x::Axis, y::OrdinalRange) = $f(eachindex(x), y)
    end
end

Base.allunique(a::Axis) = true

@inline Base.in(x::Integer, axis::Axis) = !(x < first(axis) || x > last(axis))

Base.pairs(axis::Axis) = Base.Iterators.Pairs(a, keys(axis))

# This is required for performing `similar` on arrays
Base.to_shape(axis::Axis) = length(axis)

Base.haskey(axis::Axis, key) = key in keys(axis)

@inline Base.axes(axis::Axis) = (Base.axes1(axis),)

@inline Base.unsafe_indices(axis::Axis) = (axis,)

Base.sum(axis::Axis) = sum(eachindex(axis))

offset1(axis::Axis) = static_first(axis)
known_offset1(::Type{T}) where {T<:Axis} = known_first(T)
function ArrayInterface.can_change_size(::Type{T}) where {T<:Axis}
    return can_change_size(parent_type(T))
end

Base.collect(a::Axis) = collect(eachindex(a))

Base.step(axis::Axis) = oneunit(eltype(axis))

Base.step_hp(axis::Axis) = 1

Base.size(axis::Axis) = (length(axis),)

Base.:-(axis::Axis) = maybe_unsafe_reconstruct(axis, -eachindex(axis))

function Base.:+(r::Axis, s::Axis)
    indsr = axes(r, 1)
    if indsr == axes(s, 1)
        data = eachindex(r) + eachindex(s)
        axs = (unsafe_reconstruct(r, eachindex(data)),)
        return  AxisArray{eltype(data),ndims(data),typeof(data),typeof(axs)}(data, axs)
    else
        throw(DimensionMismatch("axes $indsr and $(axes(s, 1)) do not match"))
    end
end
function Base.:-(r::Axis, s::Axis)
    indsr = axes(r, 1)
    if indsr == axes(s, 1)
        data = eachindex(r) - eachindex(s)
        axs = (unsafe_reconstruct(r, eachindex(data); keys=keys(data)),)
        return  AxisArray{eltype(data),ndims(data),typeof(data),typeof(axs)}(data, axs)
    else
        throw(DimensionMismatch("axes $indsr and $(axes(s, 1)) do not match"))
    end
end

Base.UnitRange(axis::Axis) = UnitRange(eachindex(axis))
function Base.AbstractUnitRange{T}(axis::Axis) where {T<:Integer}
    if eltype(axis) <: T && !can_change_size(axis)
        return axis
    else
        return unsafe_reconstruct(axis, AbstractUnitRange{T}(parent(axis)); keys=keys(axis))
    end
end

# FIXME this should have offset axes remain as the parent axis
function reverse_keys(axis::Axis, newinds::AbstractUnitRange{Int})
    return _Axis(reverse(keys(axis)), compose_axis(newinds))
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
                error("Element $x_i appears in both collections in call to " *
                    "append_axis!(collection1, collection2). All elements must be unique.")
            end
        end
        return append!(x, y)
    else
        return append_axis!(x, promote_axis_collections(y, x))
    end
end

@inline ArrayInterface.offsets(axis::Axis) = (first(axis),)

#= FIXME
@inline function ArrayInterface.to_axis(::IndexAxis, axis::Axis, inds)
    if allunique(inds)
        ks = Base.keys(axis)
        p = parent(axis)
        kindex = firstindex(ks)
        pindex = first(p)
        if kindex === pindex
            return _Axis(@inbounds(ks[inds]), to_axis(parent(axis), inds))
        else
            return _Axis(
                @inbounds(ks[inds .+ (pindex - kindex)]),
                to_axis(parent(axis), inds)
            )
        end
    else
        return unsafe_reconstruct(axis, to_axis(parent(axis), inds))
    end
end
=#

function maybe_unsafe_reconstruct(axis::Axis, inds::AbstractUnitRange{I}; keys=nothing) where {I<:Integer}
    if keys === nothing
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=@inbounds(Base.keys(axis)[inds]))
    else
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=keys)
    end
end
function maybe_unsafe_reconstruct(axis::Axis, inds::AbstractArray)
    if keys === nothing
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds))),)
    elseif allunique(inds)
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds)); keys=@inbounds(keys(axis)[inds])),)
    else  # not all indices are unique so will result in non-unique keys
        axs = (SimpleAxis(eachindex(inds)),)
    end
    return AxisArray{eltype(axis),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
end

