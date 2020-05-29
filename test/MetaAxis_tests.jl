@testset "MetaAxis" begin
    meta_axis = MetaAxis(1:2)
    @test @inferred(meta_axis[1:2]) isa MetaAxis

    meta_axis = MetaAxis([:a, :b])
    @test @inferred(meta_axis[1:2]) isa MetaAxis

    meta_axis = MetaAxis([:a, :b], 1:2)
    @test @inferred(meta_axis[1:2]) isa MetaAxis
    @test @inferred(meta_axis[:a]) == 1
    @test @inferred(has_metadata(meta_axis))
    @test @inferred(metadata(meta_axis)) isa Nothing
    @test @inferred(metadata_type(meta_axis)) <: Nothing

    meta_axis2 = MetaAxis(1:2, Dict())
    @test Interface.combine_metadata(meta_axis, meta_axis2) isa Dict
    @test Interface.combine_metadata(meta_axis2, meta_axis) isa Dict
    @test Interface.combine_metadata(meta_axis, meta_axis) isa Nothing
end
