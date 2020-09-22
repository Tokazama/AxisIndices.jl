
Base.IndexStyle(::Type{T}) where {T<:Axis} = IndexAxis()
Base.IndexStyle(::Type{T}) where {T<:OffsetAxis} = IndexOffset()
Base.IndexStyle(::Type{T}) where {T<:CenteredAxis} = IndexCentered()
Base.IndexStyle(::Type{T}) where {T<:IdentityAxis} = IndexIdentity()

# :resize_first!, :resize_last! don't need to define these ones b/c non mutating ones are only
# defined to avoid ambiguities with methods that pass AbstractUnitRange{<:Integer} instead of Integer
for f in (:grow_last!, :grow_first!, :shrink_last!, :shrink_first!)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            can_set_length(axis) ||  throw(MethodError($f, (axis, n)))
            StaticRanges.$f(parentindices(axis), n)
            return axis
        end

        function StaticRanges.$f(axis::Axis, n::Integer)
            can_set_length(axis) ||  throw(MethodError($f, (axis, n)))
            StaticRanges.$f(keys(axis), n)
            StaticRanges.$f(parentindices(axis), n)
            return axis
        end
    end
end

for f in (:grow_last, :grow_first, :shrink_last, :shrink_first, :resize_first, :resize_last)
    @eval begin
        @inline function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            return unsafe_reconstruct(axis, StaticRanges.$f(parentindices(axis), n))
        end

        @inline function StaticRanges.$f(axis::Axis, n::Integer)
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), n),
                StaticRanges.$f(parentindices(axis), n)
            )
        end

    end
end

for f in (:shrink_last, :shrink_first)
    @eval begin
        @inline function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        @inline function StaticRanges.$f(axis::Axis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), length(axis) - length(n)),
                n
            )
        end
    end
end

for f in (:grow_last, :grow_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        function StaticRanges.$f(axis::Axis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), length(n) - length(axis)),
                n
            )
        end
    end
end

for f in (:resize_last, :resize_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        function StaticRanges.$f(axis::Axis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, StaticRanges.$f(keys(axis), length(n)), n)
        end
    end
end

Base.empty!(axis::AbstractAxis) = set_length!(axis, 0)

function Base.pop!(axis::AbstractAxis)
    StaticRanges.can_set_last(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    return _pop!(axis)
end

function _pop!(axis::Axis)
    pop!(keys(axis))
    return pop!(parentindices(axis))
end

_pop!(axis::AbstractAxis) = pop!(parentindices(axis))

function Base.popfirst!(axis::AbstractAxis)
    StaticRanges.can_set_first(axis) || error("Cannot change size of index of type $(typeof(axis)).")
    return _popfirst!(axis)
end


function _popfirst!(axis::Axis)
    popfirst!(keys(axis))
    return popfirst!(parentindices(axis))
end

_popfirst!(axis::AbstractAxis) = popfirst!(parentindices(axis))

#= TODO implement this when part of ArrayInterface
function StaticRanges.popfirst(axis::AbstractAxis)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, popfirst(indices(axis)))
    else
        return unsafe_reconstruct(axis, popfirst(keys(axis)), popfirst(indices(axis)))
    end
end

function StaticRanges.pop(axis::AbstractAxis)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, pop(indices(axis)))
    else
        return unsafe_reconstruct(axis, pop(keys(axis)), pop(indices(axis)))
    end
end
=#

# TODO check for existing key first
function push_key!(axis::AbstractAxis, key)
    grow_last!(iparentndices(axis), 1)
    return nothing
end

function push_key!(axis::Axis, key)
    push!(keys(axis), key)
    grow_last!(iparentndices(axis), 1)
    return nothing
end

function pushfirst_axis!(axis::AbstractAxis)
    grow_last!(iparentndices(axis), 1)
    return nothing
end

function pushfirst_axis!(axis::Axis)
    grow_first!(keys(axis), 1)
    grow_last!(parentindices(axis), 1)
    return nothing
end

function popfirst_axis!(axis::Axis)
    if StaticRanges.can_set_first(axis)
        StaticRanges.shrink_first!(keys(axis), 1)
    else
        shrink_last!(keys(axis), 1)
    end
    shrink_last!(parentindices(axis), 1)
    return nothing
end

function popfirst_axis!(axis::AbstractAxis)
    shrink_last!(parentindices(axis), 1)
    return nothing
end

