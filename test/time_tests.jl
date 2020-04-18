
using AxisIndices.TimeDims

@testset "time" begin
    nia = NIArray(reshape(1:6, 2, 3), x = 2:3, time = 3.0:5.0)
    @test has_timedim(nia)
    @test !has_timedim(parent(nia))
    @test @inferred(time_keys(nia)) == 3:5
    @test @inferred(ntime(nia)) == 3
    @test @inferred(time_indices(nia)) == 1:3
    @test @inferred(timedim(nia)) == 2
    @test @inferred(select_timedim(nia, 2)) == selectdim(parent(parent(nia)), 2, 2)
    @test @inferred(time_axis_type(nia)) <: Float64
    @test @inferred(time_end(nia)) == 5.0
    @test @inferred(onset(nia)) == 3.0
    @test @inferred(duration(nia)) == 3
    @test @inferred(sampling_rate(nia)) == 1
end

