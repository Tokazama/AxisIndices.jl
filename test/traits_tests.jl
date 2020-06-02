@testset "traits" begin
    @testset "is_indices_axis" begin
        x = Axis(1:10)
        y = SimpleAxis(10)
        @test !is_indices_axis(x)
        @test !is_indices_axis(typeof(x))
        @test is_indices_axis(y)
        @test is_indices_axis(typeof(y))
    end
    @test !has_offset_axes(typeof(Axis(1:10)))
    @test has_offset_axes(typeof(Axis(1:10, 2:11)))
end
