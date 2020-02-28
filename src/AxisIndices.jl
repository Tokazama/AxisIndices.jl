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
    keys_type,
    and,
    or

include("./AxisInterface/AxisInterface.jl")
include("checkbounds.jl")
include("array.jl")
include("indexing.jl")
include("show.jl")
include("functions.jl")
include("reduce.jl")
include("permutedims.jl")
include("dropdims.jl")
include("inv.jl")
include("covcor.jl")
include("matmul.jl")
include("mutate.jl")
include("broadcast.jl")
include("./LinearAlgebra/LinearAlgebra.jl")

end