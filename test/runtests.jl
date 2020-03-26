using AxisIndices, Test, Statistics, LinearAlgebra, StaticRanges, Documenter, Dates
using AxisIndices: resize_last, resize_last!, resize_first, resize_first!, reduce_axis
using AxisIndices: shrink_last, shrink_last!, grow_last, grow_last!
using AxisIndices: mappedarray, of_eltype, matmul_axes # from MappedArrays
using StaticRanges: can_set_first, can_set_last, can_set_length

# test deps
using FixedPointNumbers, ColorTypes

using Base: step_hp, OneTo

include("AxisInterface/runtests.jl")
include("staticness_tests.jl")
include("checkbounds.jl")
include("functions_dims_tests.jl")
include("math_tests.jl")

include("functions_tests.jl")
include("concatenation_tests.jl")
include("array_tests.jl")
include("broadcasting_tests.jl")
include("linear_algebra.jl")

include("mapped_arrays.jl")
include("nameddims_tests.jl")


# TODO this needs to be formally tested
io = IOBuffer()
pretty_array(io, AxisIndicesArray(reshape(1:33, (1, 11, 3))))
str = String(take!(io))
@test str == "[dim1, dim2, dim3[1]] =\n          1       2       3       4       5       6       7       8       9       10       11  \n  1   1.000   2.000   3.000   4.000   5.000   6.000   7.000   8.000   9.000   10.000   11.000  \n\n\n[dim1, dim2, dim3[2]] =\n           1        2        3        4        5        6        7        8        9       10       11  \n  1   12.000   13.000   14.000   15.000   16.000   17.000   18.000   19.000   20.000   21.000   22.000  \n\n\n[dim1, dim2, dim3[3]] =\n           1        2        3        4        5        6        7        8        9       10       11  \n  1   23.000   24.000   25.000   26.000   27.000   28.000   29.000   30.000   31.000   32.000   33.000  \n"

@testset "docs" begin
    doctest(AxisIndices)
end
