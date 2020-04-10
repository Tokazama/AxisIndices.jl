
@testset "last" begin
   @testset "can_set_last" begin
       @test @inferred(can_set_last(typeof(Axis(UnitMRange(1:2))))) == true
       @test @inferred(can_set_last(typeof(Axis(UnitSRange(1:2))))) == false
    end

    for (r1,b,v,r2) in ((SimpleAxis(UnitMRange(1,3)), true, 2, SimpleAxis(UnitMRange(1,2))),
                        (Axis(UnitMRange(1,3),UnitMRange(1,3)), true, 2, Axis(UnitMRange(1,2),UnitMRange(1,2))))
        @testset "set_last-$(r1)" begin
            x = @inferred(can_set_last(typeof(r1)))
            @test x == b
            if x
                @test @inferred(set_last!(r1, v)) == r2
            end
            if x
                @test @inferred(set_last(r1, v)) == r2
            end
        end
    end

    @test last(Axis(2:3)) == 2
    @test last(Axis(2:3, 2:3)) == 3
end

