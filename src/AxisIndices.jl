
module AxisIndices

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end AxisIndices

using Reexport

export AxisArray

include("./CoreIndexing/CoreIndexing.jl")
@reexport using .CoreIndexing


#=
using Reexport
using StaticRanges
using ChainedFixes
using IntervalSets

export
    Indices,
    Keys,
    LinearAxes,
    # Reexport types
    LinMRange,
    LinSRange,
    OneToRange,
    OneToMRange,
    OneToSRange,
    StepMRangeLen,
    StepSRangeLen,
    StepMRange,
    StepSRange,
    UnitMRange,
    UnitSRange,
    # methods
    srange,
    mrange,
    struct_view,
    and, ⩓, or, ⩔,
    pretty_array

export ..


include("./Styles/Styles.jl")
using .Styles

include("./Interface/Interface.jl")
@reexport using .Interface
using .Interface: step_key, append_axis!, to_axis, to_axes,  to_index, to_keys
using .Interface: assign_indices

include("./Axes/Axes.jl")
@reexport using .Axes
using .Axes: permute_axes, cat_axis, cat_axes, hcat_axes, vcat_axes, combine_axis

include("./Arrays/Arrays.jl")
@reexport using .Arrays
using .Arrays: matmul_axes, get_factorization

include("./NamedAxes/NamedAxes.jl")
@reexport using .NamedAxes

include("./Meta/Meta.jl")
@reexport using .Meta

#include("./PrettyArrays/PrettyArrays.jl")
#using .PrettyArrays

include("./OffsetAxes/OffsetAxes.jl")
@reexport using .OffsetAxes

#include("./PaddedViews/PaddedViews.jl")
#using .PaddedViews

###
### Generate show methods
###

#=
PrettyArrays.@assign_show AxisArray

PrettyArrays.@assign_show NamedAxisArray

PrettyArrays.@assign_show MetaAxisArray

PrettyArrays.@assign_show NamedMetaAxisArray

PrettyArrays.@assign_show CartesianAxes

PrettyArrays.@assign_show LinearAxes

PrettyArrays.@assign_show NamedCartesianAxes

PrettyArrays.@assign_show NamedLinearAxes

PrettyArrays.@assign_show MetaCartesianAxes

PrettyArrays.@assign_show MetaLinearAxes

PrettyArrays.@assign_show NamedMetaCartesianAxes

PrettyArrays.@assign_show NamedMetaLinearAxes

###
### Overload property methods for metadata
###

Meta.@metadata_properties NamedMetaLinearAxes

Meta.@metadata_properties NamedMetaCartesianAxes

Meta.@metadata_properties NamedMetaAxisArray

=#
=#

end