function StaticRanges.set_length!(axis::AbstractAxis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(parentindices(axis), len)
    return axis
end

###
### length
###
@inline Base.length(axis::AbstractAxis) = length(parentindices(axis))
@inline function Base.length(axis::Axis{K,I,Ks,Inds}) where {K,I,Ks,Inds}
    if known_length(Ks) === nothing
        return length(parentindices(axis))
    else
        return known_length(Ks)
    end
end

function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return can_set_length(parent_type(T))
end

function StaticRanges.can_set_length(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_length(Ks) & can_set_length(Inds)
end

function StaticRanges.set_length!(axis::Axis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(parentindices(axis), len)
    set_length!(keys(axis), len)
    return axis
end


function StaticRanges.set_length(axis::AbstractAxis, len)
    return unsafe_reconstruct(axis, set_length(indices(axis), len))
end

function StaticRanges.set_length(axis::Axis, len)
    return unsafe_reconstruct(
        axis,
        set_length(keys(axis), len),
        set_length(parentindices(axis), len)
    )
end

###
### last
###
Base.last(axis::AbstractAxis) = last(parentindices(axis))
Base.last(axis::AbstractOffsetAxis) = last(parentindices(axis)) + offsets(axis)
Base.lastindex(a::AbstractAxis) = last(a)

StaticRanges.can_set_last(::Type{T}) where {T<:AbstractAxis} = can_set_last(parent_type(T))
function StaticRanges.can_set_last(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_last(Ks) & can_set_last(Inds)
end

function StaticRanges.set_last!(axis::Axis, val)
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(parentindices(axis), val)
    resize_last!(keys(axis), length(parentindices(axis)))
    return axis
end

function StaticRanges.set_last!(axis::AbstractAxis, val)
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(parentindices(axis), val)
    return axis
end

function StaticRanges.set_last(axis::AbstractAxis, val)
    return unsafe_reconstruct(axis, set_last(parentindices(axis), val))
end

function StaticRanges.set_last(axis::Axis, val)
    vs = set_last(parentindices(axis), val)
    return unsafe_reconstruct(axis, resize_last(keys(axis), length(vs)), vs)
end

function ArrayInterface.known_last(::Type{T}) where {T<:AbstractAxis}
    return known_last(parent_type(T))
end

###
### first
###
ArrayInterface.known_first(::Type{T}) where {T<:AbstractAxis} = known_first(parent_type(T))
@inline function ArrayInterface.known_first(::Type{T}) where {T<:AbstractOffsetAxis}
    if known_first(parent_type(T)) === nothing || known_offsets(T) === nothing
        return nothing
    else
        return known_first(parent_type(T)) + known_offsets(T)
    end
end

Base.first(axis::AbstractAxis) = first(parentindices(axis))
Base.first(axis::AbstractOffsetAxis) = first(parentindices(axis)) + offsets(axis)
Base.firstindex(axis::AbstractAxis) = first(axis)

function StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis}
    return can_set_first(parent_type(T))
end
function StaticRanges.can_set_first(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_first(Ks) & can_set_first(Inds)
end

function StaticRanges.set_first(axis::AbstractAxis, val)
    return unsafe_reconstruct(axis, set_first(parentindices(axis), val))
end
function StaticRanges.set_first(axis::Axis, val)
    vs = set_first(parentindices(axis), val)
    return unsafe_reconstruct(axis, resize_first(keys(axis), length(vs)), vs)
end

function StaticRanges.set_first!(axis::AbstractAxis, val)
    can_set_first(axis) || throw(MethodError(set_first!, (axis, val)))
    set_first!(parentindices(axis), val)
    return axis
end

function StaticRanges.set_first!(axis::Axis, val)
    can_set_first(axis) || throw(MethodError(set_first!, (axis, val)))
    set_first!(parentindices(axis), val)
    resize_first!(keys(axis), length(parentindices(axis)))
    return axis
end


###
### step
###
Base.step(axis::AbstractAxis) = oneunit(eltype(axis))

Base.step_hp(axis::AbstractAxis) = 1

Base.size(axis::AbstractAxis) = (length(axis),)

Base.parentindices(axis::Axis) = getfield(axis, :parent_indices)
Base.parentindices(axis::SimpleAxis) = getfield(axis, :parent_indices)
Base.parentindices(axis::StructAxis) = getfield(axis, :parent_indices)
Base.parentindices(axis::OffsetAxis) = getfield(axis, :parent_indices)
Base.parentindices(axis::CenteredAxis) = getfield(axis, :parent_indices)
Base.parentindices(axis::IdentityAxis) = getfield(axis, :parent_indices)

ArrayInterface.parent_type(::Type{T}) where {Inds,T<:Axis{<:Any,<:Any,<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:SimpleAxis{<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:StructAxis{<:Any,<:Any,<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:CenteredAxis{<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:OffsetAxis{<:Any,<:Any,Inds}} = Inds
ArrayInterface.parent_type(::Type{T}) where {Inds,T<:IdentityAxis{<:Any,<:Any,Inds}} = Inds

@inline _find_center(start, stop) = start + div(stop - start - one(start), 2)
function known_offsets(::Type{T}) where {T<:AbstractUnitRange}
    if known_first(T) === nothing
        return nothing
    else
        return known_first(T) - 1
    end
end
known_offsets(::Type{T}) where {T<:AbstractAxis} = known_offsets(parent_type(T))
known_offsets(::Type{T}) where {F,T<:OffsetAxis{<:Any,StaticInt{F}}} = F
known_offsets(::Type{T}) where {T<:OffsetAxis{<:Any,<:Any}} = nothing
known_offsets(::Type{T}) where {F,T<:IdentityAxis{<:Any,StaticInt{F}}} = F
known_offsets(::Type{T}) where {T<:IdentityAxis{<:Any,<:Any}} = nothing
@inline function known_offsets(::Type{T}) where {T<:CenteredAxis}
    P = parent_type(T)
    if known_first(P) === nothing
        return nothing
    else
        if known_last(P) === nothing
            return _find_center(known_first(P), known_last(P))
        else
            return nothing
        end
    end
end

ArrayInterface.offsets(axis::AbstractAxis) = offsets(parentindices(axis))
ArrayInterface.offsets(axis::OffsetAxis) = getfield(axis, :offsets)
ArrayInterface.offsets(axis::IdentityAxis) = getfield(axis, :offsets)
function ArrayInterface.offsets(axis::CenteredAxis)
    p = parentindices(axis)
    return _find_center(first(p), last(p))
end

# interface
Base.keys(axis::Axis) = getfield(axis, :keys)
Base.keys(axis::SimpleAxis) = parentindices(axis)
Base.keys(axis::AbstractOffsetAxis) = eachindex(axis)
# TODO Base.keys(axis::StructAxis)

function unsafe_reconstruct(a::Axis, ks::Ks, vs::Vs) where {Ks,Vs}
    return Axis{eltype(Ks),eltype(Vs),Ks,Vs}(ks, vs)
end

unsafe_reconstruct(axis::CenteredAxis, inds) = CenteredAxis{eltype(inds)}(inds)

###
### to_axis
###
function to_axis(::IndexAxis, axis, arg, inds)
    if is_key(axis, arg) && (arg isa AbstractVector)
        ks = arg
    else
        ks = @inbounds(getindex(keys(axis), inds))
    end
    return Axis(ks, to_axis(parentindices(axis), arg, inds))
end
function to_axis(::IndexOffset, axis, arg, inds)
    return OffsetAxis(offsets(axis), to_axis(parentindices(axis), arg, inds))
end
function to_axis(::IndexCentered, axis, arg, inds)
    return CenteredAxis(to_axis(parentindices(axis), arg, inds))
end
function to_axis(::IndexIdentity, axis, arg, inds)
    if inds <: AbstractUnitRange
        return IdentityAxis(inds, to_index(parentindices(axis), arg, inds))
    else
        return to_axis(parentindices(axis), arg, inds)
    end
end
# TODO function to_axis(::IndexPaddedStyle, axis, arg, inds) end

###
### getindex
###

@propagate_inbounds Base.getindex(axis::AbstractAxis, arg::Integer) = to_index(axis, arg)
Base.getindex(axis::AbstractAxis, ::Colon) = indices(axis)
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::AbstractUnitRange{I}) where {I<:Integer}
    return unsafe_reconstruct(axis, arg, to_index(axis, arg))
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StepRange{I}) where {I<:Integer}
    return to_index(axis, arg)
end
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg::StaticRanges.GapRange)
    return to_index(axis, arg)
end
Base.getindex(axis::AbstractAxis, ::Ellipsis) = indices(axis)
@propagate_inbounds function Base.getindex(axis::AbstractAxis, arg)
    return _getindex(axis, arg, to_index(axis, arg))
end
function unsafe_reconstruct(axis::AbstractAxis, arg, inds::AbstractUnitRange{I}) where {I<:Integer}
    return unsafe_reconstruct(IndexStyle(axis), axis, arg, inds)
end

_getindex(axis, arg, idx::Integer) = idx
_getindex(axis, arg, idx::AbstractVector) = idx
@inline _getindex(axis, arg, idx::AbstractUnitRange) = unsafe_reconstruct(axis, arg, idx)

unsafe_reconstruct(axis::AbstractAxis, arg, inds::Integer) = inds
unsafe_reconstruct(axis::AbstractAxis, arg, inds::AbstractVector) = inds

unsafe_reconstruct(::IndexOffset, axis, arg, inds) = OffsetAxis(offsets(axis), inds)
unsafe_reconstruct(::IndexCentered, axis, arg, inds) = CenteredAxis(inds)
unsafe_reconstruct(::IndexIdentity, axis, arg, inds) = IdentityAxis(inds)
function unsafe_reconstruct(::IndexAxis, axis, arg, inds)
    return Axis(@inbounds(getindex(keys(axis), inds)), inds)
end
unsafe_reconstruct(::IndexStyle, axis, arg, inds) = SimpleAxis(inds)

###
### checkindex
###
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Colon} = true
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Slice} = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:AbstractArray}
    if is_key(axis, arg)
        return length(find_all_in(drop_marker(arg), keys(axis))) == length(drop_marker(arg))
    else
        return checkindex(Bool, eachindex(axis), drop_marker(arg))
    end
end
Base.checkindex(::Type{Bool}, ::AbstractAxis, ::IndexingMarker{T}) where {N,T<:AbstractArray{Bool,N}} = N === 1
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Union{<:Equal,<:Approx}}
    if is_key(axis, arg)
        return !(find_first(drop_marker(arg), keys(axis)) === nothing)
    else
        return !(find_first(drop_marker(arg), eachindex(axis)) === nothing)
    end
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:AbstractRange}
    if is_key(axis, arg)
        return length(find_all_in(drop_marker(arg), keys(axis))) == length(axis)
    else
        return checkindex(Bool, eachindex(axis), drop_marker(arg))
    end
