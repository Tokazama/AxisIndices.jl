
module NamedAxes

using StaticRanges
using NamedDims
using ArrayInterface
using AxisIndices.Interface
using AxisIndices.Axes

using AxisIndices.Arrays
using AxisIndices.Arrays: ArrayInitializer

using EllipsisNotation
using EllipsisNotation: Ellipsis

using MappedArrays
using MappedArrays: ReadonlyMultiMappedArray, MultiMappedArray, ReadonlyMappedArray

using Base: @propagate_inbounds, ReinterpretArray, tail

export 
    NamedAxisArray,
    NamedCartesianAxes,
    NamedLinearAxes,
    has_dimnames,
    named_axes,
     # NamedDims API
    dim,
    dimnames,
    @defdim

include("dimnames.jl")
include("defdim.jl")
include("NamedAxisArray.jl")

end