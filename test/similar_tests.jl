

@testset "similar_type" begin
    @test similar_type(SimpleAxis(10), UnitRange{Int}) <: SimpleAxis{Int,UnitRange{Int}}
    @test similar_type(typeof(SimpleAxis(10)), UnitRange{Int}) <: SimpleAxis{Int,UnitRange{Int}}
    @test similar_type(Axis(1:10), UnitRange{UInt}) <: Axis{UInt64,Int64,UnitRange{UInt64},Base.OneTo{Int64}}
    @test similar_type(typeof(Axis(1:10)), UnitRange{UInt}) <: Axis{UInt64,Int64,UnitRange{UInt64},Base.OneTo{Int64}}
end

@testset "similar" begin
    x = AxisIndicesArray(ones(2,2), ["a", "b"], [:one, :two]);
    @test @inferred(similar(x, (1,1))) isa AxisIndicesArray{eltype(x),2}
    @test @inferred(similar(x, Int, (1,1))) isa AxisIndicesArray{Int,2}
    @test @inferred(axes_keys(similar(x, (Base.OneTo(10),Base.OneTo(10))))[1]) == 1:10
    @test @inferred(axes_keys(similar(x, (2:3,)))[1]) == 2:3

    @test eltype(@inferred(similar(x, Int, (Base.OneTo(10),Base.OneTo(10))))) <: Int
    @test eltype(@inferred(similar(x, Int, (2:3,)))) <: Int
    @test @inferred(axes_keys(similar(x, (["x", "y"],)))[1]) == ["x", "y"]
end
