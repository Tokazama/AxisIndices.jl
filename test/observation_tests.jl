
using AxisIndices.ObservationDims

@testset "observation" begin
    nia = NIArray(reshape(1:6, 2, 3), x = 2:3, observations = 3:5)
    @test has_obsdim(nia)
    @test !has_obsdim(parent(nia))
    @test @inferred(obs_keys(nia)) == 3:5
    @test @inferred(nobs(nia)) == 3
    @test @inferred(obs_indices(nia)) == 1:3
    @test @inferred(obsdim(nia)) == 2
    @test @inferred(select_obsdim(nia, 2)) == selectdim(parent(parent(nia)), 2, 2)
    @test @inferred(obs_axis_type(nia)) <: Integer
end

