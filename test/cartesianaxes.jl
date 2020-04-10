
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

    @test promote_shape(CartesianAxes((3, 4)), CartesianAxes((3,4,1,1,1))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianAxes((3,4,1,1,1)), CartesianAxes((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianIndices((3,4,1,1,1)), CartesianAxes((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianAxes((3,4,1,1,1)), CartesianIndices((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

end

