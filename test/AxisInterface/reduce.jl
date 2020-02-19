

@testset "reduce_axis" begin
    @test reduce_axis(Base.OneTo(10)) == Base.OneTo(1)
    @test reduce_axis(OneToSRange(10)) == OneToSRange(1)
    @test reduce_axis(OneToMRange(10)) == OneToMRange(1)

    @test reduce_axis(UnitRange(1, 10)) == UnitRange(1, 1)
    @test reduce_axis(UnitSRange(1, 10)) == UnitSRange(1, 1)
    @test reduce_axis(UnitMRange(1, 10)) == UnitMRange(1, 1)

    @test_throws ErrorException reduce_axis(SimpleAxis(1:0))
end
