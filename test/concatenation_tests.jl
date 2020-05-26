
@testset "cat_axis" begin
    @test @inferred(cat_axis(Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)), OneTo(20)))       isa Axis{Int64,Int64,UnitMRange{Int64},OneTo{Int64}}
    @test @inferred(cat_axis(SimpleAxis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)), OneTo(20))) isa SimpleAxis{Int64,OneTo{Int64}}
    @test @inferred(cat_axis(SimpleAxis(UnitMRange(1, 10)), Base.OneTo(10), OneTo(20)))                isa SimpleAxis{Int64,OneTo{Int64}}
    @test @inferred(cat_axis(SimpleAxis(Base.OneTo(10)),    UnitMRange(1, 10), OneTo(20)))             isa SimpleAxis{Int64,OneTo{Int64}}
    # FIXME Should be this
    #@test @inferred(cat_axis(Axis(Base.OneTo(10)),          UnitMRange(1, 10)))             isa Axis{Int64,Int64,OneToMRange{Int64},UnitMRange{Int64}}
    @test @inferred(cat_axis(Axis(Base.OneTo(10)),          UnitMRange(1, 10), OneTo(20)))             isa Axis{Int64,Int64,Base.OneTo{Int64},OneTo{Int64}}
end

#= FIXME cat tests
#
@testset "cat axes" begin
    @test @inferred(cat_axis(SimpleAxis(1:2), 2:4, 1:5)) === SimpleAxis(1:5)
    a, b = [1; 2; 3; 4; 5], [6 7; 8 9; 10 11; 12 13; 14 15];
    c, d = CartesianAxes((Axis(1:5),)), CartesianAxes((Axis(1:5), Axis(1:2)));
    #hcat_axes((Axis(1:4), Axis(1:2)), (Axis(1:4), Axis(1:2)))
    @test length.(@inferred(hcat_axes(c, d))) == length.(hcat_axes(a, b))
    @test length.(@inferred(hcat_axes(d, c))) == length.(hcat_axes(a, b))
    @test length.(@inferred(hcat_axes(CartesianAxes((10,)), CartesianAxes((10,))))) == (10, 2)
end
=#

@testset "hcat" begin
    a = AxisIndicesArray([1; 2; 3; 4; 5], (["a", "b", "c", "d", "e"],));
    b = [6 7; 8 9; 10 11; 12 13; 14 15];
    #@test keys.(@inferred(hcat_axes(a, b))) == (["a", "b", "c", "d", "e"], OneToMRange(3))

    @test axes_keys(@inferred(hcat(a, b))) == (["a", "b", "c", "d", "e"], OneToMRange(3))
    @test axes_keys(@inferred(hcat(b, a))) == (["a", "b", "c", "d", "e"], OneToMRange(3))

    @test axes_keys(@inferred(hcat(a, a))) == (["a", "b", "c", "d", "e"], 1:2)
    @test @inferred(hcat(a)) isa AbstractMatrix
    @test @inferred(hcat(hcat(a))) isa AbstractMatrix
end

@testset "vcat" begin
    a = AxisIndicesArray([1 2 3 4 5], (1:1, ["a", "b", "c", "d", "e"],));
    b = [6 7 8 9 10; 11 12 13 14 15];

    @test axes_keys(vcat(a, b)) == axes_keys(vcat(b, a))
    @test axes_keys(vcat(a, a)) == (1:2, ["a", "b", "c", "d", "e"])
    @test vcat(a) == a
end

@testset "cat" begin
    a = AxisIndicesArray(reshape(1:12, (3, 4)), (["a", "b", "c"], 2:5))
    b = parent(a)
    @test axes_keys(cat(a, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(2))
    @test axes_keys(cat(b, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(2))
    @test axes_keys(cat(a, b, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(2))

    @test axes_keys(cat(a, a, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))
    @test axes_keys(cat(a, a, b, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))
    @test axes_keys(cat(a, b, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))
    @test axes_keys(cat(b, a, a, dims=3)) == (["a", "b", "c"], 2:5, Base.OneTo(3))

    # TODO this involves combining strings
    # @test keys(cat(a, a, dims=(1, 2))) == (['a','b','c', 'a','b','c'], [2,3,4,5, 2,3,4,5])
end

