
using AxisIndices.AxisIndexing: CombineStyle, CombineStack, CombineSimpleAxis, CombineAxis, CombineResize, to_index
using AxisIndices.AxisIndexing: IndexerStyle, ToCollection, ToElement
using AxisIndices.AxisIndexing: ToIndexStyle, SearchIndices, SearchKeys, GetIndices
using AxisIndices.AxisIndexing: as_axis

using Base: to_index

struct Axis2{K,V,Ks,Vs} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs
end

Axis2(ks, vs) = Axis2{eltype(ks),eltype(vs),typeof(ks),typeof(vs)}(ks, vs)
Base.keys(a::Axis2) = getfield(a, :keys)
Base.values(a::Axis2) = getfield(a, :values)
function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
   ) where {A<:Axis2}
    return Axis2{eltype(ks_type),eltype(vs_type),ks_type,vs_type}
end

@testset "array interface" begin
    a1 = Axis(2:3 => 1:2)

    @test first(a1) == 1
    @test last(a1) == 2
    @test size(a1) == (2,)
    @test sum(a1) == 3
    @test haskey(a1, 3)
    @test !haskey(a1, 4)
    @test allunique(a1)
    @test in(2, a1)
    @test !in(3, a1)
    @test eachindex(a1) == 1:2
    @test UnitRange(a1) == 1:2

    @test Axis(a1) isa typeof(a1)
    @test SimpleAxis(Axis(1:2)) isa SimpleAxis

    @test SimpleAxis{Int,UnitRange{Int}}(Base.OneTo(2)) isa SimpleAxis{Int,UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}
    @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}


    @testset "similar_type" begin
        @test similar_type(SimpleAxis(10), UnitRange{Int}) <: SimpleAxis{Int,UnitRange{Int}}
        @test similar_type(typeof(SimpleAxis(10)), UnitRange{Int}) <: SimpleAxis{Int,UnitRange{Int}}
        @test similar_type(Axis(1:10), UnitRange{UInt}) <: Axis{UInt64,Int64,UnitRange{UInt64},Base.OneTo{Int64}}
        @test similar_type(typeof(Axis(1:10)), UnitRange{UInt}) <: Axis{UInt64,Int64,UnitRange{UInt64},Base.OneTo{Int64}}
    end

    @testset "reverse_keys" begin
        axis = Axis(1:10)
        saxis = SimpleAxis(1:10)
        @test reverse_keys(axis) == reverse_keys(saxis)
        @test keys(reverse_keys(axis)) == keys(reverse_keys(saxis))
    end

end

@testset "append tests" begin
    @test append_axis!(CombineStack(), [1, 2], [3, 4]) == [1, 2, 3, 4]
    @test_throws ErrorException append_axis!(CombineStack(), 1:3, 3:4)
end

@testset "resize tests" begin
    x = 1:10
    @test resize_last!(x, 10) == x
    @test resize_last(x, 10) == x
end

include("range_tests.jl")
include("axisindices_tests.jl")
include("indexing.jl")

# TODO organize these tests better
@test resize_first([1, 2, 3], 3) == [1, 2, 3]
@test shrink_last(1:3, 2) == 1:1

@test length(empty!(Axis(UnitMRange(1, 10)))) == 0
@test length(empty!(SimpleAxis(UnitMRange(1, 10)))) == 0



@testset "filter" begin
    a = AxisIndicesArray([11 12; 21 22], (2:3, 3:4))
    v = AxisIndicesArray(1:7, (2:8,))

    @test axes_keys(filter(isodd, v)) == ([2, 4, 6, 8],)
    @test axes_keys(filter(isodd, a)) == (1:2,)
end

@test Base.to_shape(SimpleAxis(1)) == 1



#=
include("abstractaxis.jl")
include("staticness.jl")
include("combine.jl")
include("keys.jl")
include("values.jl")
include("show.jl")
include("find.jl")
include("to_index.jl")
include("to_indices.jl")
include("checkindex.jl")
include("first.jl")
include("step.jl")
include("last.jl")
include("length.jl")
include("pop.jl")
include("popfirst.jl")

include("append_axes.jl")
include("matmul_axes.jl")
include("diagonal_axes.jl")
include("permute_axes.jl")
include("rotate_axes.jl")
include("drop_axes.jl")
include("cat_axes.jl")
include("covcor_axes.jl")

include("axis.jl")
include("simpleaxis.jl")
include("as_axis.jl")

=#

include("broadcast_axis.jl")
include("reduce_axes.jl")
include("promotion.jl")
include("reindex.jl")
include("getindex.jl")
include("to_index.jl")
include("to_indices.jl")
include("as_axis.jl")

