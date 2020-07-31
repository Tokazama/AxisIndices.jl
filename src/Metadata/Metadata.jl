"""
    Metadata

Module that formally defines interface for retreiving and setting metadata.
"""
module Metadata

using NamedDims
using StaticRanges
using ArrayInterface
using ArrayInterface: parent_type

using AxisIndices.Interface
using AxisIndices.Axes
using AxisIndices.Arrays

using AxisIndices.Arrays: ArrayInitializer

using EllipsisNotation: Ellipsis

using Base: @propagate_inbounds

export
    MetaAxis,
    MetaAxisArray,
    MetaCartesianAxes,
    MetaLinearAxes,
    NamedAxisArray,
    NamedMetaAxisArray,
    NamedMetaCartesianAxes,
    NamedMetaLinearAxes,
    has_metadata,
    has_metaproperty,
    axis_meta,
    axis_metaproperty,
    axis_metaproperty!,
    metadata,
    metaproperty,
    metaproperty!,
    metadata_type

import MetadataArrays: MetadataArray

include("interface.jl")
include("MetaAxis.jl")
include("MetaCartesianAxes.jl")
include("MetaLinearAxes.jl")
include("MetaAxisArray.jl")
include("NamedMetaAxisArray.jl")
include("NamedMetaCartesianAxes.jl")
include("NamedMetaLinearAxes.jl")

end
