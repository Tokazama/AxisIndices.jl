module Axes

using MappedArrays
using StaticArrays
using StaticRanges
using AxisIndices.Interface
using AxisIndices.Interface: to_index, maybe_tail, unsafe_reconstruct, to_keys,
    check_axis_length, assign_indices

using StaticRanges
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type
using StaticRanges: checkindexlo, checkindexhi
using StaticRanges: grow_first!, grow_last!, resize_last, resize_last!, shrink_last!
using StaticRanges: Static, Fixed, Dynamic, Staticness, Length, OneToUnion

using Base: @propagate_inbounds, tail, OneTo
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle

export
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    CartesianAxes,
    LinearAxes,
    SimpleAxis,
    StructAxis,
    to_axis,
    to_axes,
    structview

include("AbstractAxis.jl")
include("mutate.jl")
include("Axis.jl")
include("SimpleAxis.jl")
include("StructAxis.jl")
include("MetaAxis.jl")
include("promotion.jl")
include("to_axis.jl")
include("to_axes.jl")
include("indexing.jl")
include("broadcast.jl")
include("combine_axis.jl")
include("cat_axis.jl")
include("permute_axes.jl")

end
