
@testset "closest" begin
    x = 1:3:19
    @test closest(x, 3) == 2
    @test closest(x, 4) == 2
    @test closest(x, 5) == 2

    x = 19:-3:1
    @test closest(x, 3) == 6
    @test closest(x, 4) == 6
    @test closest(x, 5) == 6

    x = [4, 1, 7, 10, 13, 16, 19]
    @test closest(x, 3) == 1
    @test closest(x, 4) == 1
    @test closest(x, 5) == 1

    x = Axis([1.5, 2.0, 2.5, 3.0])
    @test x[closest(1.6)] == 1
    @test x[closest(1.9)] == 2
    @test x[closest(2.0)] == 2
    @test checkindex(Bool, x, closest(1.6))
end
