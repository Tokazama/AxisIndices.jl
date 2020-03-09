
@testset "concatenation" begin

    @test AxisIndices.cat_axis(SimpleAxis(1:2), 2:4) === SimpleAxis(1:5)
    a, b = [1; 2; 3; 4; 5], [6 7; 8 9; 10 11; 12 13; 14 15];
    c, d = CartesianAxes((Axis(1:5),)), CartesianAxes((Axis(1:5), Axis(1:2)));
    AxisIndices.hcat_axes((Axis(1:4), Axis(1:2)), (Axis(1:4), Axis(1:2)))
    @test length.(AxisIndices.hcat_axes(c, d)) == length.(AxisIndices.hcat_axes(a, b))
    @test length.(AxisIndices.hcat_axes(d, c)) == length.(AxisIndices.hcat_axes(a, b))
    @test length.(AxisIndices.hcat_axes(CartesianAxes((10,)), CartesianAxes((10,)))) == (10, 2)
end
AxisIndices.cat_axis(SimpleAxis(1:2), 2:4)
