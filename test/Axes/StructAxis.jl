
@testset "StructAxis" begin

    axis = @inferred(StructAxis{NamedTuple{(:one,:two,:three),Tuple{Int64,Int32,Int16}}}())
    @test axis[1:2] == [1, 2]
    @test keys(axis[1:2]) == [:one, :two]
    #@test AxisIndices.AxisCore.to_types(axis, :one) <: Int
    #@test AxisIndices.AxisCore.to_types(axis, [:one, :two]) <: Tuple{Int,Int32}

    axis = StructAxis{NamedTuple{(:a,:b),Tuple{Int,Int}}}()
    x = AxisArray(reshape(1:4, 2, 2), axis);
    x2 = structview(x);
    @test x2[1] isa NamedTuple{(:a,:b),Tuple{Int,Int}}

    x = AxisArray(reshape(1:4, 2, 2), StructAxis{Rational}());
    x2 = structview(x);
    @test x2[1] isa Rational
    @test AxisIndices.Axes.structdim(x) == 1
end

