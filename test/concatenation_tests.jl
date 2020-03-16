
@testset "Concatenation" begin
    @testset "hcat" begin
        a = AxisIndicesArray([1; 2; 3; 4; 5], (["a", "b", "c", "d", "e"],));
        b = [6 7; 8 9; 10 11; 12 13; 14 15];

        @test axes_keys(hcat(a, b)) ==
              axes_keys(hcat(b, a)) ==
              (["a", "b", "c", "d", "e"], OneToMRange(3))
        @test axes_keys(hcat(a, a)) == (["a", "b", "c", "d", "e"], 1:2)
    end

    @testset "vcat" begin
        a = AxisIndicesArray([1 2 3 4 5], (1:1, ["a", "b", "c", "d", "e"],));
        b = [6 7 8 9 10; 11 12 13 14 15];

        @test axes_keys(vcat(a, b)) == axes_keys(vcat(b, a))
        @test axes_keys(vcat(a, a)) == (1:2, ["a", "b", "c", "d", "e"])
    end

    @testset "cat" begin
        a = AxisIndicesArray(reshape(1:12, (3, 4)), (["a", "b", "c"], 2:5))
        b = parent(a)
        @test axes_keys(cat(a, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(2))
        @test axes_keys(cat(b, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(2))
        @test axes_keys(cat(a, b, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(2))

        @test axes_keys(cat(a, a, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))
        @test axes_keys(cat(a, a, b, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))
        @test axes_keys(cat(a, b, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))
        @test axes_keys(cat(b, a, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))

        # TODO this involves combining strings
        # @test keys(cat(a, a, dims=(1, 2))) == (['a','b','c', 'a','b','c'], [2,3,4,5, 2,3,4,5])
    end

    @test AxisIndices.cat_axis(AxisIndices.CombineStack(), [1, 2], [3, 4]) == [1, 2, 3, 4]
    @test_throws ErrorException AxisIndices.cat_axis(AxisIndices.CombineStack(), 1:3, 3:4)
end
