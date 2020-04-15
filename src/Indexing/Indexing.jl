
module Indexing

using StaticRanges
using AxisIndices.AxisCore
using AxisIndices.AxisIndicesStyles
using Base: @propagate_inbounds, OneTo, tail

export
    CartesianAxes,
    LinearAxes,
    to_axes


include("linearaxes.jl")
include("cartesianaxes.jl")
include("to_axes.jl")
include("to_indices.jl")
include("checkbounds.jl")
include("getindex.jl")

end
