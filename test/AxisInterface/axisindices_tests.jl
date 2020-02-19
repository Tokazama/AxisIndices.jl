

@testset "AxisIndices" begin
    @testset "CartesianAxes" begin
        cartaxes = CartesianAxes((2.0:5.0, 1:4))
        cartinds = CartesianIndices((1:4, 1:4))
        for (axs, inds) in zip(collect(cartaxes), collect(cartinds))
            @test axs == inds
        end

        for (axs, inds) in zip(cartaxes, cartinds)
            @test axs == inds
        end

        @test collect(cartaxes) == cartaxes[1:4,1:4]
    end

    @testset "LinearAxes" begin
        linaxes = LinearAxes((2.0:5.0, 1:4))
        lininds = LinearIndices((1:4, 1:4))
        for (axs, inds) in zip(collect(linaxes), collect(lininds))
            @test axs == inds
        end

        for (axs, inds) in zip(linaxes, lininds)
            @test axs == inds
        end
        @test collect(linaxes) == linaxes[1:4,1:4]
    end

    @test promote_shape(CartesianAxes((3, 4)), CartesianAxes((3,4,1,1,1))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianAxes((3,4,1,1,1)), CartesianAxes((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

            promote_shape(CartesianIndices((3,4,1,1,1)), CartesianIndices((3, 4)))
    @test promote_shape(CartesianIndices((3,4,1,1,1)), CartesianAxes((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianAxes((3,4,1,1,1)), CartesianIndices((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

end

