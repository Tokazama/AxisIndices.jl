module OffsetAxes

using AxisIndices
using AxisIndices: AxisCore
using AxisIndices: AxisIndicesStyle, IndicesCollection, IndexElement, KeyElement, KeysCollection
using AxisIndices: unsafe_reconstruct
using StaticRanges
using StaticRanges: similar_type, OneToUnion
using Base: OneTo, @propagate_inbounds, tail

export
    AbstractOffsetAxis,
    CenteredArray,
    CenteredAxis,
    CenteredVector,
    IdentityUnitRange,
    OffsetArray,
    OffsetAxis,
    OffsetVector,
    offset

@static if !isdefined(Base, :IdentityUnitRange)
    const IdentityUnitRange = Base.Slice
else
    using Base: IdentityUnitRange
end

include("abstractoffsetaxis.jl")

include("offsetaxis.jl")
include("offsetarray.jl")

include("centeredaxis.jl")
include("centeredarray.jl")

include("identityaxis.jl")

end
