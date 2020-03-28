
@testset "to_indices" begin
    A = ones(2,2)
    axs = (Axis(1:2), Axis(1.0:2.0))
    @test @inferred(to_indices(A, axs, (1,1))) == (1, 1)
    @test @inferred(to_indices(A, axs, (1,:))) == (1, 1:2)
    @test @inferred(to_indices(A, axs, (:,1))) == (1:2, 1)
    @test @inferred(to_indices(A, axs, ([true, true],:))) == (Base.LogicalIndex(Bool[1, 1]), Base.OneTo(2))
    @test @inferred(to_indices(A, axs, (CartesianIndices((1,1)),1))) == (Axis(1:1 => 1:1), Axis(1:1 => 1:1), 1)
    @test @inferred(to_indices(A, axs, (1,1.0))) == (1,1)
end

