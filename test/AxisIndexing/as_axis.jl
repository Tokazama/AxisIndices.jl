
@testset "as_axis" begin
    for (t,f) in (([], is_dynamic),
                  ((), is_static),
                  (1:2, is_fixed))
        for ax in (OneTo(10), 1:10, UnitMRange(1,10), OneToMRange(10))
            @test f(as_axis(t, ax))
            @test f(as_axis(t, ax, ax))
            @test f(as_axis(t, ax, 2:11))
        end
    end

    @test as_axis(1:2, 2) isa SimpleAxis{Int,Base.OneTo{Int}}
    @test as_axis(SimpleAxis(1)) isa SimpleAxis{Int,Base.OneTo{Int}}
    @test as_axis([], SimpleAxis(1)) isa SimpleAxis{Int,Base.OneTo{Int}}
    @test AxisIndices.AxisIndexing.as_simple_axis(1:2, 1:2) isa SimpleAxis{Int,UnitRange{Int}}
    @test @inferred(as_axis(mrange(1, 2), 2)) isa SimpleAxis{Int,OneToMRange{Int}}
    @test @inferred(as_axis(1:2, 1:1:2, 1:2)) isa Axis{Int64,Int64,StepRange{Int64,Int64},UnitRange{Int64}}
    @test as_axis(srange(1, 2), 2) isa SimpleAxis{Int,<:OneToSRange{Int}}
    @test as_axis((), 1:1:2, 1:2) isa Axis{Int64,Int64,StepSRange{Int64,Int64,1,1,2},UnitSRange{Int64,1,2}}
    @test_throws ErrorException as_axis([], Axis(1:2), 1:3)
end

