
module Basics

using IntervalSets
using StaticRanges
using LinearAlgebra
using AxisIndices.AxisCore
using AxisIndices.AxisIndicesStyles
using AxisIndices.Indexing
using LazyArrays
using LazyArrays: Vcat

using Base: OneTo, Fix2, tail
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

export
    CombineStyle,
    CombineAxis,
    CombineSimpleAxis,
    CombineResize,
    CombineStack,
    CoVector,
    broadcast_axis,
    cat_axis,
    cat_axes,
    hcat_axes,
    vcat_axes,
    append_axis!,
    permute_axes,
    reduce_axes,
    reduce_axis,
    drop_axes,
    promote_axis_collections,
    unwrap_broadcasted
 
include("promote_axis_collections.jl")
include("combine.jl")
include("append.jl")
include("pop.jl")
include("popfirst.jl")
include("find.jl")
include("broadcast_axis.jl")
include("broadcast.jl")
include("dropdims.jl")
include("map.jl")
include("mutate.jl")
include("rotations.jl")
include("reduce.jl")
include("permutedims.jl")
include("arraymath.jl")
include("cat.jl")
include("io.jl")

end

