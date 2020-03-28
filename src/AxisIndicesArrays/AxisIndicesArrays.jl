
module AxisIndicesArrays

using LinearAlgebra
using Statistics
using StaticRanges
using MappedArrays
using PrettyTables
using AxisIndices.ResizeVectors
using AxisIndices.AxisIndexing
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base: @propagate_inbounds, OneTo, to_index, tail, front, Fix2
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi, F2Eq

export
    AbstractAxisIndices,
    AxisIndicesArray,
    pretty_array,
    LinearAxes,
    CartesianAxes

include("abstractaxisindices.jl")
include("axisindicesarray.jl")
include("indexing.jl")
include("broadcast.jl")
include("linearaxes.jl")
include("cartesianaxes.jl")
include("cat.jl")
include("mutate.jl")
include("rotations.jl")
include("map.jl")
include("pretty_array.jl")
include("io.jl")
include("dimensions.jl")
include("linear_algebra.jl")
include("sort.jl")
include("statistics.jl")
include("arraymath.jl")
include("mapped_arrays.jl")

end
