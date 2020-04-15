
@testset "first" begin
    @testset "can_set_first" begin
        @test @inferred(!StaticRanges.can_set_first(Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}))
        @test @inferred(StaticRanges.can_set_first(Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}))
    end

    for (r1,b,v,r2) in ((SimpleAxis(UnitMRange(1,3)), true, 2, SimpleAxis(UnitMRange(2,3))),
                        (Axis(UnitMRange(1,3),UnitMRange(1,3)), true, 2, Axis(UnitMRange(2,3),UnitMRange(2,3))))
        @testset "set_first-$(r1)" begin
            x = @inferred(can_set_first(r1))
            @test x == b
            if x
                set_first!(r1, v)
                @test r1 == r2
            end
            @test set_first(r1, v) == r2
        end
    end

    @test first(Axis(2:3)) == 1
    @test first(Axis(2:3, 2:3)) == 2
end

