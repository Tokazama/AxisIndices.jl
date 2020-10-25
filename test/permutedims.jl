
@testset "permutedims" begin

    @testset "Matrix" begin
        @test AxisIndices.permute_axes(rand(4, 2)) === (Base.OneTo(2), Base.OneTo(4))
        axs = @inferred(AxisIndices.permute_axes((Axis(1:4), Axis(1:2))))
        @test axs isa Tuple{Axis,Axis}
        @test length.(axs) == (2, 4)
    end

    @testset "Vector" begin
        @test length.(AxisIndices.permute_axes(rand(4))) == (1, 4)
        axs = AxisIndices.permute_axes((Axis(1:4),))
        @test axs isa Tuple{SimpleAxis,Axis}
        @test length.(axs) == (1, 4)

        v = AxisArray([10, 20, 30], (2:4,))
        @test permutedims(v) == [10 20 30]
        @test keys.(axes(permutedims(v))) == (1:1, 2:4)
        @test permutedims(permutedims(v)) == reshape([10, 20, 30], Val(2))
        @test keys.(axes(permutedims(permutedims(v)))) == (2:4, 1:1)
    end

    @testset "Array" begin
        @test length.(AxisIndices.permute_axes(rand(2, 4, 6), (1, 3, 2))) == (2, 6, 4)

        axs = AxisIndices.permute_axes((Axis(1:2), Axis(1:4), Axis(1:6)), (1, 3, 2))
        @test axs isa Tuple{Axis,Axis,Axis}
        @test length.(axs) == (2, 6, 4)

        a = AxisArray(ones(10, 20, 30, 40), (2:11, 2:21, 2:31, 2:41));
        @test (keys.(axes(permutedims(a, (1, 2, 3, 4)))) ==
            keys.(axes(permutedims(a, 1:4))) ==
            (2:11, 2:21, 2:31, 2:41)
        )
        @test (keys.(axes(permutedims(a, (1, 3, 2, 4)))) == (2:11, 2:31, 2:21, 2:41))
    end
end

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
        @test keys.(axes(v)) == ([:one, :two], ["three", "four"])
        v = permuteddimsview(a, (2,1))
        @test v == a'
        @test keys.(axes(v)) == (["three", "four"], [:one, :two])
        a = AxisArray(rand(2,3,4), ["a", "b"], [:a, :b, :c], [1,2,3,4])
        v = permuteddimsview(a, (2,3,1))
        @test v == permutedims(a, (2,3,1))
        @test keys.(axes(v)) == ([:a, :b, :c], [1,2,3,4], ["a", "b"])
    end
end

@testset "PermuteDimsArray" begin
    x = AxisArray(ones(2,2))
    y = PermutedDimsArray(x, (2, 1))
    @test axes(y) isa Tuple{SimpleAxis, SimpleAxis}
    @test axes(y, 1) isa SimpleAxis
end

