
@testset "grow" begin
    @testset "grow_last" begin
        for (m,f,s) in ((Axis(UnitMRange(1, 10)), Axis(1:10), Axis(UnitSRange(1, 10))),
                        (SimpleAxis(UnitMRange(1, 10)), SimpleAxis(1:10), SimpleAxis(UnitSRange(1, 10))))
            x = @inferred(grow_last(m, 2))
            @test m == 1:10
            @test x == 1:12

            x = @inferred(grow_last(f, 2))
            @test f == 1:10
            @test x == 1:12

            x = @inferred((s -> grow_last(s, 2))(s))

            @test s == 1:10
            @test x == 1:12
        end
    end

    @testset "grow_last!" begin
        for m in (Axis(UnitMRange(1, 10), UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
            x = @inferred(grow_last!(m, 2))
            @test m == 1:12
            @test x == 1:12
        end
    end

    @testset "grow_first" begin
        for (m,f,s) in ((Axis(UnitMRange(1, 10)), Axis(1:10), Axis(UnitSRange(1, 10))),
                        (SimpleAxis(UnitMRange(1, 10)), SimpleAxis(1:10), SimpleAxis(UnitSRange(1, 10))))
            m,f,s = UnitMRange(1, 10), 1:10, UnitSRange(1, 10)
            x = @inferred(grow_first(m, 2))
            @test m == 1:10
            @test x == -1:10

            x = @inferred(grow_first(f, 2))
            @test f == 1:10
            @test x == -1:10

            x = @inferred((s -> grow_first(s, 2))(s))
            @test s == 1:10
            @test x == -1:10
        end
    end

    @testset "grow_first!" begin
        for m in (Axis(UnitMRange(1, 10), UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
            x = @inferred(grow_first!(m, 2))
            @test m == -1:10
            @test x == -1:10
        end
    end
end

#=
@testset "shrink" begin
    @testset "shrink_last" begin
        for (m,f,s) in ((Axis(UnitMRange(1, 10)), Axis(1:10), Axis(UnitSRange(1, 10))),
                        (SimpleAxis(UnitMRange(1, 10)), SimpleAxis(1:10), SimpleAxis(UnitSRange(1, 10)))) 
            x = @inferred(shrink_last(m, 2))
            @test m == 1:10
            @test x == 1:8

            x = @inferred(shrink_last(f, 2))
            @test f == 1:10
            @test x == 1:8

            x = @inferred((s -> shrink_last(s, 2))(s))
            @test s == 1:10
            @test x == 1:8
        end
    end

    @testset "shrink_last!" begin
        for m in (Axis(UnitMRange(1, 10), UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
            x = @inferred(shrink_last!(m, 2))
            @test m == 1:8
            @test x == 1:8
        end
    end

    @testset "shrink_first" begin
        for (m,f,s) in (
            (Axis(UnitMRange(1, 10)), Axis(1:10), Axis(UnitSRange(1, 10))),
            (SimpleAxis(UnitMRange(1, 10)), SimpleAxis(1:10), SimpleAxis(UnitSRange(1, 10)))) 
            x = @inferred(shrink_first(m, 2))
            @test m == 1:10
            @test x == 3:10

            x = @inferred(shrink_first(f, 2))
            @test f == 1:10
            @test x == 3:10

            x = @inferred((s -> shrink_first(s, 2))(s))
            @test s == 1:10
            @test x == 3:10
        end
    end

    @testset "shrink_first!" begin
        for m in (Axis(UnitMRange(1, 10), UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
            x = @inferred(shrink_first!(m, 2))
            @test m == 3:10
            @test x == 3:10
        end
    end
end

=#

