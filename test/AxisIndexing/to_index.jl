
@testset "traits" begin
    @testset "CombineStyle" begin
        for (x,y,z) in ((Axis{Int,Int,UnitRange{Int},UnitRange{Int}},Axis{Int,Int,UnitRange{Int},UnitRange{Int}},CombineAxis),
                        (SimpleAxis{Int,UnitRange{Int}},Axis{Int,Int,UnitRange{Int},UnitRange{Int}},CombineAxis),
                        (SimpleAxis{Int,UnitRange{Int}},SimpleAxis{Int,UnitRange{Int}},CombineSimpleAxis),
                        (UnitRange{Int},UnitRange{Int},CombineResize),
                        (UnitRange{Int},LinearIndices{1},CombineResize),
                        (Vector{Int},SimpleAxis{Int,UnitRange{Int}},CombineSimpleAxis),
                        (Vector{Int},Axis{Int,Int,UnitRange{Int},UnitRange{Int}},CombineAxis))
            @test @inferred(CombineStyle(x, y)) isa z
            @test @inferred(CombineStyle(y, x)) isa z
        end
    end

    @testset "ToIndexStyle" begin
        @test @inferred(ToIndexStyle(["a", "b"])) isa SearchKeys
        @test @inferred(ToIndexStyle("a")) isa SearchKeys
        @test @inferred(ToIndexStyle(1)) isa SearchIndices
        @test @inferred(ToIndexStyle([1])) isa SearchIndices
        @test @inferred(ToIndexStyle((1,))) isa SearchIndices
        @test @inferred(ToIndexStyle(true)) isa GetIndices
    end
end

@testset "to_index" begin
    a = Axis(2:10)
    @test to_index(a, 1) == 1
    @test to_index(a, 1:2) == 1:2

    x = Axis([:one, :two])
    @test to_index(x, :one) == 1
    @test to_index(x, [:one, :two]) == [1, 2]

    @test_throws BoundsError Base.to_index(x, 3)
    @test_throws BoundsError Base.to_index(x, 1:3)

    x = Axis(["a", "b"])
    @test getindex(x, CartesianIndex(1)) == 1
    @test Base.to_index(x, CartesianIndex(1)) == 1

    @testset "to_index(::SearchKeys,...)" begin
        @test @inferred(Base.to_index(SearchKeys(), x, ==("b"))) == 2
        @test @inferred(Base.to_index(SearchKeys(), x, "b")) == 2
        @test @inferred(Base.to_index(SearchKeys(), x, ["a", "b"])) == [1, 2]
        @test @inferred(Base.to_index(SearchKeys(), x, in(["a", "b"]))) == [1, 2]

        @test_throws BoundsError Base.to_index(SearchKeys(), x, "c")
        @test_throws BoundsError Base.to_index(SearchKeys(), x, ["a", "b", "c"])
    end

    @testset "to_index(::SearchIndices,...)" begin
        @test @inferred(Base.to_index(SearchIndices(), x, ==(2))) == 2
        @test @inferred(Base.to_index(SearchIndices(), x, 2)) == 2
        @test @inferred(Base.to_index(SearchIndices(), x, 1:2)) == [1, 2]
        @test @inferred(Base.to_index(SearchIndices(), x, in(1:2))) == [1, 2]

        @test_throws BoundsError Base.to_index(SearchIndices(), x, 3)
        @test_throws BoundsError Base.to_index(SearchIndices(), x, 1:3)
    end

    @testset "to_index(::GetIndices,...)" begin
        @test @inferred(Base.to_index(GetIndices(), x, [false, true])) == [2]
        @test @inferred(Base.to_index(GetIndices(), x, [true, true])) == [1, 2]
        @test_throws BoundsError Base.to_index(SearchIndices(), x, false)
        # FIXME this doesn't throw a bounds error for some reason
        #@test_throws BoundsError Base.to_index(AxisIndices.SearchIndices(), x, [true, true, true])
    end
end

