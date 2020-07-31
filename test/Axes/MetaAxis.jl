@testset "MetaAxis" begin
    meta_axis = MetaAxis(1:2)
    @test @inferred(meta_axis[1:2]) isa MetaAxis

    meta_axis = MetaAxis([:a, :b])
    @test @inferred(meta_axis[1:2]) isa MetaAxis

    metaproperty!(meta_axis, :p1, 1)
    @test metaproperty(meta_axis, :p1) == 1

    meta_axis = MetaAxis([:a, :b], 1:2)
    @test @inferred(meta_axis[1:2]) isa MetaAxis
    @test @inferred(meta_axis[:a]) == 1
    @test @inferred(has_metadata(meta_axis))
    @test @inferred(has_metadata(typeof(meta_axis)))
    @test @inferred(metadata(meta_axis)) isa Dict
    @test @inferred(metadata_type(meta_axis)) <: Dict{Symbol,Any}
    @test @inferred(metadata_type(typeof(meta_axis))) <: Dict{Symbol,Any}
    @test !@inferred(is_indices_axis(meta_axis))
    @test !@inferred(is_indices_axis(typeof(meta_axis)))

    meta_axis2 = MetaAxis(1:2, nothing)
    @test Metadata.combine_metadata(meta_axis, meta_axis2) isa Dict
    @test Metadata.combine_metadata(meta_axis2, meta_axis) isa Dict
    @test Metadata.combine_metadata(meta_axis2, meta_axis2) isa Nothing
    @test Metadata.combine_metadata(meta_axis, meta_axis) isa Dict
    @test Metadata.combine_metadata(1, nothing) isa Int
    @test Metadata.combine_metadata(nothing, 1) isa Int

    @test metadata(view(meta_axis2, 1:2)) isa Nothing

    A = AxisArray(ones(2,2), meta_axis, 1:2)
    @test typeof(axis_meta(A)) <: Tuple{<:Dict,Nothing}
    @test typeof(axis_meta(A, 1)) <: Dict
    axis_metaproperty!(A, 1, :p2, 2)
    @test axis_metaproperty(A, 1, :p2) == 2


    @test metadata(MetaAxis([:a, :b], 1:2, 1)) isa Int
end
