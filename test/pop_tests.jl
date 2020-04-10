
@testset "pop" begin
    for x in (Axis(UnitMRange(1,10),UnitMRange(1,10)),
              SimpleAxis(UnitMRange(1,10)))
        y = collect(x)
        @test pop(x) == pop(y)
        @test pop!(x) == pop!(y)
        @test x == y
    end

    r = UnitMRange(1, 1)
    y = collect(r)
    @test pop!(r) == pop!(y)
    @test isempty(r) == true
end

