

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

struct InitReflectPads <: PaddedInitializer end
const reflect_pad = InitReflectPads()

struct InitOrigin <: AxisInitializer end
const center = InitOrigin()
center(collection::AbstractArray) = AxisOrigin()(collection)

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

