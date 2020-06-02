
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

