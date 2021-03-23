

(init::AxisInitializer)(x) = Base.Fix2(init, x)
(init::AxisInitializer)(collection::AbstractRange, x) = init(x)(collection)
(init::AxisInitializer)(collection, x) = init(x)(collection)
function (init::AxisInitializer)(collection::AbstractRange, x::Tuple)
    if ndims(collection) !== length(x)
        throw(DimensionMismatch("Number of axis arguments provided ($(length(x))) does " *
                                "not match number of collections's axes ($(ndims(collection)))."))
    end
    if known_step(collection) === 1
        return init(first(x))(collection)
    else
        return AxisArray(collection, map(init, x))
    end
end
function (init::AxisInitializer)(collection, x::Tuple)
    if ndims(collection) !== length(x)
        throw(DimensionMismatch("Number of axis arguments provided ($(length(x))) does " *
                                "not match number of collections's axes ($(ndims(collection)))."))
    end
    return AxisArray(collection, map(init, x))
end

# TODO can do better than this
(p::PaddedInitializer)(x::Tuple) = y -> p(y; first_pad=first(x), last_pad=last(x))
(p::PaddedInitializer)(fp::Integer, lp::Integer) = param(p)(Pads(fp, lp))
(p::PaddedInitializer)(x::AbstractArray, fp::Integer, lp::Integer) = param(p)(Pads(fp, lp))(x)
(p::PaddedInitializer)(; kwargs...) = param(p)(Pads(; kwargs...))
(p::PaddedInitializer)(x::AbstractArray; kwargs...) = param(p)(Pads(; kwargs...))(x)


struct InitOffset <: AxisInitializer end
const offset = InitOffset()
offset(x::Integer) = AxisOffset(x)

struct InitOrigin <: AxisInitializer end
const center = InitOrigin()
center(collection::AbstractArray) = AxisOrigin()(collection)
center(x::Integer) = AxisOrigin(x)

struct InitReflectPads <: PaddedInitializer end
const reflect_pad = InitReflectPads()

struct InitSymmetricPads <: PaddedInitializer end
const symmetric_pad = InitSymmetricPads()

struct InitCircularPads <: PaddedInitializer end
const circular_pad = InitCircularPads()

struct InitReplicatePads <: PaddedInitializer end
const replicate_pad = InitReplicatePads()


struct InitZeroPads <: PaddedInitializer end
const zero_pad = InitZeroPads()

struct InitNothingPads <: PaddedInitializer end
const nothing_pad = InitNothingPads()

struct InitOnePads <: PaddedInitializer end
const one_pad = InitOnePads()

# TODO replace initialize with to_axis or something
param(::InitOffset) = AxisOffset
param(::InitOrigin) = AxisOrigin
param(::InitZeroPads) = ZeroPads
param(::InitOnePads) = OnePads
param(::InitNothingPads) = NothingPads
param(::InitReplicatePads) = ReplicatePads
param(::InitSymmetricPads) = SymmetricPads
param(::InitCircularPads) = CircularPads
param(::InitReflectPads) = ReflectPads

param(axis::KeyedAxis) = _AxisKeys(getfield(axis, :keys))
param(axis::SimpleAxis) = nothing
param(axis::OffsetAxis) = AxisOffset(getfield(axis, :offset))
param(axis::CenteredAxis) = AxisOrigin(getfield(axis, :origin))
param(axis::PaddedAxis) = getfield(axis, :pads)
param(axis::StructAxis{T}) where {T} = _AxisStruct(T)

reparam(::NothingPads) = NothingPads
reparam(::OnePads) = OnePads
reparam(::ZeroPads) = ZeroPads
reparam(::ReplicatePads) = ReplicatePads
reparam(::SymmetricPads) = SymmetricPads
reparam(::CircularPads) = CircularPads
reparam(::ReflectPads) = ReflectPads


initialize(::Nothing, axis::AbstractUnitRange{Int}) = SimpleAxis(axis)
initialize(p::AxisOrigin, axis::AbstractUnitRange{Int}) = _CenteredAxis(p.origin, axis)
initialize(p::AxisOffset, axis::AbstractUnitRange{Int}) = _OffsetAxis(p.offset, axis)
initialize(p::PadsParameter, axis::AbstractUnitRange{Int}) = _PaddedAxis(p, axis)
initialize(p::AxisKeys, axis::AbstractUnitRange{Int}) = _Axis(p.keys, axis)
initialize(p::AxisStruct{T}, axis::AbstractUnitRange{Int}) where {T} = _StructAxis(T, axis)

initialize(p::PadsParameter, x) = AxisArray(x, ntuple(_ -> p, Val(ndims(x))))
initialize(::Axis, param, axis) = _Axis(param, axis)
initialize(::CenteredAxis, param, axis) = _CenteredAxis(param, axis)
initialize(::OffsetAxis, param, axis) = _CenteredAxis(param, axis)
initialize(::PaddedAxis, param, axis) = _PaddedAxis(param, axis)
initialize(::StructAxis, ::Type{T}, axis) where {T} = _StructAxis(T, axis)

