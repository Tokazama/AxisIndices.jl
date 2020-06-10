using AxisIndices: to_axis

@testset "to_axis" begin
    x = @inferred(to_axis([1, 2, 3]))
    @testset "1-arg" begin
        @test x isa Axis{Int,Int,Vector{Int},OneToMRange{Int}}
        @test @inferred(to_axis(x)) isa Axis{Int,Int,Vector{Int},OneToMRange{Int}}
        @test @inferred(to_axis(10)) isa SimpleAxis{Int,OneTo{Int}}
    end

    @testset "2-arg" begin
        @test @inferred(to_axis(nothing, 1:2)) isa SimpleAxis{Int,UnitRange{Int}}
        @test @inferred(to_axis(1:2, 1:2)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
        @test @inferred(to_axis(x, 1:2)) isa Axis{Int,Int,Vector{Int},UnitRange{Int}}
    end

end
