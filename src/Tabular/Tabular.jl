
# TODO indexing needs more consistent system
# - get generators working with AxisIndices
module Tabular

using StaticArrays
using StaticRanges
using AxisIndices.Styles
using AxisIndices.Interface
using AxisIndices.Axes
using AxisIndices.Axes: to_axis
using AxisIndices.Arrays
using AxisIndices.Arrays: unsafe_getindex
using PrettyTables
using Tables
using TableTraits
using TableTraitsUtils

using Base: @propagate_inbounds

export Table, TableRow

include("AbstractTable.jl")
include("Table.jl")
include("TableRow.jl")
include("indexing.jl")

end

