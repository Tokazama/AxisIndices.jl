module AxisIndices

using StaticRanges, LinearAlgebra, Statistics, Dates, IntervalSets
using MappedArrays, PrettyTables
using Base: @propagate_inbounds, OneTo, to_index, tail, front, Fix2
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base.Cartesian
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi, F2Eq

import Base: rot180, rotr90, rotl90

export
    # Types
    AbstractAxisIndices,
    AxisIndicesArray,
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    SimpleAxis,
    CartesianAxes,
    LinearAxes,
    # Reexport types
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
    PromoteStyle,
    PromoteConvert,
    PromoteAxis,
    PromoteSimpleAxis,
    # methods
    srange,
    mrange,
    values_type,
    keys_type,
    first_key,
    last_key,
    and,
    ⩓,
    or,
    ⩔,
    indices,
    reindex,
    axes_keys,
    pretty_array

include("abstractaxis.jl")
include("abstractarray.jl")
include("traits.jl")
include("indexing.jl")
include("broadcast_axis.jl")
include("cat_axis.jl")
include("append_axis.jl")
include("functions.jl")
include("cat.jl")
include("reduce.jl")
include("dimensions.jl")
include("mutate.jl")
include("promotion.jl")
include("broadcast.jl")
include("linear_algebra.jl")
include("io.jl")
include("mapped_arrays.jl")
include("nameddims.jl")

end
