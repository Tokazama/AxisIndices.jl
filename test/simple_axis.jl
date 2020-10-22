
@testset "SimpleAxis" begin
    @test @inferred(typeof(SimpleAxis(1:10))(2:3)) == 2:3
    @test @inferred(SimpleAxis(Axis(1:2))) isa SimpleAxis
    @test SimpleAxis{Int,UnitRange{Int}}(SimpleAxis(Base.OneTo(10))) isa SimpleAxis{Int,UnitRange{Int}}
    @test SimpleAxis{Int,UnitMRange{Int}}(Base.OneTo(10)) isa SimpleAxis{Int,UnitMRange{Int}}
    @test SimpleAxis{Int,UnitMRange{Int}}(1:2) isa SimpleAxis{Int,UnitMRange{Int}}
    @test SimpleAxis{Int,UnitRange{Int}}(Base.OneTo(2)) isa SimpleAxis{Int,UnitRange{Int}}
end

