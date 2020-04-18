
using AxisIndices.ColorDims

@testset "colors" begin
    nia = NIArray(reshape(1:6, 2, 3), x = 2:3, color = 3:5)
    @test has_colordim(nia)
    @test !has_colordim(parent(nia))
    @test @inferred(color_keys(nia)) == 3:5
    @test @inferred(ncolor(nia)) == 3
    @test @inferred(color_indices(nia)) == 1:3
    @test @inferred(colordim(nia)) == 2
    @test @inferred(select_colordim(nia, 2)) == selectdim(parent(parent(nia)), 2, 2)
    @test @inferred(color_axis_type(nia)) <: Integer
end

