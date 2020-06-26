
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
        a = AxisArray([1 3; 2 4], [:one, :two], ["three", "four"]);
        v = permuteddimsview(a, (1,2))
        @test v == a
        @test axes_keys(v) == ([:one, :two], ["three", "four"])
        v = permuteddimsview(a, (2,1))
        @test v == a'
        @test axes_keys(v) == (["three", "four"], [:one, :two])
        a = AxisArray(rand(2,3,4), ["a", "b"], [:a, :b, :c], [1,2,3,4])
        v = permuteddimsview(a, (2,3,1))
        @test v == permutedims(a, (2,3,1))
        @test axes_keys(v) == ([:a, :b, :c], [1,2,3,4], ["a", "b"])
    end

    @testset "NamedDimsArray" begin
        a = NamedAxisArray{(:a,:b)}([1 3; 2 4])
        v = permuteddimsview(a, (2,1))
        @test v == a'
        @test dimnames(v) == (:b, :a)
    end
end
