@testset "NamedDims" begin
    A = NIArray(reshape(1:24, 2, 3, 4), x=["a", "b"], y =["one", "two", "three"], z=2:5)
    @test StaticRanges.axes_type(typeof(A)) <: typeof(axes(A))
    @test StaticRanges.parent_type(typeof(A)) <: typeof(parent(A))
    @test A[1,1,1] == A["a", "one", ==(2)] == 1
    @test A[CartesianIndex(1,1,1)] == 1
    @test A[["a", "b"], 1:2, 1:2] ==
          A[["a", "b"], 1:2, 1:2, 1] ==
          parent(A)[1:2, 1:2, 1:2] ==
          parent(parent(A))[1:2, 1:2, 1:2]
    @test A[1:10] == 1:10
end

