# TODO IndicesFix2 tests

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

    @test @inferred(is_element(1))
    @test @inferred(is_element(KeyElement))
    @test @inferred(is_element(BoolElement))
    @test @inferred(is_element(IndexElement))
    @test @inferred(is_element(CartesianElement))
    @test @inferred(is_element(KeyEquals))
    @test @inferred(is_element(IndexEquals))
    @test @inferred(!is_element(Vector{Int}))
    @test @inferred(!is_element(KeysCollection))
    @test @inferred(is_element(KeyedStyle{KeyEquals()}))
    @test @inferred(!is_element(KeyedStyle{KeysCollection()}))

    @test @inferred(is_collection([1]))
    @test @inferred(is_collection(KeysCollection))

    @test @inferred(is_index(1))
    @test @inferred(is_index(Int))
    @test @inferred(!is_index(:a))
    @test @inferred(!is_index(KeyElement))
    @test @inferred(is_index(BoolElement))
    @test @inferred(is_index(IndexElement))
    @test @inferred(is_index(SliceCollection))

    @test @inferred(AxisIndicesStyle(typeof(Indices(1)))) == IndexElement()
    @test @inferred(AxisIndicesStyle(typeof(Indices(==(1))))) == IndexEquals()
    @test @inferred(AxisIndicesStyle(typeof(Indices(>(1))))) == IndicesFix2()

    @test @inferred(AxisIndicesStyle(typeof(Keys(1)))) == KeyElement()
    @test @inferred(AxisIndicesStyle(typeof(Keys(1)))) == KeyElement()
    @test @inferred(AxisIndicesStyle(typeof(Keys([1,2])))) == KeysCollection()

    @test @inferred(is_key(:a))
    @test @inferred(is_key(Symbol))
end

@testset "to_index" begin
    a = Axis(2:10)
    @test @inferred(to_index(a, 1)) == 1
    @test @inferred(to_index(a, 1:2)) == 1:2
    @test @inferred(to_index(a, Keys(2:3))) == 1:2
    @test @inferred(to_keys(a, Keys(2:3), 1:2)) == 2:3
    @test @inferred(to_index(a, Keys(2))) == 1
    @test @inferred(to_keys(a, Keys(2), 1)) == 2

    x = Axis([:one, :two])
    @test @inferred(to_index(x, :one)) == 1
    @test @inferred(to_index(x, [:one, :two])) == [1, 2]

    x = Axis(0.1:0.1:0.5)
    @test @inferred(to_index(x, 0.3)) == 3

    x = Axis(["a", "b"])
    @test @inferred(to_index(x, "a")) == 1

    @testset "CartesianElement" begin
        @test @inferred(to_index(x, CartesianIndex(1))) == 1
        @test_throws BoundsError to_index(x, CartesianIndex(3))
    end

    @testset "KeyEquals" begin
        @test @inferred(to_index(x, ==("b"))) == 2
        @test_throws BoundsError to_index(x, ==("c"))
        @test @inferred(to_keys(x, ==("b"), 2)) == "b"
    end

    @testset "IndexEquals" begin
        @test @inferred(to_index(x, Indices(==(2)))) == 2
        @test_throws BoundsError to_index(x, Indices(==(3)))
        @test @inferred(to_keys(x, Indices(==(2)), 2)) == "b"
    end

    @testset "KeyElement" begin
        @test @inferred(to_index(x, "b")) == 2
        @test_throws BoundsError to_index(x, "c")
        @test @inferred(to_keys(x, "b", 2)) == "b"
        @test @inferred(to_keys(KeyElement(), x, "b", 2)) == "b"
    end

    @testset "IndexElement" begin
        @test @inferred(to_index(x, 2)) == 2
        @test @inferred(to_index(x, Indices(2))) == 2
        @test_throws BoundsError to_index(x, 3)
        @test @inferred(to_keys(x, 2, 2)) == "b"
        @test @inferred(to_keys(x, Indices(2), 2)) == "b"
    end

    @testset "KeysCollection" begin
        @test @inferred(to_index(x, ["a", "b"])) == [1, 2]
        @test_throws BoundsError to_index(x, ["a", "b", "c"])
        @test @inferred(to_keys(x, ["a", "b"], [1, 2])) == ["a", "b"]
    end

    @testset "KeysIn" begin
        @test @inferred(to_index(x, in(["a", "b"]))) == [1, 2]
        @test_throws BoundsError to_index(x, in(["a", "b", "c"]))
    end

    @testset "IndicesFix2" begin
        @test @inferred(to_index(x, Indices(<(2)))) == [1]
        @test @inferred(to_keys(x, Indices(<(2)), [1])) == ["a"]
    end

    @testset "IndicesIn" begin
        @test @inferred(to_index(x, Indices(in(1:2)))) == [1, 2]
        @test_throws BoundsError to_index(x, Indices(in(1:3)))
        @test @inferred(to_keys(x, Indices(in(1:2)), [1, 2])) == ["a", "b"]
    end

    @testset "IndicesCollection" begin
        @test @inferred(to_index(x, 1:2)) == [1, 2]
        @test_throws BoundsError to_index(x, 1:3)
    end

    @testset "BoolsCollection" begin
        @test @inferred(to_index(x, [false, true])) == [2]
        @test @inferred(to_index(x, [true, true])) == [1, 2]
        @test_throws BoundsError to_index(x, [true, true, true])
        @test @inferred(to_keys(x, [true, true], [1, 2])) == ["a", "b"]
    end

    @testset "BoolElement" begin
        @test @inferred(to_index(x, true)) == 1
        @test_throws BoundsError to_index(x, false)
    end

    @testset "SliceCollection" begin
        @test @inferred(to_index(x, :)) == Base.Slice(values(x))
    end

    @testset "KeyedStyle" begin
        @test @inferred(KeyedStyle(KeyElement())) isa KeyedStyle{KeyElement()}
        @test @inferred(KeyedStyle(IndicesCollection())) isa KeyedStyle{KeysCollection()}
    end
end

@testset "to_indices" begin
    A = AxisArray(ones(2,2),  (Axis(1:2), Axis(1.0:2.0)));
    V = AxisArray(ones(2), ["a", "b"]);

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

