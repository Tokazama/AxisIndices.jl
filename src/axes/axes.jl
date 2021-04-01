
"""
    IndexAxis

Index style for mapping keys to an array's parent indices.
"""
struct IndexAxis <: IndexStyle end
Base.IndexStyle(::Type{Axis{P,A}}) where {P,A} = IndexAxis()

include("lazy_vcat.jl")
include("lazy_index.jl")

include("pads.jl")
include("offsets.jl")
include("keys.jl")
include("struct_axis.jl")
include("indexing.jl")
include("compose.jl")
include("axes_methods.jl")
include("range_interface.jl")
include("initialize.jl")

# TODO - replace/reorganize
function ArrayInterface.unsafe_reconstruct(axis::OffsetAxis, inds)
    if inds isa AbstractOffsetAxis
        f_axis = offsets(axis, 1)
        f_inds = offsets(inds, 1)
        if f_axis === f_inds
            return OffsetAxis(offsets(axis, 1), unsafe_reconstruct(parent(axis), parent(inds)))
        else
            return OffsetAxis(f_axis + f_inds, unsafe_reconstruct(parent(axis), parent(inds)))
        end
    else
        return _OffsetAxis(getfield(axis, :offset), unsafe_reconstruct(parent(axis), inds))
    end
end

function ArrayInterface.unsafe_reconstruct(axis::CenteredAxis, inds; kwargs...)
    return CenteredAxis(origin(axis), unsafe_reconstruct(parent(axis), inds; kwargs...))
end

function ArrayInterface.unsafe_reconstruct(axis::Axis, inds; keys=nothing)
    if keys === nothing
        ks = Base.keys(axis)
        p = parent(axis)
        kindex = firstindex(ks)
        pindex = first(p)
        if kindex === pindex
            return _Axis(@inbounds(ks[inds]), compose_axis(inds))
        else
            return _Axis(@inbounds(ks[inds .+ (pindex - kindex)]), compose_axis(inds))
        end
    else
        return _Axis(keys, compose_axis(inds))
    end
end
ArrayInterface.unsafe_reconstruct(axis::SimpleAxis, x) = SimpleAxis(x)

ArrayInterface.unsafe_reconstruct(axis::PaddedAxis, data; kwargs...) = OffsetAxis(-first_pad(axis), data)
# TODO ArrayInterface.unsafe_reconstruct(axis::StructAxis
@inline function ArrayInterface.unsafe_reconstruct(axis::StructAxis{T}, inds) where {T}
    if known_length(inds) === known_length(axis)
        return StructAxis{T,typeof(inds)}(inds)
    else
        indexΔ = One() - static_first(axis)
        return _unsafe_reconstruct_struct_axis(axis, inds, static_first(inds) + indexΔ, static_last(inds) + indexΔ)
    end
end
@inline function _unsafe_reconstruct_struct_axis(axis::StructAxis{T}, inds, start, stop) where {T}
    return initialize_axis([fieldname(T, i) for i in start:stop], compose_axis(inds))
end

@inline function _unsafe_reconstruct_struct_axis(axis::StructAxis{T}, inds, start::StaticInt, stop::StaticInt) where {T}
    return StructAxis{NamedTuple{__names(T, start:stop), __types(T, start:stop)}}(inds)
end


###
### TODO move these
###
SimpleAxis(x::AbstractUnitRange) = initialize(SimpleAxis, x)
SimpleAxis(start::Integer, stop::Integer) = SimpleAxis(start:stop)
SimpleAxis(stop::Integer) = SimpleAxis(static(1):stop)

SimpleAxis(p::AxisParameter) = ComposedFunction(SimpleAxis, p)

(p1::AxisParameter)(::Type{SimpleParam}) = ComposedFunction(p1, SimpleParam())
(p1::AxisParameter)(::SimpleParam) = ComposedFunction(p1, SimpleAxis)

const OneToAxis = Axis{SimpleParam,OptionallyStaticUnitRange{StaticInt{1},Int}}
const MutableAxis = Axis{SimpleParam,SimpleAxis{DynamicAxis}}
const StaticAxis{N} = Axis{SimpleParam,OptionallyStaticUnitRange{StaticInt{1},StaticInt{N}}}

KeyedAxis() = _Axis(Vector{Any}(), SimpleAxis(DynamicAxis(0)))
KeyedAxis(x::Pair) = KeyedAxis(x.first, x.second)
KeyedAxis(x::KeyedAxis) = x

@inline KeyedAxis(k::AbstractVector, axis) = Axis(k, compose_axis(axis))
@inline function Axis(k::AbstractVector, axis::AbstractAxis)
    return _Axis(_maybe_offset(offset1(axis) - offset1(k), k), drop_keys(axis))
end

function KeyedAxis(ks::AbstractVector)
    if can_change_size(ks)
        inds = SimpleAxis(DynamicAxis(length(ks)))
    else
        inds = compose_axis(static_first(eachindex(ks)):static_length(ks))
    end
    return _initialize(AxisKeys(ks), inds)
end

function StructAxis{T,P}(p::P) where {T,P}
    if typeof(T) <: DataType
        return _Axis(_AxisStruct(T), p)
    else
        throw(ArgumentError("Type must be have all field fully paramterized, got $T"))
    end
end

function StructAxis{T}(inds::AbstractAxis) where {T}
    fc = _fieldcount(T)
    if known_length(inds) === fc
        return StructAxis{T,typeof(inds)}(inds)
    else
        if known_first(inds) === nothing
            throw(ArgumentError("StructAxis cannot have a parent type whose first index and last index are not known at compile time."))
        else
            f = static_first(inds)
            l = f + StaticInt(fc) - One()
            return StructAxis{T}(unsafe_reconstruct(inds, f:l))
        end
    end
end
StructAxis{T}(inds) where {T} = StructAxis{T}(compose_axis(inds))
StructAxis{T}() where {T} = _Axis(_AxisStruct(T), SimpleAxis(One():StaticInt{_fieldcount(T)}()))

# need to subtract the different between the first index of the keys and the parent axis
function sub_keys_parent_diff(axis::StructAxis, inds::Integer)
    return int(inds + (static_first(axis) - static(1)))
end
function sub_keys_parent_diff(axis::StructAxis, inds)
    return inds .+ (static_first(axis) - static(1))
end

function sub_keys_parent_diff(axis, inds::Integer)
    return int(inds + (static_first(axis) - offset1(keys(axis))))
end
function sub_keys_parent_diff(axis, inds)
    return inds .+ (static_first(axis) - offset1(keys(axis)))
end

###
### promotion rules
###
Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractAxis}
    return Axis{
        promote_type(keys_type(X), keys_type(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:Axis}
    return Axis{
        promote_type(keys_type(X), keys_type(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:SimpleAxis}
    return Axis{keys_type(X),promote_type(parent_type(X), parent_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:SimpleAxis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractAxis}
    return SimpleAxis{promote_type(parent_type(X), parent_type(Y))}
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:SimpleAxis}
    return SimpleAxis{promote_type(parent_type(X),parent_type(Y))}
end

function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:SimpleAxis}
    return promote_rule(Y, X)
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractUnitRange}
    return SimpleAxis{promote_type(parent_type(X), parent_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractUnitRange}
    return Axis{keys_type(X), promote_type(parent_type(X), parent_type(Y))}
end

# unfortunately, we need these to avoid ambiguities
function Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:SimpleAxis}
    return promote_rule(Y,UnitRange{T1})
end
function Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:Axis}
    return promote_rule(Y,UnitRange{T1})
end

const PaddedAxis{PA<:AxisPads,P} = Axis{PA,P}

