
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi
using Base.Cartesian

export
    reindex,
    # Combine Indices
    #combine_indices,
    combine_axis,
    combine_values,
    combine_keys,
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    CartesianAxes,
    LinearAxes,
    SimpleAxis,
    # Swapping Axes
    drop_axes,
    permute_axes,
    reduce_axes,
    reduce_axis,
    # Matrix Multiplication and Axes
    matmul_axes,
    inverse_axes,
    covcor_axes,
    # Appending Axes
    append_axes,
    append_keys,
    append_values,
    append_axis,
    append_axis!,
    # Concatenating Axes
    cat_axes,
    hcat_axes,
    vcat_axes,
    cat_axis,
    cat_values,
    cat_keys,
    # Resizing Axes
    resize_first,
    resize_first!,
    resize_last,
    resize_last!,
    grow_first,
    grow_first!,
    grow_last,
    grow_last!,
    shrink_first,
    shrink_first!,
    shrink_last,
    shrink_last!

const KeyIndexType = Union{Symbol,AbstractString,AbstractChar,Dates.AbstractTime}

include("abstractaxis.jl")
include("axisindices.jl")

include("iterate.jl")
include("axis.jl")
include("simpleaxis.jl")
include("reindex.jl")
include("resize.jl")
include("combine.jl")
include("append.jl")
include("cat_axes.jl")
include("to_index.jl")
include("getindex.jl")
include("promotion.jl")

