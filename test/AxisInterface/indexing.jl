
@testset "Indexing" begin
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


    @testset "reindex" begin
        axs = (Axis(2:10), Axis(2:10), Axis(2:10))
        @test @inferred(reindex(axs, (1, 1:9, 1:9))) == (Axis(2:10), Axis(2:10))
    end

    @testset "Functional indexing" begin
        a = Axis(2:10)
        @test @inferred(a[1:5]) == @inferred(a[<(7)])

        a = Axis(2.0:10.0)
        @test @inferred(a[2.0]) == 1
        @test @inferred(a[2.0]) == 1
        @test @inferred(a[isapprox(2)]) == 1
        @test @inferred(a[isapprox(2.1; atol=1)]) == 1
        @test @inferred(a[≈(3.1; atol=1)]) == 2
    end

end

@testset "Floats as keys #13" begin
    A = AxisIndicesArray(collect(1:5), 0.1:0.1:0.5)
    @test @inferred(A[0.3]) == 3
end

