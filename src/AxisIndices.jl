module AxisIndices

using StaticRanges, LinearAlgebra, Statistics, Dates, PrettyTables
using Base: @propagate_inbounds, OneTo, to_index, tail, front
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base.Cartesian
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi

export
    AbstractAxisIndices,
    AxisIndicesArray,
    Axis,
    SimpleAxis,
    LinMRange,
    LinSRange,
    OneToRange,
    OneToMRange,
    OneToSRange,
    AbstractStepRangeLen,
    StepMRangeLen,
    StepSRangeLen,
    AbstractStepRange,
    StepMRange,
    StepSRange,
    UnitMRange,
    UnitSRange,
    # methods
    srange,
    mrange,
    values_type,
    keys_type,
    and,
    or,
    indices,
    pretty_array



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
include("abstractarray.jl")
include("indexing.jl")
include("functions.jl")
include("cat.jl")
include("reduce.jl")
include("dimensions.jl")
include("mutate.jl")
include("promotion.jl")
include("broadcast.jl")
include("linear_algebra.jl")
include("io.jl")

end
