
using AxisIndices.Indexing: to_index
#using AxisIndices.Indexing: axis_indices_styles

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
end

@testset "AxisIndicesStyles" begin
    @test @inferred(AxisIndicesStyle(String)) isa KeyElement
    @test @inferred(AxisIndicesStyle(Int)) isa IndexElement
    @test @inferred(AxisIndicesStyle(Bool)) isa BoolElement
    @test @inferred(AxisIndicesStyle(CartesianIndex{1})) isa CartesianElement

    @test @inferred(AxisIndicesStyle(Vector{String})) isa KeysCollection
    @test @inferred(AxisIndicesStyle(Vector{Int})) isa IndicesCollection
    @test @inferred(AxisIndicesStyle(Vector{Bool})) isa BoolsCollection

    @test @inferred(AxisIndicesStyle(Colon)) isa SliceCollection
    @test @inferred(AxisIndicesStyle(Base.Slice)) isa SliceCollection

    @test @inferred(is_element(KeyElement))
    @test @inferred(is_element(BoolElement))
    @test @inferred(is_element(IndexElement))
    @test @inferred(is_element(CartesianElement))
    @test @inferred(is_element(KeyEquals))
    @test @inferred(!is_element(Vector{Int}))
    @test @inferred(!is_element(KeysCollection))

    @test @inferred(is_collection([1]))
    @test @inferred(is_collection(KeysCollection))

    @test @inferred(is_index(1))
    @test @inferred(is_index(Int))
    @test @inferred(!is_index(:a))
    @test @inferred(!is_index(KeyElement))
    @test @inferred(is_index(BoolElement))
    @test @inferred(is_index(IndexElement))
    @test @inferred(is_index(SliceCollection))

    @test @inferred(is_key(:a))
    @test @inferred(is_key(Symbol))
end

@testset "to_index" begin
    a = Axis(2:10)
    @test @inferred(to_index(a, 1)) == 1
    @test @inferred(to_index(a, 1:2)) == 1:2

    x = Axis([:one, :two])
    @test @inferred(to_index(x, :one)) == 1
    @test @inferred(to_index(x, [:one, :two])) == [1, 2]

    x = Axis(0.1:0.1:0.5)
    @test @inferred(to_index(x, 0.3)) == 3

    x = Axis(["a", "b"])
    @inferred(to_index(x, "a")) == 1
    #=
    @testset "CartesianElement" begin
        @test @inferred(to_index(x, CartesianIndex(1))) == 1
        @test_throws BoundsError to_index(x, CartesianIndex(3))
    end
    =#

    @testset "KeyEquals" begin
        @test @inferred(to_index(x, ==("b"))) == 2
        @test_throws BoundsError to_index(x, ==("c"))
    end

    @testset "KeyElement" begin
        @test @inferred(to_index(x, "b")) == 2
        @test_throws BoundsError to_index(x, "c")
    end

    @testset "KeysCollection" begin
        @test @inferred(to_index(x, ["a", "b"])) == [1, 2]
        @test_throws BoundsError to_index(x, ["a", "b", "c"])
    end

    @testset "KeysIn" begin
        @test @inferred(to_index(x, in(["a", "b"]))) == [1, 2]
        @test_throws BoundsError to_index(x, in(["a", "b", "c"]))
    end

    @testset "IndexElement" begin
        @test @inferred(to_index(x, 2)) == 2
        @test_throws BoundsError to_index(x, 3)
    end
    @testset "IndicesCollection" begin
        @test @inferred(to_index(x, 1:2)) == [1, 2]
        @test_throws BoundsError to_index(x, 1:3)
    end

    @testset "BoolsCollection" begin
        @test @inferred(to_index(x, [false, true])) == [2]
        @test @inferred(to_index(x, [true, true])) == [1, 2]
        @test_throws BoundsError to_index(x, [true, true, true])
    end

    @testset "BoolElement" begin
        @test @inferred(to_index(x, true)) == 1
        @test_throws BoundsError to_index(x, false)
    end
end

@testset "to_indices" begin
    A = AxisIndicesArray(ones(2,2),  (Axis(1:2), Axis(1.0:2.0)));
    V = AxisIndicesArray(ones(2), ["a", "b"]);

    @testset "linear indexing" begin
        @test @inferred(to_indices(A, (1,))) == (1,)
        @test @inferred(to_indices(A, (1:2,))) == (1:2,)

        @testset "Linear indexing doesn't ruin vector indexing" begin
            @test @inferred(to_indices(V, (1:2,))) == (1:2,)
            @test @inferred(to_indices(V, (1,))) == (1,)
            @test @inferred(to_indices(V, ("a",))) == (1,)
        end
    end

    @test @inferred(to_indices(A, (1, 1))) == (1, 1)
    @test @inferred(to_indices(A, (1, 1:2))) == (1, 1:2)
    @test @inferred(to_indices(A, (1:2, 1))) == (1:2, 1)
    @test @inferred(to_indices(A, (1, :))) == (1, Base.Slice(Axis(1.0:2.0)))
    @test @inferred(to_indices(A, (:, 1))) == (Base.Slice(Axis(1:2)), 1)
    @test @inferred(to_indices(A, ([true, true], :))) == (Base.LogicalIndex(Bool[1, 1]), Base.Slice(Axis(1.0:2.0)))
    @test @inferred(to_indices(A, (CartesianIndices((1,)), 1))) == (Axis(1:1 => 1:1), 1)
    @test @inferred(to_indices(A, (1, 1.0))) == (1,1)
end

#=
@testset "axis_indices_styles" begin
    A = AxisIndicesArray(reshape(1:9, 3,3),
                         (2:4,        # first dimension has keys 2:4
                          3.0:5.0));  # second dimension has keys 3.0:5.0

    @test @inferred(axis_indices_styles(axes(A), (:, 2))) == (AxisIndices.Indexing.SliceCollection(), AxisIndices.Indexing.IndexElement())
    #=
    julia> @btime axis_indices_styles($(axes(A)), (:,2))
      0.035 ns (0 allocations: 0 bytes)
    =#

    @test @inferred(axis_indices_styles(axes(A), (2, :))) == (AxisIndices.Indexing.IndexElement(), AxisIndices.Indexing.SliceCollection())
    #=
    julia> @btime axis_indices_styles($(axes(A)), (2, :))
      0.035 ns (0 allocations: 0 bytes)
    =#

    @test @inferred(axis_indices_styles(axes(A), (1, 2))) == (AxisIndices.Indexing.IndexElement(), AxisIndices.Indexing.IndexElement())
    #=
    julia> @btime axis_indices_styles($(axes(A)), (1, 2))
      0.035 ns (0 allocations: 0 bytes)
    =#

    @test @inferred(axis_indices_styles(axes(A), (1:2, 2))) == (AxisIndices.Indexing.IndicesCollection(), AxisIndices.Indexing.IndexElement())
    #=
    julia> @btime axis_indices_styles($(axes(A)), $((1:2, 2)))
    =#
end
=#

