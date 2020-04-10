
@testset "AbstractAxis promotions" begin
    a1 = Axis(1:10)
    a2 = Axis(1.0:10.0)
    sa1 = SimpleAxis(1:10)
    sa2 = SimpleAxis(UnitRange(UInt(1), UInt(10)))
    oneto = Base.OneTo(10)

    @test Base.promote_rule(typeof(a1), typeof(a2)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Base.OneTo{Int64}}
    @test Base.promote_rule(typeof(a2), typeof(a1)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Base.OneTo{Int64}}

    @test Base.promote_rule(typeof(a1), typeof(sa1)) <: Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}
    @test Base.promote_rule(typeof(sa1), typeof(a1)) <: Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

    @test Base.promote_rule(typeof(a2), typeof(sa1)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},UnitRange{Int64}}
    @test Base.promote_rule(typeof(sa1), typeof(a2)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},UnitRange{Int64}}

    @test Base.promote_rule(typeof(sa1), typeof(sa2)) <: SimpleAxis{UInt,UnitRange{UInt}}
    @test Base.promote_rule(typeof(sa2), typeof(sa1)) <: SimpleAxis{UInt,UnitRange{UInt}}

    @test Base.promote_rule(Vector{Int}, typeof(sa1)) <: SimpleAxis{UInt,UnitRange{UInt}}
    @test Base.promote_rule(typeof(sa1), Vector{Int}) <: SimpleAxis{UInt,UnitRange{UInt}}

    @test Base.promote_rule(typeof(sa2), Base.OneTo{Int}) <: SimpleAxis{UInt,UnitRange{UInt}}
    @test Base.promote_rule(Base.OneTo{Int}, typeof(sa2)) <: SimpleAxis{UInt,UnitRange{UInt}}

    @test Base.promote_rule(typeof(sa2), typeof(1:10)) <: SimpleAxis{UInt64,UnitRange{UInt64}}
    @test Base.promote_rule(typeof(1:10), typeof(sa2)) <: SimpleAxis{UInt64,UnitRange{UInt64}}

    @test Base.promote_rule(typeof(a2), typeof(1:10)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},UnitRange{Int}}
    @test Base.promote_rule(typeof(1:10), typeof(a2)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},UnitRange{Int}}

    @test Base.promote_rule(typeof(sa2), typeof(oneto)) <: SimpleAxis{UInt64,UnitRange{UInt64}}
    @test Base.promote_rule(typeof(oneto), typeof(sa2)) <: SimpleAxis{UInt64,UnitRange{UInt64}}

    @test Base.promote_rule(typeof(a2), typeof(oneto)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Base.OneTo{Int}}
    @test Base.promote_rule(typeof(oneto), typeof(a2)) <: Axis{Float64,Int64,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Base.OneTo{Int}}
end

