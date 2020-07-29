# FIXME popfirst
@testset "popfirst" begin
    for x in (Axis(UnitMRange(1,10),UnitMRange(1,10)),
              SimpleAxis(UnitMRange(1,10)))
        y = collect(x)
        @test popfirst(x) == popfirst(y)
        @test popfirst!(x) == popfirst!(y)
        @test x == y
    end
    r = UnitMRange(1, 1)
    y = collect(r)
    @test popfirst!(r) == popfirst!(y)
    @test isempty(r) == true
end
