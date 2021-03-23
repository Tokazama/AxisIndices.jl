
@testset "StructAxis" begin
    axis = @inferred(StructAxis{Complex{Float64}}())
    @test ArrayInterface.known_length(axis) === 2
    @test @inferred(getindex(axis, StaticInt(1):StaticInt(2))) === axis
    @test @inferred(getindex(axis, StaticInt(1):StaticInt(1)))[:re] === 1
    @test @inferred(getindex(axis, StaticInt(2):StaticInt(2)))[:im] === 2

    @testset "struct_view" begin
        x = AxisArray(reshape(1:4, 2, 2), StructAxis{Complex{Float64}}(), ["a", "b"]);
        @inferred(AxisIndices.structdim(x)) === StaticInt(1)
        @test_throws MethodError AxisIndices.structdim(parent(x))

        x2 = @inferred(struct_view(x))
        @test eltype(x2) <: Complex{Float64}
        @test keys(axes(x2, 1)) == ["a", "b"]

        x = AxisArray(reshape(1:4, 2, 2), StructAxis{NamedTuple{(:x, :y),Tuple{Float64,Float64}}}(), ["a", "b"]);
        x2 = @inferred(struct_view(x))
        @test eltype(x2) <: NamedTuple{(:x, :y),Tuple{Float64,Float64}}
        @test keys(axes(x2, 1)) == ["a", "b"]
    end

    # must know first index for struct axis b/c it's a completely statically sized axis
    @test_throws ArgumentError StructAxis{Complex{Float64}}(1:10)
    @test_throws ArgumentError StructAxis{Complex}(Base.OneTo(10))
end

