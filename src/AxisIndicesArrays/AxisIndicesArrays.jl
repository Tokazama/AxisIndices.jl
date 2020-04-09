
module AxisIndicesArrays

using LinearAlgebra
using Statistics
using StaticRanges
using MappedArrays
using PrettyTables
using AxisIndices.AxisIndexing
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base: @propagate_inbounds, OneTo, tail, front, Fix2, to_index
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi
using StaticRanges:
    prev_type,
    next_type,
    grow_first,
    grow_first!,
    grow_last,
    grow_last!,
    shrink_first,
    shrink_first!,
    shrink_last,
    shrink_last!,
    resize_first,
    resize_first!,
    resize_last,
    resize_last!


export
    AbstractAxisIndices,
    AxisIndicesArray,
    pretty_array,
    LinearAxes,
    CartesianAxes,
    get_factorization

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
include("statistics.jl")
include("arraymath.jl")
include("mapped_arrays.jl")

end
