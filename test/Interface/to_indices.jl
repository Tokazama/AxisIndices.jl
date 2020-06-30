# TODO Test all to_indices methods here
@testset "to_indices" begin
    A = AxisArray(reshape(1:27, 3, 3, 3))
    @test @inferred Interface.to_indices(A, ([CartesianIndex(1,1,1), CartesianIndex(1,2,1)],)) == (CartesianIndex{3}[CartesianIndex(1, 1, 1), CartesianIndex(1, 2, 1)],)
    @test @inferred(A[[CartesianIndex(1,1,1), CartesianIndex(1,2,1)]]) == [1, 4]

end
