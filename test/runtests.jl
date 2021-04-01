
using AbstractFFTs
using Test
using Statistics
using StaticRanges
using NamedDims
using IntervalSets
using FFTW
using LinearAlgebra
using MappedArrays
using Dates
using Documenter
using StaticArrays
using ArrayInterface
using ArrayInterface: indices, known_length, StaticInt, known_first, known_last, known_length
using ArrayInterface.Static

#=
using Dates,MappedArrays,Statistics,LinearAlgebra,Base,Core
pkgs = (Dates,MappedArrays,Statistics,LinearAlgebra,Base,Core);
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
using AxisIndices: cat_axis, hcat_axes, vcat_axes, matmul_axes
using AxisIndices: CenteredAxis, OffsetAxis, StructAxis, SimpleAxis, KeyedAxis, PaddedAxis
using AxisIndices: DUnitRange, DOneTo, SOneTo, UnitSRange
using AxisIndices: OffsetVector
using StaticRanges: parent_type

using ArrayInterface: to_axes, to_index
using Base: step_hp, OneTo
using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()

@test Base.to_shape(SimpleAxis(1)) == 1
include("axes.jl")

#=
include("indexing.jl")
include("abstract_axis.jl")
include("offset_axis.jl")
include("struct_axis.jl")
include("padded_axis.jl")
include("arrays.jl")
include("similar_tests.jl")

include("axis.jl")
=#

#= TODO test append_axis!
@testset "append tests" begin
    @test append_axis!(CombineStack(), [1, 2], [3, 4]) == [1, 2, 3, 4]
    @test_throws ErrorException append_axis!(CombineStack(), 1:3, 3:4)
end
=#
include("linear_algebra.jl")
include("copyto_tests.jl")
include("permutedims.jl")
include("closest.jl")

include("broadcasting_tests.jl")
@testset "CartesianAxes" begin
    cartaxes = CartesianAxes((2.0:5.0, 1:4))
    cartinds = CartesianIndices((1:4, 1:4))
    for (axs, inds) in zip(collect(cartaxes), collect(cartinds))
        @test axs == inds
    end

    for (axs, inds) in zip(cartaxes, cartinds)
        @test axs == inds
    end

    @test collect(cartaxes) == cartaxes[1:4, 1:4]
end

@testset "LinearAxes" begin
    linaxes = LinearAxes((2.0:5.0, 1:4))
    lininds = LinearIndices((1:4, 1:4))
    @test @inferred(linaxes[10]) == 10
    for (axs, inds) in zip(collect(linaxes), collect(lininds))
        @test axs == inds
    end

    for (axs, inds) in zip(linaxes, lininds)
        @test axs == inds
    end
    @test collect(linaxes) == linaxes[1:4,1:4]
end

@test first(axes(@inferred(filter(isodd, AxisArray(1:7, (2:8,)))), 1)) == 2
@test axes(filter(isodd, AxisArray([11 12; 21 22], (2:3, 3:4))), 1) isa AbstractAxis
include("mapped_arrays.jl")
#include("offset_array_tests.jl")
include("resize_tests.jl")
include("fft.jl")

if VERSION >= v"1.6.0-DEV.421"
    @testset "docs" begin
        doctest(AxisIndices)
    end
end

#include("NamedMetaAxisArray_tests.jl")

