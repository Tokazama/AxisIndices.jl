

@test valtype(typeof(Axis(1.0:10.0))) <: Int
@test keytype(typeof(Axis(1.0:10.0))) <: Float64

@test firstindex(Axis(1:10)) == firstindex(1:10)

@testset "first" begin
    @testset "can_set_first" begin
        @test @inferred(can_set_first(typeof(Axis(UnitMRange(1, 2)))))
        @test @inferred(!can_set_first(typeof(Axis(UnitSRange(1, 2)))))
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
    @test first(GapRange(2:5, 7:10)) == 2
end

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

    @test last(GapRange(2:5, 7:10)) == 10
end

@testset "step(r)" begin
    for (r,b) in ((SimpleAxis(OneToMRange(10)), OneToMRange(10)),)
        @test @inferred(step(r)) === step(b)
        @test @inferred(Base.step_hp(r)) === Base.step_hp(b)
        if b isa StepRangeLen
            @test @inferred(stephi(r)) == stephi(b)
            @test @inferred(steplo(r)) == steplo(b)
        end
    end
end

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

            @test length(GapRange(1:5, 6:10)) == 10
        end
    end

    @testset "can_set_length" begin
        @test @inferred(can_set_length(typeof(Axis(UnitMRange(1:2))))) == true
        @test @inferred(can_set_length(typeof(Axis(UnitSRange(1:2))))) == false
    end

    @testset "set_length!" begin
        @test @inferred(set_length!(SimpleAxis(OneToMRange(10)), UInt32(11))) == SimpleAxis(OneToMRange(11))
        @test @inferred(set_length!(Axis(OneToMRange(10), OneToMRange(10)), UInt32(11))) == Axis(OneToMRange(11), OneToMRange(11))
    end

    @testset "set_length" begin
        @test @inferred(set_length(SimpleAxis(OneToMRange(10)), UInt32(11))) == SimpleAxis(OneToMRange(11))
        @test @inferred(set_length(Axis(OneToMRange(10), OneToMRange(10)), UInt32(11))) == Axis(OneToMRange(11), OneToMRange(11))
    end
end


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

@testset "Staticness" begin
    # as_[mutable/immutable/static]
    for (i,m,s) in ((SimpleAxis(UnitRange(1, 3)), SimpleAxis(UnitMRange(1, 3)), SimpleAxis(UnitSRange(1, 3))),
                    (Axis(UnitRange(1, 3),UnitRange(1, 3)), Axis(UnitMRange(1, 3),UnitMRange(1, 3)), Axis(UnitSRange(1, 3),UnitSRange(1, 3))),
                   )
        @testset "as_dynamic($(typeof(i).name))" begin
            @test is_dynamic(typeof(as_dynamic(i)))
            @test is_dynamic(typeof(as_dynamic(m)))
            @test is_dynamic(typeof(as_dynamic(s)))
        end

        @testset "as_fixed($(typeof(i).name))" begin
            @test is_fixed(typeof(as_fixed(i)))
            @test is_fixed(typeof(as_fixed(m)))
            @test is_fixed(typeof(as_fixed(s)))
        end

        @testset "as_static($(typeof(i).name))" begin
            @test is_static(typeof(as_static(i)))
            @test is_static(typeof(as_static(m)))
            @test is_static(typeof(as_static(s)))
        end
    end
end

@testset "size" begin
    S = Axis(UnitSRange(1, 3), UnitSRange(1, 3))
    @test StaticRanges.Size(typeof(S)) === StaticRanges.Size{(3,)}()
end
