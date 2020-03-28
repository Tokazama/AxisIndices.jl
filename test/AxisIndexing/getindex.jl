
@testset "getindex" begin
    a = Axis(2:10)
    @test @inferred(a[1:5]) == @inferred(a[<(7)])

    a = Axis(2.0:10.0)
    @test @inferred(a[2.0]) == 1
    @test @inferred(a[2.0]) == 1
    @test @inferred(a[isapprox(2)]) == 1
    @test @inferred(a[isapprox(2.1; atol=1)]) == 1
    @test @inferred(a[≈(3.1; atol=1)]) == 2
end

