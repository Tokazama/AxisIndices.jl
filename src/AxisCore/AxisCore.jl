
module AxisCore

using ChainedFixes
using IntervalSets
using LinearAlgebra

using LazyArrays
using LazyArrays: Vcat

using StaticRanges
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type,
    checkindexlo, checkindexhi, OneToUnion, grow_first!, grow_last!, resize_last,
    resize_last!, shrink_last!

using AxisIndices.PrettyArrays

using Base: @propagate_inbounds, OneTo, Fix2, tail, front, Fix2
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

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
    similar_axes,
    keys_type,
    indices,
    values_type,
    unsafe_reconstruct,
    maybetail,
    to_axis,
    true_axes,
    assign_indices,
    v2k,
    k2v,
    broadcast_axis,
    cat_axis,
    cat_axes,
    hcat_axes,
    vcat_axes,
    append_axis!,
    permute_axes,
    reduce_axes,
    reduce_axis,
    reconstruct_reduction,
    drop_axes,
    promote_axis_collections,
    unwrap_broadcasted,
    CartesianAxes,
    LinearAxes,
    to_axes,
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
    CombineStyle,
    CombineAxis,
    CombineSimpleAxis,
    CombineResize,
    CombineStack,
    CoVector,
    # methods
    is_element,
    is_index,
    is_collection,
    is_key,
    to_index,
    to_keys


include("abstractaxis.jl")
include("utils.jl")
include("axis.jl")
include("simpleaxis.jl")
include("abstractaxisindices.jl")
include("axisindicesarray.jl")
include("promotion.jl")
include("show.jl")
include("traits.jl")

include("promote_axis_collections.jl")
include("append.jl")
include("pop.jl")
include("popfirst.jl")
include("find.jl")
include("broadcast_axis.jl")
include("broadcast.jl")
include("dropdims.jl")
include("map.jl")
include("mutate.jl")
include("rotations.jl")
include("reduce.jl")
include("permutedims.jl")
include("arraymath.jl")
include("cat.jl")
include("io.jl")

include("linearaxes.jl")
include("cartesianaxes.jl")
include("to_axes.jl")
include("to_indices.jl")
include("checkbounds.jl")
include("getindex.jl")


to_axis(axis::AbstractAxis) = axis
to_axis(axis::OneToUnion) = SimpleAxis(axis)
to_axis(axis::AbstractVector) = Axis(axis)

end

