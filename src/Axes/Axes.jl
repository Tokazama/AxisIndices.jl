module Axes

using NamedDims
using MappedArrays
using StaticArrays
using StaticRanges
using AxisIndices.Interface
using AxisIndices.Interface: AbstractIndices
using AxisIndices.Interface: maybe_tail, unsafe_reconstruct, assign_indices
using AxisIndices.Interface: check_axis_length, check_axis_unique
using AxisIndices.Interface: _construct_meta
using AxisIndices.Interface: as_staticness

using AxisIndices.Styles
using AxisIndices.Styles: to_index, to_keys

using AxisIndices.PrettyArrays

using StaticRanges
using StaticRanges: Static, Fixed, Dynamic, Staticness, Length, OneToUnion
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type
using StaticRanges: checkindexlo, checkindexhi
using StaticRanges: grow_first!, grow_last!
using StaticRanges: resize_last, resize_last!, resize_first, resize_first!
using StaticRanges: shrink_last!

import MetadataArrays: MetadataArray

using Base: @propagate_inbounds, tail, OneTo
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle

export
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    CartesianAxes,
    CenteredAxis,
    LinearAxes,
    MetaAxis,
    MetaCartesianAxes,
    MetaLinearAxes,
    NamedCartesianAxes,
    NamedLinearAxes,
    NamedMetaCartesianAxes,
    NamedMetaLinearAxes,
    OffsetAxis,
    SimpleAxis,
    StructAxis,
    structview

include("AbstractAxis.jl")
include("Axis.jl")
include("SimpleAxis.jl")
include("StructAxis.jl")
include("MetaAxis.jl")
include("AbstractOffsetAxis.jl")
include("CenteredAxis.jl")
include("OffsetAxis.jl")
include("mutate.jl")
include("promotion.jl")
include("to_axis.jl")
include("to_axes.jl")
include("indexing.jl")
include("broadcast.jl")
include("combine_axis.jl")
include("cat_axis.jl")
include("permute_axes.jl")

end
