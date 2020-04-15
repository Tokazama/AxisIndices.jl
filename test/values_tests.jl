
@testset "values/indices" begin

    @test valtype(typeof(Axis(1.0:10.0))) <: Int
    a1 = Axis(2:3 => 1:2)

    @test allunique(a1)
    @test in(2, a1)
    @test !in(3, a1)
    @test eachindex(a1) == 1:2

    @testset "Floats as keys #13" begin
        A = AxisIndicesArray(collect(1:5), 0.1:0.1:0.5)
        @test @inferred(A[0.3]) == 3
    end

end

