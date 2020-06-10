
@testset "checkindex" begin
    @testset "KeyElement" begin
        @test @inferred(check_index(KeyElement(), Axis([:a, :b]), :a))
        @test !@inferred(check_index(KeyElement(), Axis([:a, :b]), :c))
    end

    @testset "IndexElement" begin
        @test @inferred(check_index(IndexElement(), Axis([:a, :b]), 1))
        @test !@inferred(check_index(IndexElement(), Axis([:a, :b]), 3))
    end

    @testset "BoolElement" begin
        @test @inferred(check_index(BoolElement(), Axis([:a, :b]), true))
    end

    @testset "CartesianElement" begin
        @test @inferred(check_index(CartesianElement(), Axis([:a, :b]), CartesianIndex(1)))
        @test !@inferred(check_index(CartesianElement(), Axis([:a, :b]), CartesianIndex(3)))
    end

    @testset "KeysCollection" begin
        @test @inferred(check_index(KeysCollection(), Axis([:a, :b]), [:a, :b]))
        @test !@inferred(check_index(KeysCollection(), Axis([:a, :b]), [:a, :c]))
    end

    @testset "IndicesCollection" begin
        @test @inferred(check_index(IndicesCollection(), Axis([:a, :b]), [1, 2]))
        @test !@inferred(check_index(IndicesCollection(), Axis([:a, :b]), [1, 3]))
    end

    @testset "BoolsCollection" begin
        @test @inferred(check_index(BoolsCollection(), Axis([:a, :b]), [true, true]))
        @test !@inferred(check_index(BoolsCollection(), Axis([:a, :b]), [true, true, true]))
    end

    @testset "IntervalCollection" begin
        @test @inferred(check_index(IntervalCollection(), Axis([:a, :b]), 1..2))
    end

    @testset "KeysIn" begin
        @test @inferred(check_index(KeysIn(), Axis([:a, :b]), in([:a, :b])))
        @test !@inferred(check_index(KeysIn(), Axis([:a, :b]), in([:a, :c])))
    end

    @testset "KeysIn" begin
        @test @inferred(check_index(IndicesIn(), Axis([:a, :b]), in([1, 2])))
        @test !@inferred(check_index(IndicesIn(), Axis([:a, :b]), in([1, 3])))
    end

    @testset "KeyEquals" begin
        @test @inferred(check_index(KeyEquals(), Axis([:a, :b]), ==(:a)))
        @test !@inferred(check_index(KeyEquals(), Axis([:a, :b]), ==(:c)))
    end

    @testset "IndexEquals" begin
        @test @inferred(check_index(IndexEquals(), Axis([:a, :b]), ==(1)))
        @test !@inferred(check_index(IndexEquals(), Axis([:a, :b]), ==(3)))
    end

    @testset "KeysFix2" begin
        @test @inferred(check_index(KeysFix2(), Axis([:a, :b]), <(:b)))
    end

    @testset "IndicesFix2" begin
        @test @inferred(check_index(IndicesFix2(), Axis([:a, :b]), <(2)))
    end

    @testset "SliceCollection" begin
        @test @inferred(check_index(SliceCollection(), Axis([:a, :b]), :))
    end

    @testset "KeyedStyle" begin
        @test @inferred(check_index(KeyedStyle(KeyElement()), Axis([:a, :b]), :a))
        @test !@inferred(check_index(KeyedStyle(KeyElement()), Axis([:a, :b]), :c))
    end
end

