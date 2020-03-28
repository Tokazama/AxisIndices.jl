module AxisIndices

using StaticRanges
using Statistics
using Dates
using IntervalSets
using MappedArrays
using PrettyTables
using LinearAlgebra
using Base: @propagate_inbounds, OneTo, to_index, tail, front, Fix2
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown
using Base.Cartesian
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi, F2Eq

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
    NamedIndicesArray,
    NIArray,
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
    dimnames,
    dim,
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

include("./ResizeVectors/ResizeVectors.jl")
using .ResizeVectors

include("./AxisIndexing/AxisIndexing.jl")
using .AxisIndexing

include("./AxisIndicesArrays/AxisIndicesArrays.jl")
using .AxisIndicesArrays

include("./NamedIndicesArrays/NamedIndicesArrays.jl")
using .NamedIndicesArrays

end
