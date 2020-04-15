
@testset "length - tests" begin
    @testset "length(r)" begin
        for (r,b) in ((SimpleAxis(UnitMRange(1,3)), 1:3),
                      (Axis(UnitMRange(1,3),UnitMRange(1,3)), 1:3)
                     )
            @test @inferred(length(r)) == length(b)
            @test @inferred(length(r)) == length(b)
            if b isa StepRangeLen
                @test @inferred(stephi(r)) == stephi(b)
                @test @inferred(steplo(r)) == steplo(b)
            end
        end
    end

    @testset "can_set_length" begin
        @test @inferred(!StaticRanges.can_set_length(Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}))
        @test @inferred(StaticRanges.can_set_length(Axis{Int,Int,UnitMRange{Int},OneToMRange{Int}}))
    end

    @testset "set_length!" begin
        @test @inferred(set_length!(SimpleAxis(OneToMRange(10)), UInt32(11))) == SimpleAxis(OneToMRange(11))
        @test @inferred(set_length!(Axis(OneToMRange(10), OneToMRange(10)), UInt32(11))) == Axis(OneToMRange(11), OneToMRange(11))
    end

    @testset "set_length" begin
        @test @inferred(set_length(SimpleAxis(OneToMRange(10)), UInt32(11))) == SimpleAxis(OneToMRange(11))
        @test @inferred(set_length(Axis(OneToMRange(10), OneToMRange(10)), UInt32(11))) == Axis(OneToMRange(11), OneToMRange(11))
    end

    @testset "empty length" begin
        @test length(empty!(Axis(UnitMRange(1, 10)))) == 0
        @test length(empty!(SimpleAxis(UnitMRange(1, 10)))) == 0
    end

end

