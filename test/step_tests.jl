
@testset "step(r)" begin
    for (r,b) in ((SimpleAxis(OneToMRange(10)), OneToMRange(10)),)
        @test @inferred(step(r)) === step(b)
        @test @inferred(Base.step_hp(r)) === Base.step_hp(b)
        if b isa StepRangeLen
            @test @inferred(stephi(r)) == stephi(b)
            @test @inferred(steplo(r)) == steplo(b)
        end
    end

    @test @inferred(step(SimpleAxis(2))) == 1
    @test @inferred(firstindex(Axis(1:10))) == firstindex(1:10)
end

