module AxisIndexing

using AxisIndices.ResizeVectors
using StaticRanges, IntervalSets
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi, F2Eq
using Base: @propagate_inbounds, OneTo, to_index, tail, front, Fix2

export
    # Types
    AbstractAxes,
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    SimpleAxis,
    # methods
    append_axis!,
    axes_keys,
    axes_type,
    as_axis,
    as_axes,
    broadcast_axis,
    diagonal_axes,
    cat_axis,
    vcat_axes,
    hcat_axes,
    covcor_axes,
    drop_axes,
    dioganal_axes,
    first_key,
    indices,
    last_key,
    keys_type,
    matmul_axes,
    permute_axes,
    reduce_axes,
    reduce_axis,
    reindex,
    rotl90_axes,
    rotr90_axes,
    rot180_axes,
    reverse_keys,
    step_key,
    values_type,
    indices,
    reindex,
    unsafe_reindex,
    unsafe_reconstruct,
    maybe_unsafe_reconstruct

include("indexer_style.jl")
include("abstractaxis.jl")
include("staticness.jl")
include("combine.jl")
include("keys.jl")
include("values.jl")
include("show.jl")
include("find.jl")
include("to_index.jl")
include("to_indices.jl")
include("getindex.jl")
include("reindex.jl")
include("checkindex.jl")
include("first.jl")
include("step.jl")
include("last.jl")
include("length.jl")
include("pop.jl")
include("popfirst.jl")

include("broadcast_axis.jl")
include("append_axes.jl")
include("matmul_axes.jl")
include("diagonal_axes.jl")
include("permute_axes.jl")
include("rotate_axes.jl")
include("drop_axes.jl")
include("cat_axes.jl")
include("covcor_axes.jl")
include("reduce_axes.jl")

include("axis.jl")
include("simpleaxis.jl")
include("as_axis.jl")
include("promotion.jl")

end
