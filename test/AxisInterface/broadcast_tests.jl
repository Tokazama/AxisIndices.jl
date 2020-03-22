using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()

@testset "Broadcasting" begin
    x = Axis(1:10, 1:10)
    y = SimpleAxis(1:10)
    z = 1:10

    @test @inferred(broadcasted(bstyle, -, 2, x)) ==
          @inferred(broadcasted(bstyle, -, 2, y)) ==
          broadcasted(bstyle, -, 2, z)

    @test @inferred(broadcasted(bstyle, -, x, 2)) ==
          @inferred(broadcasted(bstyle, -, y, 2)) ==
          broadcasted(bstyle, -, z, 2)

    @test @inferred(broadcasted(bstyle, +, 2, x)) ==
          @inferred(broadcasted(bstyle, +, 2, y)) ==
          broadcasted(bstyle, +, 2, z)
    @test isa(broadcasted(bstyle, +, 2, x), Axis)
    @test isa(broadcasted(bstyle, +, 2, y), SimpleAxis)

    @test @inferred(broadcasted(bstyle, +, x, 2)) ==
          @inferred(broadcasted(bstyle, +, y, 2)) ==
          broadcasted(bstyle, +, z, 2)
    @test isa(broadcasted(bstyle, +, x, 2), Axis)
    @test isa(broadcasted(bstyle, +, y, 2), SimpleAxis)

    @test @inferred(broadcasted(bstyle, *, 2, x)) ==
          @inferred(broadcasted(bstyle, *, 2, y)) ==
          broadcasted(bstyle, *, 2, z)

    @test @inferred(broadcasted(bstyle, *, x, 2)) ==
          @inferred(broadcasted(bstyle, *, y, 2)) ==
          broadcasted(bstyle, *, z, 2)
end

