
@testset "NamedMetaAxisArray" begin
    nma1 = NamedMetaAxisArray{(:dim_1,:dim_2)}(ones(Int, 2, 2), ["a", "b"], [:one, :two]);
    nma2 = NamedMetaAxisArray(ones(Int, 2, 2), (dim_1 = ["a", "b"], dim_2 = [:one, :two]));
    nma3 = NamedMetaAxisArray{(:dim_1,:dim_2),Int}(undef, (["a", "b"], [:one, :two]));
    nma4 = NamedMetaAxisArray{(:dim_1,:dim_2),Int}(undef, ["a", "b"], [:one, :two]);
    nma5 = NamedMetaAxisArray{(:dim_1,:dim_2),Int,2}(undef, (["a", "b"], [:one, :two]));
    nma6 = NamedMetaAxisArray{(:dim_1,:dim_2),Int,2}(undef, ["a", "b"], [:one, :two]);

    @test typeof(nma1) <: typeof(nma2)
    @test typeof(nma3) <: typeof(nma4) <: typeof(nma5) <: typeof(nma6)
    @test axes(nma1) == axes(nma2) == axes(nma3) == axes(nma4)
    @test dimnames(nma1) == dimnames(nma2) == dimnames(nma3) == dimnames(nma4)

    @test dimnames(NamedMetaAxisArray(ones(2,2))) == (:dim_1, :dim_2)
    @test axes_keys(NamedMetaAxisArray(ones(Int, 2, 2), (["a", "b"], [:one, :two]))) == (["a", "b"], [:one, :two])
    @test axes_keys(NamedMetaAxisArray(ones(Int, 2, 2), ["a", "b"], [:one, :two])) == (["a", "b"], [:one, :two])
end

@testset "NamedDims" begin
    A = NamedAxisArray(reshape(1:24, 2, 3, 4), x=["a", "b"], y =["one", "two", "three"], z=2:5);
    @test @inferred(ArrayInterface.parent_type(typeof(A))) <: typeof(parent(A))
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

@testset "MetaAxisArray" begin
    meta_axis_array = MetaAxisArray(ones(2,2));
    @test typeof(parent(meta_axis_array)) <: typeof(AxisArray(ones(2, 2)))

    axis_array = AxisArray(ones(2, 2), ["a", "b"], [:one, :two])
    meta_axis_array = MetaAxisArray(ones(2, 2), ["a", "b"], [:one, :two])
    @test typeof(parent(meta_axis_array)) <: typeof(axis_array)

    axis_array = AxisArray{Int}(undef, ["a", "b"], [:one, :two])
    meta_axis_array = MetaAxisArray{Int}(undef, ["a", "b"], [:one, :two])
    @test typeof(parent(meta_axis_array)) <: typeof(axis_array)

    axis_array = AxisArray{Int,2}(undef, ["a", "b"], [:one, :two])
    meta_axis_array = MetaAxisArray{Int,2}(undef, ["a", "b"], [:one, :two])
    @test typeof(parent(meta_axis_array)) <: typeof(axis_array)
end

