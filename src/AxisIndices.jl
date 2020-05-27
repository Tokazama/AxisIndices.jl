
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
    AbstractAxisArray,
    AxisArray,
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    AxisRow,
    AxisTable,
    SimpleAxis,
    CartesianAxes,
    LinearAxes,
    NamedAxisArray,
    Indices,
    Keys,
    StructAxis,
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
    indices_type,
    keys_type,
    first_key,
    last_key,
    rowaxis,
    rowkeys,
    rowtype,
    colaxis,
    colkeys,
    coltype,
    structview,
    and,
    ⩓,
    or,
    ⩔,
    ..,
    indices,
    axes_keys,
    pretty_array,
    # traits,
    is_indices_axis

include("./PrettyArrays/PrettyArrays.jl")
using .PrettyArrays

include("./Interface/Interface.jl")
using .Interface
using .Interface: to_index, to_keys

include("./Axes/Axes.jl")
using .Axes
using .Axes: permute_axes

include("./Arrays/Arrays.jl")
using .Arrays

include("./ObservationDims.jl")
using .ObservationDims

include("./Tabular/Tabular.jl")
using .Tabular

end
