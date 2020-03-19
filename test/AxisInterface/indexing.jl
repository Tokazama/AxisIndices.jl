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

        x = Axis([:one, :two])
        @test to_index(x, :one) == 1
        @test to_index(x, [:one, :two]) == [1, 2]

        #@test_throws BoundsError to_index(x, :three)
        # TODO this currently doesn't throw an error, just returns the indices that can be found
        #@test_throws BoundsError to_index(x, [:one, :two, :three])
    end

    @testset "reindex" begin
        axs = (Axis(2:10), Axis(2:10), Axis(2:10))
        @test reindex(axs, (1, 1:9, 1:9)) == (Axis(2:10), Axis(2:10))
    end

    @testset "Functional indexing" begin
        a = Axis(2:10)
        @test a[1:5] == a[<(7)]
    end
end


