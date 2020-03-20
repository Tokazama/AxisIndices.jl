
using Base: to_index

struct Axis2{K,V,Ks,Vs} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs
end

Axis2(ks, vs) = Axis2{eltype(ks),eltype(vs),typeof(ks),typeof(vs)}(ks, vs)
Base.keys(a::Axis2) = getfield(a, :keys)
Base.values(a::Axis2) = getfield(a, :values)
function AxisIndices.StaticRanges.similar_type(
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
end

@testset "Axis Constructors" begin
    a1 = Axis(2:3 => 1:2)

    @test SimpleAxis{Int,UnitRange{Int}}(SimpleAxis(Base.OneTo(10))) isa SimpleAxis{Int,UnitRange{Int}}

    @test StaticRanges.similar_type(SimpleAxis(1:10)) <: SimpleAxis{Int64,UnitRange{Int64}}

    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:10) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}

    @test Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}(1:10) isa Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}

    @test Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}(1:10) isa Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}

    @test Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}(1:10) isa Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}

    @test AxisIndices.as_axis(a1) == a1


    @test SimpleAxis{Int,UnitMRange{Int}}(1:2) isa SimpleAxis{Int,UnitMRange{Int}}
end

@testset "reverse_keys" begin
    axis = Axis(1:10)
    saxis = SimpleAxis(1:10)
    @test AxisIndices.reverse_keys(axis) == AxisIndices.reverse_keys(saxis)
    @test keys(AxisIndices.reverse_keys(axis)) == keys(AxisIndices.reverse_keys(saxis))
end

@testset "append tests" begin
    @test AxisIndices.append_axis!(AxisIndices.CombineStack(), [1, 2], [3, 4]) == [1, 2, 3, 4]
    @test_throws ErrorException AxisIndices.append_axis!(AxisIndices.CombineStack(), 1:3, 3:4)
end

@testset "resize tests" begin
    x = 1:10
    @test resize_last!(x, 10) == x
    @test resize_last(x, 10) == x
end

include("range_tests.jl")
include("reduce.jl")
include("promotions.jl")
include("axisindices_tests.jl")
include("indexing.jl")
include("combine_tests.jl")
include("cat_tests.jl")
include("broadcast_tests.jl")

# TODO organize these tests better
@test resize_first([1, 2, 3], 3) == [1, 2, 3]
@test shrink_last(1:3, 2) == 1:1

@test length(empty!(Axis(UnitMRange(1, 10)))) == 0
@test length(empty!(SimpleAxis(UnitMRange(1, 10)))) == 0

@testset "as_axis" begin
    for (t,f) in (([], is_dynamic),
                  ((), is_static),
                  (1:2, is_fixed))
        for ax in (OneTo(10), 1:10)
            @test f(AxisIndices.as_axis(t, ax))
        end
    end

    @test AxisIndices.as_axis(1:2, 2) isa SimpleAxis{Int,Base.OneTo{Int}}
    @test AxisIndices.as_axis(srange(1, 2), 2) isa SimpleAxis{Int,<:OneToSRange{Int}}
    @test AxisIndices.as_axis(mrange(1, 2), 2) isa SimpleAxis{Int,OneToMRange{Int}}
    @test AxisIndices.as_axis(srange(1, 2), 2) isa SimpleAxis{Int,<:OneToSRange{Int}}
end

@testset "filter" begin
    a = AxisIndicesArray([11 12; 21 22], (2:3, 3:4))
    v = AxisIndicesArray(1:7, (2:8,))

    @test axes_keys(filter(isodd, v)) == ([2, 4, 6, 8],)
    @test axes_keys(filter(isodd, a)) == (1:2,)
end

@testset "ToIndexStyle" begin
    @test AxisIndices.ToIndexStyle(String) isa AxisIndices.SearchKeys
    @test AxisIndices.ToIndexStyle(Int) isa AxisIndices.SearchIndices
    @test AxisIndices.ToIndexStyle(Bool) isa AxisIndices.GetIndices
end

