
@testset "StructAxis" begin
    axis = @inferred(StructAxis{Complex{Float64}}())
    @test ArrayInterface.known_length(axis) === 2
    @test @inferred(getindex(axis, StaticInt(1):StaticInt(2))) === axis
    @test keys(@inferred(getindex(axis, StaticInt(1):StaticInt(1))))[1] === :re
    @test keys(@inferred(getindex(axis, StaticInt(2):StaticInt(2))))[1] === :im

    x = AxisArray(reshape(1:4, 2, 2), axis, ["a", "b"]);
    @inferred(AxisIndices.structdim(x)) === StaticInt(1)

    x2 = @inferred(struct_view(x))
    @test eltype(x2) <: Complex{Float64}
    @test keys(axes(x2, 1)) == ["a", "b"]
end

