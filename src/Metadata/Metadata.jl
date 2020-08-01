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
using AxisIndices.NamedAxes

using AxisIndices.Arrays: ArrayInitializer

using EllipsisNotation: Ellipsis

using Base: @propagate_inbounds, Fix2

export
    MetadataArray,
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
    meta,
    metadata,
    metaproperty,
    metaproperty!,
    metadata_type


include("MetadataArray.jl")
include("interface.jl")
include("MetaAxis.jl")
include("MetaCartesianAxes.jl")
include("MetaLinearAxes.jl")
include("MetaAxisArray.jl")
include("NamedMetaAxisArray.jl")
include("NamedMetaCartesianAxes.jl")
include("NamedMetaLinearAxes.jl")

macro metadata_properties(T)
    quote
        @inline Base.getproperty(x::$T, k::Symbol) = Metadata.metaproperty(x, k)

        @inline Base.setproperty!(x::$T, k::Symbol, val) = Metadata.metaproperty!(x, k, val)

        @inline Base.propertynames(x::$T) = Metadata.metanames(x)
    end
end

end
