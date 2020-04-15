
@testset "size" begin
    x = Axis(UnitSRange(1, 3), UnitSRange(1, 3))
    @test StaticRanges.Size(typeof(x)) === StaticRanges.Size{(3,)}()

    @test size(x) == (3,)
    @test size(x, 1) == 3
end
