module AxisIndices

using StaticRanges, LinearAlgebra, Statistics, Dates
using Base: @propagate_inbounds, OneTo, to_index, tail, front
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

export
    AxisIndicesArray,
    Axis,
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
    srange,
    mrange,
    values_type,
    keys_type



include("./AxisInterface/AxisInterface.jl")
include("array.jl")
include("show.jl")
include("functions.jl")
include("functions_dims.jl")
include("functions_math.jl")
include("broadcast.jl")

end
