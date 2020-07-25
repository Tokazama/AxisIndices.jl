
"""
    AbstractOffsetAxis{I,Ks,Inds}

Supertype for axes that begin indexing offset from one. All subtypes of `AbstractOffsetAxis`
use the keys for indexing and only convert to the underlying indices when
`to_index(::OffsetAxis, ::Integer)` is called (i.e. when indexing the an array
with an `AbstractOffsetAxis`. See [`OffsetAxis`](@ref), [`CenteredAxis`](@ref),
and [`IdentityAxis`](@ref) for more details and examples.
"""
abstract type AbstractOffsetAxis{I,Ks,Inds} <: AbstractAxis{I,I,Ks,Inds} end

@inline Base.first(axis::AbstractOffsetAxis) = first(keys(axis))

@inline Base.last(axis::AbstractOffsetAxis) = last(keys(axis))

Base.firstindex(axis::AbstractOffsetAxis) = first(axis)

Base.lastindex(axis::AbstractOffsetAxis) = last(axis)

Base.eachindex(axis::AbstractOffsetAxis) = keys(axis)

Base.collect(axis::AbstractOffsetAxis) = collect(keys(axis))

Styles.AxisIndicesStyle(::Type{A}, ::Type{T}) where {A<:AbstractOffsetAxis,T} = KeyedStyle(T)

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

function ArrayInterface.known_first(::Type{T}) where {T<:AbstractOffsetAxis}
    return known_first(keys_type(T))
end

function ArrayInterface.known_last(::Type{T}) where {T<:AbstractOffsetAxis}
    return known_last(keys_type(T))
end


#=
"""
    offset(x)

Returns the offset from 1-based indexing `x` has.
"""
offset(x::OneToUnion) = 0
offset(x::AbstractUnitRange) = first(x) - 1
#offset(x::AbstractUnitRange) = 1 - first(x)
#offset(axis::CenteredAxis) = first(keys(axis)) - 1

@inline function Base.iterate(axis::AbstractOffsetAxis)
    ret = iterate(values(axis))
    ret === nothing && return nothing
    return (ret[1] + offset(axis), ret[2])
end

@inline function Base.iterate(axis::AbstractOffsetAxis, i)
    ret = iterate(values(axis), i)
    ret === nothing && return nothing
    return (ret[1] + offset(axis), ret[2])
end


@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, i::Integer)
    return values(axis)[i - offset(axis)] + offset(axis)
end
@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, s::AbstractUnitRange{<:Integer})
    return values(axis)[s .- offset(axis)] .+ offset(axis)
end
@propagate_inbounds function Base.getindex(axis::AbstractOffsetAxis, s::AbstractOffsetAxis)
    return OffsetAxis(offset(axis), values(axis)[s .- offset(axis)])
end

function Base.checkindex(::Type{Bool}, axis::AbstractOffsetAxis, i::Integer)
    return checkindex(Bool, values(axis), values(axis) - offset(axis))
end

#function Base.checkindex(::Type{Bool}, axis::AbstractOffsetAxis, i::AbstractUnitRange{<:Integer})
#    return checkindex(Bool, values(axis), values(axis) .- offset(axis))
#end


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

=#

function Base.pop!(axis::AbstractOffsetAxis)
    StaticRanges.can_set_last(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    out = pop!(indices(axis))
    _reset_keys!(axis, length(indices(axis)))
    return out
end

function StaticRanges.set_last!(axis::AbstractOffsetAxis{K,I}, val::I) where {K,I}
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

function StaticRanges.grow_last!(axis::AbstractOffsetAxis, n::Integer)
    can_set_length(axis) ||  throw(MethodError(grow_last!, (axis, n)))
    len = length(axis) + n
    StaticRanges.grow_last!(indices(axis), n)
    _reset_keys!(axis, len)
    return nothing
end

function StaticRanges.shrink_last!(axis::AbstractOffsetAxis, n::Integer)
    can_set_length(axis) ||  throw(MethodError(shrink_last!, (axis, n)))
    len = length(axis) - n
    StaticRanges.shrink_last!(indices(axis), n)
    _reset_keys!(axis, len)
    return nothing
end

function StaticRanges.set_length!(axis::AbstractOffsetAxis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(indices(axis), len)
    _reset_keys!(axis, len)
    return axis
end

# TODO check for existing key first
push_key!(axis::AbstractOffsetAxis, key) = grow_last!(axis, 1)

pushfirst_key!(axis::AbstractOffsetAxis, key) = grow_last!(axis, 1)

