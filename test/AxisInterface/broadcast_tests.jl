using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()

@testset "Broadcasting" begin
    x = Axis(1:10, 1:10)
    y = SimpleAxis(1:10)
    z = 1:10

    @test broadcasted(bstyle, -, 2, x) ==
          broadcasted(bstyle, -, 2, y) ==
          broadcasted(bstyle, -, 2, z)

    @test broadcasted(bstyle, -, x, 2) ==
          broadcasted(bstyle, -, y, 2) ==
          broadcasted(bstyle, -, z, 2)

    @test broadcasted(bstyle, +, 2, x) ==
          broadcasted(bstyle, +, 2, y) ==
          broadcasted(bstyle, +, 2, z)
    @test isa(broadcasted(bstyle, +, 2, x), Axis)
    @test isa(broadcasted(bstyle, +, 2, y), SimpleAxis)

    @test broadcasted(bstyle, +, x, 2) ==
          broadcasted(bstyle, +, y, 2) ==
          broadcasted(bstyle, +, z, 2)
    @test isa(broadcasted(bstyle, +, x, 2), Axis)
    @test isa(broadcasted(bstyle, +, y, 2), SimpleAxis)

    @test broadcasted(bstyle, *, 2, x) ==
          broadcasted(bstyle, *, 2, y) ==
          broadcasted(bstyle, *, 2, z)

    @test broadcasted(bstyle, *, x, 2) ==
          broadcasted(bstyle, *, y, 2) ==
          broadcasted(bstyle, *, z, 2)
end

