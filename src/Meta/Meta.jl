"""
    Metadata

Module that formally defines interface for retreiving and setting metadata.
"""
module Meta

using Metadata
using Metadata: MetaArray

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
    MetaAxisArray,
    MetaCartesianAxes,
    MetaLinearAxes,
    NamedMetaAxisArray,
    NamedMetaCartesianAxes,
    NamedMetaLinearAxes

include("MetaAxisArray.jl")

macro metadata_properties(T)
    quote
        @inline Base.getproperty(x::$T, k::Symbol) = Metadata.metaproperty(x, k)

        @inline Base.setproperty!(x::$T, k::Symbol, val) = Metadata.metaproperty!(x, k, val)

        @inline Base.propertynames(x::$T) = Metadata.metanames(x)
    end
end

end
