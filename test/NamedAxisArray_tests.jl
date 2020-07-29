
@testset "NamedDims" begin
    A = NamedAxisArray(reshape(1:24, 2, 3, 4), x=["a", "b"], y =["one", "two", "three"], z=2:5);
    @test @inferred(StaticRanges.axes_type(typeof(A))) <: typeof(axes(A))
    @test @inferred(StaticRanges.parent_type(typeof(A))) <: typeof(parent(A))
    @test @inferred(A[1,1,1]) == @inferred(A["a", "one", ==(2)]) == 1
    @test @inferred(A[CartesianIndex(1,1,1)]) == 1
    # FIXME
    @test @inferred(A[["a", "b"], 1:2, 1:2]) ==
          @inferred(A[["a", "b"], 1:2, 1:2, 1]) ==
          @inferred(parent(A)[1:2, 1:2, 1:2]) ==
          @inferred(parent(A)[["a", "b"], 1:2, 1:2, 1])

    @test @inferred(A[1:10]) == 1:10

    @test keys(@inferred(AxisIndices.named_axes(A))) == (:x,:y,:z)
    @test keys(@inferred(AxisIndices.named_axes(parent(A)))) == (:dim_1, :dim_2, :dim_3)

    @test dimnames(@inferred(NamedAxisArray{(:x, :y),Int}(undef, 1:2, 1:2))) == (:x, :y)
    @test dimnames(@inferred(NamedAxisArray{(:x, :y),Int}(undef, (2,2)))) == (:x, :y)
    @test dimnames(@inferred(NamedAxisArray{(:x, :y),Int,2}(undef, 1:2, 1:2))) == (:x, :y)
end
AxisArray(reshape(1:24, 2, 3, 4), ["a", "b"], ["one", "two", "three"], 2:5)
