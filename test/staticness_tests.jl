
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
i,m,s = SimpleAxis(UnitRange(1, 3)), SimpleAxis(UnitMRange(1, 3)), SimpleAxis(UnitSRange(1, 3))
