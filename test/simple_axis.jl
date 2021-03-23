
@testset "SimpleAxis" begin
    x = SimpleAxis(10)
    @test @inferred(SimpleAxis(static(1), 10)) === x
    @test @inferred(SimpleAxis(x)) === x
    @test @inferred(SimpleAxis(Base.IdentityUnitRange(parent(x)))) === x
    @test @inferred(SimpleAxis(DynamicAxis(10))) isa SimpleAxis{DynamicAxis}
    @test @inferred(typeof(SimpleAxis(1:10))(2:3)) == 2:3
    @test @inferred(SimpleAxis(Axis(1:2))) isa SimpleAxis
end

