
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
using ArrayInterface: indices, known_length, StaticInt

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
using AxisIndices: is_key, cat_axis, hcat_axes, vcat_axes, matmul_axes
using AxisIndices: CenteredAxis, IdentityAxis, OffsetAxis
using StaticRanges: can_set_first, can_set_last, can_set_length, parent_type
using StaticRanges: grow_last, grow_last!, grow_first, grow_first!
using StaticRanges: shrink_last, shrink_last!, shrink_first, shrink_first!, has_offset_axes
#using AxisIndices.Interface: IdentityUnitRange

using ArrayInterface: to_axes, to_index
using Base: step_hp, OneTo
using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()

@test Base.to_shape(SimpleAxis(1)) == 1

include("simple_axis.jl")
include("axis.jl")
include("abstract_axis.jl")
include("centered_axis.jl")
include("identity_axis.jl")
include("offset_axis.jl")
include("struct_axis.jl")
include("padded_axis.jl")
include("arrays.jl")
include("indexing.jl")
include("append_tests.jl")
include("similar_tests.jl")
include("broadcasting_tests.jl")
include("linear_algebra.jl")
include("copyto_tests.jl")
include("permutedims.jl")
include("closest.jl")

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

@testset "docs" begin
    doctest(AxisIndices)
end

#include("NamedMetaAxisArray_tests.jl")
