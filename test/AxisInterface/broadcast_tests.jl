using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()

@testset "Broadcasting" begin
    x = Axis(1:10, 1:10)
    y = 1:10
    @test broadcasted(bstyle, -, 2, x) == broadcasted(bstyle, -, 2, y)
    @test isa(broadcasted(bstyle, -, 2, x), Axis)
    @test broadcasted(bstyle, -, x, 2) == broadcasted(bstyle, -, y, 2)
    @test isa(broadcasted(bstyle, -, x, 2), Axis)

    @test broadcasted(bstyle, +, 2, x) == broadcasted(bstyle, +, 2, y)
    @test isa(broadcasted(bstyle, +, 2, x), Axis)
    @test broadcasted(bstyle, +, x, 2) == broadcasted(bstyle, +, y, 2)
    @test isa(broadcasted(bstyle, +, x, 2), Axis)

    @test broadcasted(bstyle, *, 2, x) == broadcasted(bstyle, *, 2, y)
    @test isa(broadcasted(bstyle, *, 2, x), Axis)
    @test broadcasted(bstyle, *, x, 2) == broadcasted(bstyle, *, y, 2)
    @test isa(broadcasted(bstyle, *, x, 2), Axis)
end

