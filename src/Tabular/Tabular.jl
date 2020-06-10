
# TODO indexing needs more consistent system
# - get generators working with AxisIndices
module Tabular

using StaticArrays
using StaticRanges
using AxisIndices.Styles
using AxisIndices.Interface
using AxisIndices.Interface: to_index, to_axis

using AxisIndices.Axes
using AxisIndices.Axes: unsafe_getindex
using AxisIndices.Arrays
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

