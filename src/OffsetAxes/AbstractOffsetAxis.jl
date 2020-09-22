
Styles.AxisIndicesStyle(::Type{A}, ::Type{T}) where {A<:AbstractOffsetAxis,T} = KeyedStyle(T)

#=
function Interface.indices_type(::Type{T}) where {T<:AbstractOffsetAxis}
    start = known_first(T)
    stop = known_last(T)
    if stop isa Nothing && start isa Nothing
        return UnitRange{Int}
        # FIXME when OptionallyStaticUnitRange is finalized in ArrayInterface
        # return OptionallyStaticUnitRange{eltype(T),start}
    else
        return UnitSRange{eltype(start),start,stop}
    end
end
=#

Interface.is_indices_axis(::Type{<:AbstractOffsetAxis}) = true

@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, i::Integer)
    @boundscheck if !in(i, keys(axis))
        throw(BoundsError(axis, i))
    end
    return i
end

function Interface.print_axis(io, axis::AbstractOffsetAxis)
    if haskey(io, :compact)
        Interface.print_axis_compactly(io, keys(axis))
    else
        print(io, "$(typeof(axis).name)($(keys(axis)) => $(indices(axis)))")
    end
end

_add_offset(f::Integer, ::Nothing) = nothing
_add_offset(::Type, ::Nothing) = nothing
_add_offset(::Type, x::Integer) = nothing
_add_offset(f::Integer, x::Integer) = x + f


@inline function ArrayInterface.known_first(::Type{T}) where {T<:AbstractOffsetAxis}
    return _add_offset(known_offset(T), known_first(parent_indices_type(T)))
end

@inline function ArrayInterface.known_last(::Type{T}) where {T<:AbstractOffsetAxis}
    return _add_offset(known_offset(T), known_last(parent_indices_type(T)))
end

#=
@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, i::Integer)
    return values(axis)[i - get_offset(axis)] + get_offset(axis)
end
@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, s::AbstractUnitRange{<:Integer})
    return values(axis)[s .- get_offset(axis)] .+ get_offset(axis)
end
@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, s::AbstractOffsetAxis)
    return OffsetAxis(get_offset(axis), parentindices(axis)[s .- get_offset(axis)])
end

function Base.checkindex(::Type{Bool}, axis::AbstractOffsetAxis, i::Integer)
    return checkindex(Bool, parentindices(axis), parentindices(axis) - get_offset(axis))
end

function Base.checkindex(::Type{Bool}, axis::AbstractOffsetAxis, i::AbstractUnitRange{<:Integer})
    return checkindex(Bool, parentindices(axis), parentindices(axis) .- get_offset(axis))
end
=#

#=
for f in (:find_lasteq,
          :find_lastgt,
          :find_lastgteq,
          :find_lastlt,
          :find_lastlteq,
          :find_firsteq,
          :find_firstgt,
          :find_firstgteq,
          :find_firstlt,
          :find_firstlteq)
    @eval begin
        function StaticRanges.$f(x, r::AbstractOffsetAxis)
            f = offset(r)
            idx = $f(x - f, values(r))
            if idx isa Nothing
                return idx
            else
                return idx + f
            end
        end
    end
end

FIXME - not sure what to do about this for offset axes
function StaticRanges.set_last!(axis::AbstractOffsetAxis{K}, val) where {K,I}
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(indices(axis), val)
    _reset_keys!(axis, length(indices(axis)))
    return axis
end

function Base.popfirst!(axis::AbstractOffsetAxis)
    StaticRanges.can_set_first(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    out = popfirst!(indices(axis))
    _reset_keys!(axis, length(indices(axis)))
    return out
end


function Base.pop!(axis::AbstractOffsetAxis)
    StaticRanges.can_set_last(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    out = pop!(indices(axis))
    _reset_keys!(axis, length(indices(axis)))
    return out
end

=#


