module AxisIndexing

using AxisIndices.AxisIndicesStyles
using NamedDims
using StaticRanges, IntervalSets
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi
using StaticRanges: OneToUnion
using Base: @propagate_inbounds, OneTo, tail, front, Fix2

using StaticRanges:
    prev_type,
    next_type,
    grow_first,
    grow_first!,
    grow_last,
    grow_last!,
    shrink_first,
    shrink_first!,
    shrink_last,
    shrink_last!,
    resize_first,
    resize_first!,
    resize_last,
    resize_last!

export
    # Types
    AbstractAxes,
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    SimpleAxis,
    # traits
    CombineStyle,
    CombineAxis,
    CombineSimpleAxis,
    CombineResize,
    CombineStack,
    # methods
    append_axis!,
    axes_keys,
    axes_type,
    as_axis,
    as_axes,
    broadcast_axis,
    diagonal_axes,
    cat_axis,
    cat_axis!,
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
    to_axis,
    to_axes,
    maybe_unsafe_reconstruct,
    to_index,
    to_key

include("abstractaxis.jl")
include("utils.jl")
include("to_index.jl")
include("to_indices.jl")

include("similar.jl")

include("combine.jl")
include("find.jl")
include("indexing.jl")
include("pop.jl")
include("popfirst.jl")

include("broadcast_axis.jl")
include("append_axes.jl")
include("dimensions.jl")
include("reduce_axes.jl")

include("axis.jl")
include("simpleaxis.jl")
include("to_axis.jl")
include("promotion.jl")

end
