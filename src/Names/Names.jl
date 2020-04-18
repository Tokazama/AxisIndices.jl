
module Names

using StaticRanges
using NamedDims
using AxisIndices.PrettyArrays
using AxisIndices.AxisCore
using Base: @propagate_inbounds

export
    NamedIndicesArray,
    NIArray,
    dim,
    dimnames,
    named_axes,
    @defdim

include("niarray.jl")
include("defdim.jl")

end

