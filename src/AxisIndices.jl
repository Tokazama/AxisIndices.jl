
module AxisIndices

using StaticRanges
using Statistics
using Dates
using IntervalSets
using MappedArrays
using PrettyTables
using LinearAlgebra
using Base: @propagate_inbounds, OneTo, tail, front, Fix2
using Base.Cartesian
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type, checkindexlo, checkindexhi

export
    # Modules
    # Interface,
    # Indexing,
    # Arrays,
    # Math,
    # Names,
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
    NamedDimsArray,
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
    ..,
    indices,
    reindex,
    axes_keys,
    pretty_array

include("./PrettyArrays/PrettyArrays.jl")
using .PrettyArrays

include("./AxisCore/AxisCore.jl")
using .AxisCore

include("./Indexing/Indexing.jl")
using .Indexing

include("./Basics/Basics.jl")
using .Basics

include("./Math/Math.jl")
using .Math

include("./Mapped/Mapped.jl")
using .Mapped

include("./Names/Names.jl")
using .Names

end

