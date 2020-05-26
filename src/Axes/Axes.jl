module Axes

using MappedArrays
using StaticArrays
using StaticRanges
using AxisIndices.Interface
using AxisIndices.Interface: to_index, maybe_tail, unsafe_reconstruct, to_keys, check_axis_length


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

include("abstractaxis.jl")
include("mutate.jl")
include("axis_traits.jl")
include("axis.jl")
include("simpleaxis.jl")
include("structaxis.jl")
include("metaaxis.jl")
include("promotion.jl")
include("promote_axis_collections.jl")
include("to_axis.jl")
include("to_axes.jl")
include("indexing.jl")
include("broadcast.jl")
include("cat_axis.jl")
include("permute_axes.jl")

end
