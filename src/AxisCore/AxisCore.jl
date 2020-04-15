
module AxisCore

using AxisIndices.PrettyArrays
using IntervalSets
using StaticRanges
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type,
    checkindexlo, checkindexhi, OneToUnion
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base: @propagate_inbounds, OneTo, tail, front, Fix2
export
    AbstractAxisIndices,
    AbstractAxisIndicesMatrix,
    AbstractAxisIndicesVector,
    AbstractAxisIndicesVecOrMat,
    AxisIndicesArray,
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    SimpleAxis,
    # methods
    axes_keys,
    first_key,
    step_key,
    last_key,
    similar_axis,
    similar_axes,
    keys_type,
    indices,
    values_type,
    unsafe_reconstruct,
    maybetail,
    to_axis,
    true_axes

include("abstractaxis.jl")
include("utils.jl")
include("axis.jl")
include("simpleaxis.jl")
include("abstractaxisindices.jl")
include("axisindicesarray.jl")
include("promotion.jl")
include("show.jl")

to_axis(axis::AbstractAxis) = axis
to_axis(axis::OneTo) = SimpleAxis(axis)
to_axis(axis::AbstractVector) = Axis(axis)

end

