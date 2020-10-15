
@testset "CenteredAxis" begin
    ca = @inferred(CenteredAxis(1:10))
    @test @inferred(keys(ca)) == -5:4
    @test @inferred(parent(ca)) == 1:10
    @test typeof(ca)(parent(ca)) isa typeof(ca)
    ca = @inferred(CenteredAxis{Int32}(UnitRange(1, 10)))
    @test typeof(ca)(parent(ca)) isa typeof(ca)
    @test keytype(ca) <: Int32
    centered_axis = @inferred(CenteredAxis{Int32}(UnitRange(1, 10)))
    @test eltype(ca) <: Int32
    ca2 = ca[-1:1]
    @test @inferred(keys(ca2)) == -1:1
    @test @inferred(parent(ca2)) == 5:7
end

