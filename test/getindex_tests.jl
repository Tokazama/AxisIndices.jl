
@testset "getindex" begin
    @testset "Axis" begin
        a = Axis(2:10)
        @test @inferred(a[1:5]) == @inferred(a[<(7)])

        a = Axis(2.0:10.0)
        @test @inferred(a[2.0]) == 1
        @test @inferred(a[2.0]) == 1
        @test @inferred(a[isapprox(2)]) == 1
        @test @inferred(a[isapprox(2.1; atol=1)]) == 1
        @test @inferred(a[≈(3.1; atol=1)]) == 2
    end

    @testset "CartesianAxes" begin
        x = CartesianAxes((2,2))
        @test getindex(x, 1, :) == CartesianAxes((2,2))[1, 1:2]
        @test getindex(x, :, 1) == CartesianAxes((2,2))[1:2, 1]

        @test getindex(x, CartesianIndex(1, 1)) == CartesianIndex(1,1)
        @test getindex(x, [true, true], :) == CartesianAxes((2,2))
        # FIXME
        #@test getindex(CartesianAxes((2,)), [CartesianIndex(1)]) == [CartesianIndex(1)]

        @test to_indices(x, axes(x), (CartesianIndex(1),)) == (1,)
        @test to_indices(x, axes(x), (CartesianIndex(1,1),)) == (1, 1)
    end

    @testset "linear indexing" begin
        v = AxisIndicesArray(1:4)
        m = AxisIndicesArray(reshape(1:4, 2, 2))

        # ensure it doesn't mess up vector indexing
        @test @inferred(v[1:3]) isa AxisIndicesArray
        # ensure it drops axes and shape just as it does with an Array
        @test @inferred(m[1:3]) isa typeof(parent(m)[1:3])
    end
end
