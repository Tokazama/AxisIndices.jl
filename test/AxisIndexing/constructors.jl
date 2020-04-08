
@testset "Axis Constructors" begin
    a1 = Axis(2:3 => 1:2)

    @test SimpleAxis{Int,UnitRange{Int}}(SimpleAxis(Base.OneTo(10))) isa SimpleAxis{Int,UnitRange{Int}}

    @test StaticRanges.similar_type(SimpleAxis(1:10)) <: SimpleAxis{Int64,UnitRange{Int64}}

    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:10) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}

    @test Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}(1:10) isa Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}

    @test Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}(1:10) isa Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}

    @test Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}(1:10) isa Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}

    @test AxisIndices.to_axis(a1) == a1


    @test SimpleAxis{Int,UnitMRange{Int}}(1:2) isa SimpleAxis{Int,UnitMRange{Int}}

    @test Axis{String,Int,Vector{String},Base.OneTo{Int}}(Axis(["a", "b"])) isa Axis{String,Int,Vector{String},Base.OneTo{Int}}

    axis = Axis(1:10)
    @test @inferred(keys(similar(axis, 2:3))) == 2:3
    @test @inferred(keys(similar(axis, ["a", "b"]))) == ["a", "b"]
    @test @inferred(similar(SimpleAxis(10), 2:3)) == 2:3
end


