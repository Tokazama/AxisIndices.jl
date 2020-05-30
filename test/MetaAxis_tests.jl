@testset "MetaAxis" begin
    meta_axis = MetaAxis(1:2)
    @test @inferred(meta_axis[1:2]) isa MetaAxis

    meta_axis = MetaAxis([:a, :b])
    @test @inferred(meta_axis[1:2]) isa MetaAxis

    meta_axis = MetaAxis([:a, :b], 1:2)
    @test @inferred(meta_axis[1:2]) isa MetaAxis
    @test @inferred(meta_axis[:a]) == 1
    @test @inferred(has_metadata(meta_axis))
    @test @inferred(has_metadata(typeof(meta_axis)))
    @test @inferred(metadata(meta_axis)) isa Nothing
    @test @inferred(metadata_type(meta_axis)) <: Nothing
    @test !@inferred(is_indices_axis(meta_axis))
    @test !@inferred(is_indices_axis(typeof(meta_axis)))


    meta_axis2 = MetaAxis(1:2, Dict())
    @test Interface.combine_metadata(meta_axis, meta_axis2) isa Dict
    @test Interface.combine_metadata(meta_axis2, meta_axis) isa Dict
    @test Interface.combine_metadata(meta_axis2, meta_axis2) isa Dict
    @test Interface.combine_metadata(meta_axis, meta_axis) isa Nothing
    @test Interface.combine_metadata(1, nothing) isa Int
    @test Interface.combine_metadata(nothing, 1) isa Int

    @test metadata(view(meta_axis2, 1:2)) isa Dict

    A = AxisArray(ones(2,2), meta_axis2, 1:2)
    @test typeof(axis_meta(A)) <: Tuple{<:Dict,Nothing}
    @test typeof(axis_meta(A, 1)) <: Dict

    @test metadata(MetaAxis([:a, :b], 1:2, 1)) isa Int

end