end
Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Fix2} = true
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T}
    if is_key(axis, arg)
        return drop_marker(arg) in keys(axis)
    else
        return drop_marker(arg) in eachindex(axis)
    end
end

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

#=
@inline function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T<:Function}
end

@inline function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::IndexingMarker{T}) where {T}
    if is_element(axis, arg)

    else
    end
end

_checkindex(axis, arg) = _checkindex(IndexStyle(axis), axis, arg)
_checkindex(::IndexLinear, axis, arg::Integer) = arg in axis
@inline function _checkindex(::IndexLinear, axis, arg::AbstractArray{I}) where {I<:Integer}
    if parent_type(axis) <: typeof(axis)
        return checkindex(Bool, axis, arg)
    else
        return checkindex(Bool, parentindices(axis), arg)
    end
end
_checkindex(::IndexLinear, axis, arg::AbstractArray) = all(in(axis), arg)
_checkindex(::IndexLinear, axis, ::Function) = true
_checkindex(::IndexLinear, axis, arg) = !(find_first(==(arg), axis) === nothing)
function _checkindex(::IndexLinear, axis, arg::Union{<:Equal,<:Approx})
    return !(find_first(arg, axis) === nothing)
end
function _checkindex(::IndexAxis, axis, arg)
    if is_key(axis, arg)
        return _checkindex(keys(axis), drop_marker(arg))
    else
        return _checkindex(parentindices(axis), drop_marker(arg))
    end
