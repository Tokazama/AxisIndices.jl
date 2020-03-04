
@testset "Concatenation" begin
    @testset "hcat" begin
        a = AxisIndicesArray([1; 2; 3; 4; 5], (["a", "b", "c", "d", "e"],));
        b = [6 7; 8 9; 10 11; 12 13; 14 15];

        @test keys(hcat(a, b)) == keys(hcat(b, a))
        @test keys(hcat(a, a)) == (["a", "b", "c", "d", "e"], 1:2)
    end

    @testset "vcat" begin
        a = AxisIndicesArray([1 2 3 4 5], (1:1, ["a", "b", "c", "d", "e"],));
        b = [6 7 8 9 10; 11 12 13 14 15];

        @test keys(vcat(a, b)) == keys(vcat(b, a))
        @test keys(vcat(a, a)) == (1:2, ["a", "b", "c", "d", "e"])
    end
end
