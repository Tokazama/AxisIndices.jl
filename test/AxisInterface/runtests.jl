
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

@test_throws ErrorException AxisIndices.unsafe_reindex(Axis2(1:2, 1:2), 1:2)

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

    @test SimpleAxis{Int,UnitRange{Int}}(SimpleAxis(Base.OneTo(10))) isa SimpleAxis{Int,UnitRange{Int}}

    @test StaticRanges.similar_type(SimpleAxis(1:10)) <: SimpleAxis{Int64,UnitRange{Int64}}

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

@testset "next_type" begin
    @test next_type("a") == "b"
    @test next_type(:a) == :b
    @test next_type('a') == 'b'
    @test next_type(1) == 2
    @test next_type(1.0) == nextfloat(1.0)
    @test next_type("") == ""
end

@testset "prev_type" begin
    @test prev_type("b") == "a"
    @test prev_type(:b) == :a
    @test prev_type('b') == 'a'
    @test prev_type(1) == 0
    @test prev_type(nextfloat(1.0)) == prevfloat(nextfloat(1.0))
    @test prev_type("") == ""
end

# TODO organize these tests better
@test resize_first([1, 2, 3], 3) == [1, 2, 3]
@test shrink_last(1:3, 2) == 1:1

@test length(empty!(Axis(UnitMRange(1, 10)))) == 0
@test length(empty!(SimpleAxis(UnitMRange(1, 10)))) == 0
