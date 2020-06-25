
include("vectors.jl")
include("AxisArray.jl")


@testset "permuteddimsview" begin
    @testset "standard" begin
        a = [1 3; 2 4]
        v = permuteddimsview(a, (1,2))
        @test v == a
        v = permuteddimsview(a, (2,1))
        @test v == a'
        a = rand(3,7,5)
        v = permuteddimsview(a, (2,3,1))
        @test v == permutedims(a, (2,3,1))
    end

    @testset "AxisArray" begin
        a = AxisArray([1 3; 2 4])
        v = permuteddimsview(a, (1,2))
        @test v == a
        @test isa(v, AbstractAxisArray)
        v = permuteddimsview(a, (2,1))
        @test v == a'
        a = AxisArray(rand(3,7,5))
        v = permuteddimsview(a, (2,3,1))
        @test v == permutedims(a, (2,3,1))
        @test isa(v, AbstractAxisArray)
    end

    @testset "NamedDimsArray" begin
        a = NamedAxisArray{(:a,:b)}([1 3; 2 4])
        v = permuteddimsview(a, (1,2))
        @test v == a
        @test v isa NamedAxisArray
    end
end



