module AxisIndices

using StaticRanges, LinearAlgebra, Statistics, Dates, PrettyTables
using Base: @propagate_inbounds, OneTo, to_index, tail, front
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base.Cartesian
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi

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
    and,
    or,
    indices,
    reindex,
    axes_keys,
    pretty_array

include("abstractaxis.jl")
include("abstractarray.jl")
include("traits.jl")
include("broadcast_axis.jl")
include("cat_axis.jl")
include("append_axis.jl")

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
