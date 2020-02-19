@testset "Indexing" begin
    @testset "AbstractAxis" begin
        x = Axis(1:10)
        @test getindex(x, CartesianIndex(1)) == 1
        @test Base.to_index(x, CartesianIndex(1)) == 1
    end

    @testset "AxisIndices" begin
        x = CartesianAxes((2,2))
        @test getindex(x, 1, :) == CartesianAxes((2,2))[1, 1:2]
        @test getindex(x, :, 1) == CartesianAxes((2,2))[1:2, 1]

        @test getindex(x, CartesianIndex(1, 1)) == CartesianIndex(1,1)
        @test getindex(x, [true, true], :) == CartesianAxes((2,2))
        @test getindex(CartesianAxes((2,)), [CartesianIndex(1)]) == [CartesianIndex(1)]

        @test to_indices(x, axes(x), (CartesianIndex(1),)) == (1,)
        @test to_indices(x, axes(x), (CartesianIndex(1,1),)) == (1, 1)
    end

    @testset "to_index" begin
        a = Axis(2:10)
        @test to_index(a, 1) == 1
        @test to_index(a, 1:2) == 1:2
    end

    @testset "reindex" begin
        axs = (Axis(2:10), Axis(2:10), Axis(2:10))
        @test reindex(axs, (1, 1:9, 1:9)) == (Axis(2:10), Axis(2:10))
    end

end
