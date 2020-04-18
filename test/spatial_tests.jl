

using AxisIndices.SpatialDims

@testset "spatial" begin
    nia = NIArray(reshape(1:12, 2, 3, 2), x = 2:3, time = 3.0:5.0, obs = 1:2)
    @test @inferred(spatial_order(nia)) == (:x,)
    @test @inferred(spatialdims(nia)) == (1,)
    @test @inferred(spatial_axes(nia)) == (Axis(2:3 => Base.OneTo(2)),)
    @test @inferred(spatial_offset(nia)) == (2,)
    @test @inferred(spatial_keys(nia)) == (2:3,)
    @test @inferred(spatial_indices(nia)) == (1:2,)
    @test @inferred(spatial_size(nia)) == (2,)
    @test @inferred(pixel_spacing(nia)) == (1,)
end

