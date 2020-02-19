using AxisIndices, Test, Statistics, LinearAlgebra, StaticRanges, Documenter
using Base: step_hp, OneTo


using StaticRanges: can_set_first, can_set_last, can_set_length


using AxisIndices: matmul_axes

include("AxisInterface/runtests.jl")
include("functions_dims_tests.jl")
include("functions_maths_tests.jl")
include("functions_tests.jl")

@testset "docs" begin
    doctest(AxisIndices; manual=false)
end