end

function _checkindex(axis, arg::MarkKeys{T}) where {T<:Integer}
    return drop_marker(arg) in keys(axis)
end
function _checkindex(axis, arg::MarkIndices{T}) where {T<:AbstractArray}

end
=#

###
### General AbstractAxis methods
###
Base.eachindex(axis::AbstractAxis) = parentindices(axis)
Base.eachindex(axis::AbstractOffsetAxis) = static_first(axis):static_last(axis)

Base.allunique(a::AbstractAxis) = true

@inline Base.in(x::Integer, axis::AbstractAxis) = !(x < first(axis) || x > last(axis))

Base.pairs(axis::AbstractAxis) = Base.Iterators.Pairs(a, keys(axis))

# This is required for performing `similar` on arrays
Base.to_shape(axis::AbstractAxis) = length(axis)

Base.haskey(axis::AbstractAxis, key) = key in keys(axis)

@inline function Base.compute_offset1(parent, stride1::Integer, dims::Tuple{Int}, inds::Tuple{<:AbstractAxis}, I::Tuple)
    return Base.compute_linindex(parent, I) - stride1 * first(axes(parent, first(dims)))
end

@inline Base.axes(axis::AbstractAxis) = (Base.axes1(axis),)

@inline Base.axes1(axis::AbstractAxis) = copy(axis)

@inline Base.unsafe_indices(axis::AbstractAxis) = (axis,)

Base.isempty(axis::AbstractAxis) = isempty(parentindices(axis))

Base.sum(axis::AbstractAxis) = sum(eachindex(axis))

function ArrayInterface.can_change_size(::Type{T}) where {T<:AbstractAxis}
    return can_change_size(parent_type(T))
end

Base.collect(a::AbstractAxis) = collect(eachindex(a))

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

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function reverse_keys(axis::AbstractAxis, newinds::AbstractUnitRange)
    if is_indices_axis(axis)
        return to_axis(reverse(keys(axis)), newinds, false)
    else
        return similar(axis, reverse(keys(axis)), newinds, false)
    end
end

