
@test "iterate" begin
    linaxes = LinearAxes((2,3,4))
    cartaxes = CartesianAxes((2,3,4))
    axis = Axis(1:24)

    # this test ensures that if we iterate through linear indices that we get
    # the same result as we would get from a cartesian set of indices
    for i in 1:2
        for j in 1:3
            for k in 1:3
                @test iterate(linaxes, (i, j, k)) == to_linear(linaxes, axes(linaxes), iterate(cartaxes, (i, j, k)))
            end
        end
    end

    @testset "nextind and prevind" begin
        @test nextind(CartesianAxes((4,)), 2) == 3
        @test nextind(CartesianAxes((2, 3)), (2, 1)) == (1, 2)
        @test prevind(CartesianAxes((4,)), 2) == 1
        @test prevind(CartesianAxes((2, 3)), (2,1)) == (1, 1)
    end

end
