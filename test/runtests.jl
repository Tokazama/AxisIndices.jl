
using Test
using Statistics
using StaticRanges
using NamedDims
using IntervalSets
using LinearAlgebra
using MappedArrays
using Dates
using Documenter

#=
pkgs = (Documenter,Dates,MappedArrays,Statistics,TableTraits,TableTraitsUtils,LinearAlgebra,Tables,IntervalSets,NamedDims,StaticRanges,StaticArrays,Base,Core);
ambs = detect_ambiguities(pkgs...);
using AxisIndices
ambs = setdiff(detect_ambiguities(AxisIndices, pkgs...), ambs);

unique([i[1].name for i in ambs])
for amb_i in ambs
    if amb_i[1].name == :CartesianIndices
        print(amb_i)
    end
end

inds = [i[1].name == :copyto! for i in ambs]
ambs[[i[1].name == :mapreduce for i in ambs]]

itr[1].name
unique([itr[1].name for itr in ambs])

if !isempty(ambs)
    println("Ambiguities:")
    for a in ambs
        println(a)
    end
=#

using DelimitedFiles
using AxisIndices
using AxisIndices.CoreIndexing: to_index, is_key, cat_axis, hcat_axes, vcat_axes, to_axes, matmul_axes
using StaticRanges: can_set_first, can_set_last, can_set_length, parent_type
using StaticRanges: grow_last, grow_last!, grow_first, grow_first!
using StaticRanges: shrink_last, shrink_last!, shrink_first, shrink_first!, has_offset_axes
#using AxisIndices.Interface: IdentityUnitRange

using Base: step_hp, OneTo
using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()


@test Base.to_shape(SimpleAxis(1)) == 1

include("styles_tests.jl")

#include("./Interface/Interface.jl")
include("./Axes/Axes.jl")
include("./Arrays/Arrays.jl")
include("./OffsetAxes/OffsetAxes.jl")

include("getindex_tests.jl")
include("size_tests.jl")
include("pop_tests.jl")
include("popfirst_tests.jl")
include("first_tests.jl")
include("step_tests.jl")
include("last_tests.jl")
include("length_tests.jl")
include("cartesianaxes.jl")
include("linearaxes.jl")
include("append_tests.jl")
include("filter_tests.jl")
include("promotion_tests.jl")
include("similar_tests.jl")
include("resize_tests.jl")
include("staticness_tests.jl")
include("checkbounds.jl")
include("functions_dims_tests.jl")
include("math_tests.jl")
include("drop_tests.jl")
include("constructors.jl")
include("functions_tests.jl")
include("concatenation_tests.jl")
include("array_tests.jl")
include("broadcasting_tests.jl")
include("linear_algebra.jl")

include("mapped_arrays.jl")
include("traits_tests.jl")
include("copyto_tests.jl")
include("reshape_tests.jl")

include("NamedAxisArray_tests.jl")
include("MetaAxisArray_tests.jl")
include("NamedMetaAxisArray_tests.jl")
include("offset_tests.jl")

@testset "pretty_array" begin
    A = AxisArray(Array{Int,0}(undef, ()))
    @test pretty_array(String, A) == repr(A[1])
end

#include("offset_array_tests.jl")
F = svd(AxisArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))));
io = IOBuffer()
show(io, F)
str = String(take!(io))
@test str[1:7] == "AxisSVD"

# TODO Change to 1.5 once beta is fix is released
if VERSION > v"1.4"
    @testset "docs" begin
        doctest(AxisIndices)
    end
end

