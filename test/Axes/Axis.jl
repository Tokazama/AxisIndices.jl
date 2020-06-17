
@testset "Axis" begin
    axis = Axis()

    a1 = Axis(2:3 => 1:2)
    axis = Axis(1:10)

    @test UnitRange(a1) == 1:2

    @test @inferred(Axis(a1)) isa typeof(a1)

    @test @inferred(Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:10)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}

    @test @inferred(Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}(1:10)) isa Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}

    @test @inferred(Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}(1:10)) isa Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}

    @test @inferred(Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}(1:10)) isa Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}

    @test @inferred(AxisIndices.to_axis(a1)) == a1

    @test @inferred(Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}(1:2)) isa Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}
    @test @inferred(Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}(UnitRange(UInt(1), UInt(2)))) isa Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}

    @test Axis{String,Int,Vector{String},Base.OneTo{Int}}(Axis(["a", "b"])) isa Axis{String,Int,Vector{String},Base.OneTo{Int}}

    @test @inferred(keys(similar(axis, 2:3))) == 2:3
    @test @inferred(keys(similar(axis, ["a", "b"]))) == ["a", "b"]

    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
    @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}
    @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}

end
