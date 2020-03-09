@testset "Binary broadcasting operations (.+)" begin

    #= TODO moved to docs
    @testset "standard case" begin
        a = AxisIndicesArray(ones(3), (2:4,))
        @test a .+ a == 2ones(3)
        @test keys(axes(a .+ a, 1)) == 2:4

        @test a .+ a.+ a == 3ones(3)
        @test keys(axes(a .+ a .+ a, 1)) == 2:4

        @test (a .= 0 .* a .+ 7) == [7, 7, 7]
    end
    =#

    #= TODO Need to explain how order matters
    @testset "Order matters" begin
        x = AxisIndicesArray(ones(3, 5), (:, nothing))
        y = AxisIndicesArray(ones(3, 5), (nothing, :y))

        lhs = x .+ y
        rhs = y .+ x
        @test dimnames(lhs) == (:x, :y) == dimnames(rhs)
        @test lhs == 2ones(3, 5) == rhs
    end
    =#

   @testset "broadcasting" begin
        v = AxisIndicesArray(zeros(3,), (2:4,))
        m = AxisIndicesArray(ones(3, 3), (2:4, 3:5))
        s = 0

        @test v .+ m == ones(3, 3) == m .+ v
        @test s .+ m == ones(3, 3) == m .+ s
        @test s .+ v .+ m == ones(3, 3) == m .+ s .+ v

        @test keys.(axes(v .+ m)) == (2:4, 3:5) == keys.(axes(m .+ v))
        @test keys.(axes(s .+ m)) == (2:4, 3:5) == keys.(axes(m .+ s))
        @test keys.(axes(s .+ v .+ m)) == (2:4, 3:5) == keys.(axes(m .+ s .+ v))
    end
end
