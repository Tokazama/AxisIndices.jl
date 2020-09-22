"""
    OffsetAxes

The `OffsetAxes` module provides the [`CenteredAxis`](@ref), [`IdentityAxis`],
and [`OffsetAxis`](@ref) types, with the respective array types [`CenteredArray`](@ref),
[`IdentityArray`](@ref), [`OffsetArray`](@ref). All of these array types are aliases
for the `AxisArray` type with the type of the axes specified for a certain type of
offset. Alternatively, the [`center`](@ref), [`idaxis`](@ref), and [`offset`](@ref) can
be used as shorthand for specifying that a specific axis of an `AxisArray` has ceretain
type of offset indexing behavior.
"""
module OffsetAxes

using AxisIndices.Styles
using AxisIndices.Interface
using AxisIndices.Interface: unsafe_reconstruct, check_axis_length, maybe_tail, naxes, check_axis_length
using AxisIndices.Interface: append_axis!
using AxisIndices.Interface: to_axis, to_axes, to_index, assign_indices


using AxisIndices.Axes

using AxisIndices.Arrays
using AxisIndices.Arrays: ArrayInitializer

using ArrayInterface
using ArrayInterface: known_first, known_last

using StaticRanges
using StaticRanges: OneToUnion
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type
using StaticRanges: checkindexlo, checkindexhi
using StaticRanges: grow_first!, grow_last!
using StaticRanges: resize_last, resize_last!, resize_first, resize_first!
using StaticRanges: shrink_last!

using Base: @propagate_inbounds, OneTo, tail

export
    CenteredArray,
    CenteredAxis,
    CenteredVector,
    IdentityArray,
    IdentityAxis,
    IdentityVector,
    OffsetArray,
    OffsetAxis,
    OffsetVector,
    center,
    offset,
    idaxis


include("AbstractOffsetAxis.jl")

include("CenteredAxis.jl")
include("IdentityAxis.jl")
include("OffsetAxis.jl")

include("CenteredArray.jl")
include("IdentityArray.jl")
include("OffsetArray.jl")

end
