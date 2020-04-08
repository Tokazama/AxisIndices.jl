
using AxisIndices.AxisIndexing: CombineStyle, CombineStack, CombineSimpleAxis, CombineAxis, CombineResize, to_index
#using AxisIndices.AxisIndexing: IndexerStyle, ToCollection, ToElement
#using AxisIndices.AxisIndexing: SearchStyle, SearchIndices, SearchKeys, GetIndices
using AxisIndices.AxisIndexing: to_axis, to_axes

include("constructors.jl")
include("broadcast_axis.jl")
include("reduce_axes.jl")
include("promotion.jl")
include("getindex.jl")
include("to_index.jl")
include("as_axis.jl")


include("range_tests.jl")
include("axisindices_tests.jl")

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

    @test @inferred(!StaticRanges.can_set_first(Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}))
    @test @inferred(StaticRanges.can_set_first(Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}))
    @test @inferred(!StaticRanges.can_set_length(Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}))
    @test @inferred(StaticRanges.can_set_length(Axis{Int,Int,UnitMRange{Int},OneToMRange{Int}}))
    @test step(a1) == 1


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


@testset "Indexing" begin
    @testset "AxisIndices" begin
        x = CartesianAxes((2,2))
        @test getindex(x, 1, :) == CartesianAxes((2,2))[1, 1:2]
        @test getindex(x, :, 1) == CartesianAxes((2,2))[1:2, 1]

        @test getindex(x, CartesianIndex(1, 1)) == CartesianIndex(1,1)
        @test getindex(x, [true, true], :) == CartesianAxes((2,2))
        # FIXME
        #@test getindex(CartesianAxes((2,)), [CartesianIndex(1)]) == [CartesianIndex(1)]

        @test to_indices(x, axes(x), (CartesianIndex(1),)) == (1,)
        @test to_indices(x, axes(x), (CartesianIndex(1,1),)) == (1, 1)
    end
end

@testset "Floats as keys #13" begin
    A = AxisIndicesArray(collect(1:5), 0.1:0.1:0.5)
    @test @inferred(A[0.3]) == 3
end
@testset "append tests" begin
    @test append_axis!(CombineStack(), [1, 2], [3, 4]) == [1, 2, 3, 4]
    @test_throws ErrorException append_axis!(CombineStack(), 1:3, 3:4)
end

@test length(empty!(Axis(UnitMRange(1, 10)))) == 0
@test length(empty!(SimpleAxis(UnitMRange(1, 10)))) == 0

#=
@testset "map" begin
    x = Axis(2:10)
    y = SimpleAxis(2:10)
    map(+, x, y)
end
=#


@testset "filter" begin
    a = AxisIndicesArray([11 12; 21 22], (2:3, 3:4))
    v = AxisIndicesArray(1:7, (2:8,))

    @test axes_keys(@inferred(filter(isodd, v))) == ([2, 4, 6, 8],)
    @test axes_keys(filter(isodd, a)) == (1:2,)
end

@test Base.to_shape(SimpleAxis(1)) == 1

@testset "drop_axes" begin
    axs = (Axis(["a", "b"]), Axis([:a]), Axis([1.0]), Axis(1:2))
    @test map(keys, AxisIndices.AxisIndexing.drop_axes(axs, 2)) == (["a", "b"], [1.0], 1:2)
    @test map(keys, AxisIndices.AxisIndexing.drop_axes(axs, (2, 3))) == (["a", "b"], 1:2)
end

