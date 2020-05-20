
module AxisIndices

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end AxisIndices

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
    Indices,
    Keys,
    # Reexport types
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
    dimnames,
    dim,
    # methods
    parent_type,
    srange,
    mrange,
    values_type,
    keys_type,
    first_key,
    last_key,
    colaxis,
    colkeys,
    rowaxis,
    rowkeys,
    and,
    ⩓,
    or,
    ⩔,
    ..,
    indices,
    axes_keys,
    pretty_array,
    # traits,
    is_simple_axis

include("./PrettyArrays/PrettyArrays.jl")
using .PrettyArrays

include("./AxisCore/AxisCore.jl")
using .AxisCore

include("./OffsetAxes/OffsetAxes.jl")
using .OffsetAxes

include("./Math/Math.jl")
using .Math

include("./Mapped/Mapped.jl")
using .Mapped

include("./Names/Names.jl")
using .Names

include("./ObservationDims.jl")
using .Names

include("./StructAxes/StructAxes.jl")
using .StructAxes

include("./AxisTables/AxisTables.jl")
using .AxisTables

end
