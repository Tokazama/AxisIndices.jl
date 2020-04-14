
module AxisCore

using StaticRanges
using IntervalSets
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base: @propagate_inbounds, OneTo, tail, front, Fix2
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type,
    checkindexlo, checkindexhi, OneToUnion

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
    KeyedAxis,
    IndexedAxis,
    # Traits
    AxisIndicesStyle,
    KeyElement,
    IndexElement,
    BoolElement,
    CartesianElement,
    KeysCollection,
    IndicesCollection,
    IntervalCollection,
    BoolsCollection,
    KeysIn,
    KeyEquals,
    KeysFix2,
    SliceCollection,
    # methods
    axes_keys,
    first_key,
    step_key,
    last_key,
    similar_axis,
    similar_axes,
    promote_axis_collections,
    keys_type,
    indices,
    values_type,
    is_element,
    is_index,
    is_collection,
    is_key,
    to_index,
    to_keys,
    unsafe_reconstruct,
    maybetail,
    to_axis,
    true_axes

include("abstractaxis.jl")
include("utils.jl")
include("axis.jl")
include("simpleaxis.jl")
include("keyedaxis.jl")
include("indexedaxis.jl")
include("abstractaxisindices.jl")
include("axisindicesarray.jl")
include("styles.jl")
include("promotion.jl")
include("show.jl")

to_axis(axis::AbstractAxis) = axis
to_axis(axis::OneTo) = SimpleAxis(axis)
to_axis(axis::AbstractVector) = Axis(axis)

end

