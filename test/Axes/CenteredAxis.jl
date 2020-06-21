
@testset "CenteredAxis" begin
    centered_axis = @inferred(CenteredAxis(1:10))
    @test @inferred(keys(centered_axis)) == -5:4
    @test @inferred(indices(centered_axis)) == 1:10
    @test typeof(centered_axis)(keys(centered_axis), indices(centered_axis)) isa typeof(centered_axis)
    centered_axis = @inferred(CenteredAxis{Int32}(UnitSRange(1, 10)))
    @test typeof(centered_axis)(keys(centered_axis), indices(centered_axis)) isa typeof(centered_axis)
    @test keytype(centered_axis) <: Int32
    centered_axis = @inferred(CenteredAxis{Int32}(UnitSRange(1, 10)))
    @test eltype(centered_axis) <: Int32
    ca2 = centered_axis[-1:1]
    @test @inferred(keys(ca2)) == -1:1
    @test @inferred(indices(ca2)) == 5:7
    @test !@inferred(has_metadata(centered_axis))
    @test !@inferred(has_metadata(typeof(centered_axis)))
    @test metadata_type(centered_axis) isa Nothing
    @test is_indices_axis(typeof(centered_axis))

    @testset "simialar_type" begin
        @test similar_type(centered_axis, OneTo{Int}) <:
            CenteredAxis{Int64,UnitRange{Int64},OneTo{Int64}}
        @test similar_type(centered_axis, OneToSRange{Int,10}) <:
            CenteredAxis{Int64,UnitSRange{Int64,-5,4},OneToSRange{Int64,10}}
        @test similar_type(centered_axis, UnitSRange{Int,1,10}) <:
            CenteredAxis{Int64,UnitSRange{Int64,-5,4},UnitSRange{Int64,1,10}}
        @test similar_type(centered_axis, UnitSRange{Int,1,10}, OneToSRange{Int,10}) <:
            CenteredAxis{Int64,UnitSRange{Int64,1,10},OneToSRange{Int64,10}}
        @test similar_type(centered_axis, UnitRange{Int}, OneToSRange{Int,10}) <:
            CenteredAxis{Int64,UnitRange{Int64},OneToSRange{Int64,10}}
        @test_throws ErrorException similar_type(centered_axis, OneToSRange{Int}, OneToSRange{Int,10})

        # codecov doesn't catch these with the previous methods like it should but we should
        # make sure they are still necessary so as no to maintain dead code.
        @test AxisIndices.Axes._centered_axis_similar_type(OneTo{Int}) <:
            CenteredAxis{Int64,UnitRange{Int64},OneTo{Int64}}
        @test AxisIndices.Axes._centered_axis_similar_type(OneToSRange{Int,10}) <:
            CenteredAxis{Int64,UnitSRange{Int64,-5,4},OneToSRange{Int64,10}}
        @test AxisIndices.Axes._centered_axis_similar_type(UnitSRange{Int,1,10}) <:
            CenteredAxis{Int64,UnitSRange{Int64,-5,4},UnitSRange{Int64,1,10}}
        @test AxisIndices.Axes._centered_axis_similar_type(UnitSRange{Int,1,10}, OneToSRange{Int,10}) <:
            CenteredAxis{Int64,UnitSRange{Int64,1,10},OneToSRange{Int64,10}}
        @test AxisIndices.Axes._centered_axis_similar_type(UnitRange{Int}, OneToSRange{Int,10}) <:
            CenteredAxis{Int64,UnitRange{Int64},OneToSRange{Int64,10}}
    end
end

