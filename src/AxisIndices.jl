module AxisIndices

using StaticRanges, LinearAlgebra, Statistics
using StaticRanges: to_axis
using Base: @propagate_inbounds, OneTo, to_index, tail, front
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

export AxisIndicesArray, Axis, SimpleAxis

include("array.jl")
include("show.jl")
include("functions.jl")
include("functions_dims.jl")
include("functions_math.jl")
include("broadcast.jl")

end
