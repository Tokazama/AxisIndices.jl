
module AxisIndices

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end AxisIndices

using Reexport
using StaticRanges
using ChainedFixes
using IntervalSets

export
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    AxisRow,
    AxisTable,
    CartesianAxes,
    CenteredAxis,
    Indices,
    Keys,
    LinearAxes,
    MetaAxis,
    SimpleAxis,
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
    srange,
    mrange,
    structview,
    and, ⩓, or, ⩔,
    ..,
    pretty_array

include("./Interface/Interface.jl")
@reexport using .Interface
using .Interface: step_key, append_axis!

include("./Styles/Styles.jl")
using .Styles
using .Styles: to_index, to_keys

include("./PrettyArrays/PrettyArrays.jl")
using .PrettyArrays

include("./Axes/Axes.jl")
using .Axes
using .Axes: permute_axes, cat_axis, cat_axes, hcat_axes, vcat_axes, combine_axis


include("./Arrays/Arrays.jl")
@reexport using .Arrays

include("./ObservationDims.jl")
using .ObservationDims

include("./Tabular/Tabular.jl")
using .Tabular

end
