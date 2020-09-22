
@testset "checkindex" begin
    @testset "KeyElement" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), :a))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), :c))
    end

    @testset "IndexElement" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), 1))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), 3))
    end

    @testset "BoolElement" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), true))
    end

    #= TODO I don't think this should ever happen
        @testset "CartesianElement" begin
            @test @inferred(checkindex(Bool, Axis([:a, :b]), CartesianIndex(1)))
            #@test !@inferred(checkindex(Bool, Axis([:a, :b]), CartesianIndex(3)))
        end
    =#

    @testset "KeysCollection" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), [:a, :b]))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), [:a, :c]))
    end

    @testset "IndicesCollection" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), [1, 2]))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), [1, 3]))
    end

    @testset "BoolsCollection" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), [true, true]))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), [true, true, true]))
    end

    @testset "IntervalCollection" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), 1..2))
    end

    @testset "KeysIn" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), in([:a, :b])))
        #@test !@inferred(checkindex(Bool, Axis([:a, :b]), in([:a, :c])))
    end

    @testset "IndicesIn" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), as_indices(in([1, 2]))))
        #@test !@inferred(checkindex(Bool, Axis([:a, :b]), as_indices(in([1, 3]))))
    end

    @testset "KeyEquals" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), ==(:a)))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), ==(:c)))
    end

    @testset "IndexEquals" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), as_indices(==(1))))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), as_indices(==(3))))
    end

    @testset "KeysFix2" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), <(:b)))
    end

    @testset "IndicesFix2" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), <(2)))
    end

    @testset "SliceCollection" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), :))
    end

    @testset "KeyedStyle" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), as_keys(:a)))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), as_keys(:c)))
    end
end

