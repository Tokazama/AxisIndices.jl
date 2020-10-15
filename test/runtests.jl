
using Test
using Statistics
using StaticRanges
using NamedDims
using IntervalSets
using LinearAlgebra
using MappedArrays
using Dates
using Documenter
using StaticArrays
using ArrayInterface
using ArrayInterface: indices, known_length

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
using StaticRanges: can_set_first, can_set_last, can_set_length, parent_type
using StaticRanges: grow_last, grow_last!, grow_first, grow_first!
using StaticRanges: shrink_last, shrink_last!, shrink_first, shrink_first!, has_offset_axes
#using AxisIndices.Interface: IdentityUnitRange

using ArrayInterface: to_axes, to_index
using Base: step_hp, OneTo
using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()

@test Base.to_shape(SimpleAxis(1)) == 1

include("copyto_tests.jl")

@testset "keys" begin
    axis = Axis(2:3 => 1:2)

    @test keytype(typeof(Axis(1.0:10.0))) <: Float64
    @test haskey(axis, 3)
    @test !haskey(axis, 4)
    @test keys.(axes(axis)) == (2:3,)

    A = AxisArray(ones(3,2), [:one, :two, :three], nothing)
    @testset "reverse" begin
        x = [1, 2, 3]
        y = AxisArray(x)
        z = AxisArray(x, Axis([:one, :two, :three]))

        revx = reverse(x)
        revy = @inferred(reverse(y))
        revz = @inferred(reverse(z))

        @testset "reverse vectors values properly" begin
            @test revx == revz == revy
        end

        @testset "reverse vectors keys" begin
            @test keys(axes(revy, 1)) == [3, 2, 1]
            @test keys(axes(revz, 1)) == [:three, :two, :one]
        end

        @testset "reverse arrays" begin
            b = [1 2; 3 4]
            x = AxisArray(b, [:one, :two], ["a", "b"])

            xrev1 = reverse(x, dims=1)
            xrev2 = reverse(x, dims=2)
            @test keys.(axes(xrev1)) == ([:two, :one], ["a", "b"])
            @test keys.(axes(xrev2)) == ([:one, :two], ["b", "a"])
        end
    end
end

@testset "CartesianAxes" begin
    cartaxes = CartesianAxes((2.0:5.0, 1:4))
    cartinds = CartesianIndices((1:4, 1:4))
    for (axs, inds) in zip(collect(cartaxes), collect(cartinds))
        @test axs == inds
    end

    for (axs, inds) in zip(cartaxes, cartinds)
        @test axs == inds
    end

    @test collect(cartaxes) == cartaxes[1:4,1:4]
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

include("simple_axis.jl")
include("axis.jl")
include("abstract_axis.jl")
include("centered_axis.jl")
include("identity_axis.jl")
include("offset_axis.jl")
include("arrays.jl")
include("getindex_tests.jl")
include("append_tests.jl")
include("similar_tests.jl")
include("arrays.jl")
include("broadcasting_tests.jl")
include("linear_algebra.jl")
include("first_tests.jl")
include("last_tests.jl")
include("length_tests.jl")

@test first(axes(@inferred(filter(isodd, AxisArray(1:7, (2:8,)))), 1)) == 2
@test axes(filter(isodd, AxisArray([11 12; 21 22], (2:3, 3:4))), 1) isa AbstractAxis
include("mapped_arrays.jl")
#include("offset_array_tests.jl")

include("resize_tests.jl")
include("offset_tests.jl")

@testset "docs" begin
    doctest(AxisIndices)
end

include("NamedMetaAxisArray_tests.jl")

