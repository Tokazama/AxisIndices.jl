
@testset "Axis" begin
    axis = Axis()

    a1 = Axis(2:3 => 1:2)
    axis = Axis(1:10)

    @test UnitRange(a1) == 1:2

    @test @inferred(Axis(a1)) isa typeof(a1)

    @test @inferred(Axis(1:10)) isa Axis{UnitRange{Int},SimpleAxis{DOneTo}}

    #= FIXME
    @test @inferred(Axis{UnitRange{Int},SimpleAxis{UnitMRange{Int}}}(1:10)) isa Axis{UnitRange{Int},SimpleAxis{DUnitRange}}

    @test @inferred(Axis{UnitMRange{Int},SimpleAxis{UnitRange{Int}}}(1:10)) isa Axis{UnitMRange{Int},SimpleAxis{DUnitRange}}

    @test @inferred(Axis{UnitMRange{Int},SimpleAxis{UnitMRange{Int}}}(1:10)) isa Axis{UnitMRange{Int},SimpleAxis{DUnitRange}}

    @test @inferred(Axis{UnitRange{UInt},SimpleAxis{UnitRange{Int}}}(1:2)) isa Axis{UnitRange{UInt},SimpleAxis{UnitRange{Int}}}
    @test @inferred(Axis{UnitRange{UInt},SimpleAxis{UnitRange{Int}}}(UnitRange(UInt(1), UInt(2)))) isa Axis{UnitRange{UInt},SimpleAxis{UnitRange{Int}}}

    @test Axis{Vector{String},Base.OneTo{Int}}(Axis(["a", "b"])) isa Axis{String,Int,Vector{String},Base.OneTo{Int}}

    @test Axis{UnitRange{Int},SimpleAxis{UnitRange{Int}}}(Base.OneTo(2)) isa Axis{UnitRange{Int},SimpleAxis{UnitRange{Int}}}
    @test Axis{UnitRange{Int},SimpleAxis{UnitRange{Int}}}(1:2) isa Axis{UnitRange{Int},SimpleAxis{UnitRange{Int}}}
    @test Axis{UnitRange{Int},SimpleAxis{Base.OneTo{Int}}}(Base.OneTo(2)) isa Axis{UnitRange{Int},SimpleAxis{Base.OneTo{Int}}}
    @test Axis{UnitRange{Int},SimpleAxis{Base.OneTo{Int}}}(1:2) isa Axis{UnitRange{Int},SimpleAxis{Base.OneTo{Int}}}
    =#
end

   #@test @inferred(AxisIndices.to_axis(a1)) == a1

        #= TODO problems with `==` due to == on axes
        @testset "View axes" begin
            a = rand(8)
            idr = IdentityAxis(2:4)
            v = view(a, idr)
            @test axes(v) == (2:4,)
            @test v == OffsetArray(a[2:4], 2:4)

            a = rand(5, 5)
            idr2 = IdentityAxis(3:4)
            v = view(a, idr, idr2)
            @test axes(v) == (2:4, 3:4)
            @test v == OffsetArray(a[2:4, 3:4], 2:4, 3:4)
        end
        =#

#= FIXME
@testset "AbstractAxis promotions" begin
    a1 = typeof(Axis(1:10))
    a2 = typeof(Axis(1.0:10.0))
    sa1 = typeof(SimpleAxis(1:10))
    sa2 = typeof(SimpleAxis(UnitRange(UInt(1), UInt(10))))
    p = typeof(Base.OneTo(10))
    pur = typeof(1:10)

    @test promote_type(sa1, sa2) <: SimpleAxis{DUnitRange}
    @test promote_type(p, sa2) <: SimpleAxis{DUnitRange}
    @test promote_type(sa2, p) <: SimpleAxis{DUnitRange}
    @test promote_type(pur, sa2) <: SimpleAxis{DUnitRange}
    @test promote_type(sa2, pur) <: SimpleAxis{DUnitRange}
    @test promote_type(p, sa1) <: SimpleAxis{DUnitRange}
    @test promote_type(sa1, p) <: SimpleAxis{DUnitRange}
    @test promote_type(pur, sa1) <: SimpleAxis{DUnitRange}
    @test promote_type(sa1, pur) <: SimpleAxis{DUnitRange}

    @test promote_type(Vector{Int}, sa1) <: AbstractVector{Int}
    @test promote_type(sa1, Vector{Int}) <: AbstractVector{Int}

    a12 = Axis{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},SimpleAxis{ArrayInterface.OptionallyStaticUnitRange{ArrayInterface.StaticInt{1},Int64}}}
    @test promote_type(a1, a2) <: a12
    @test promote_type(a2, a1) <: a12
    @test promote_type(a1, sa1) <: Axis{UnitRange{Int},SimpleAxis{DUnitRange}}
    @test promote_type(sa1, a1) <: Axis{UnitRange{Int},SimpleAxis{DUnitRange}}
    @test promote_type(a2, sa1) <: Axis{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},SimpleAxis{DUnitRange}}
    @test promote_type(sa1, a2) <: Axis{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},SimpleAxis{DUnitRange}}
    @test promote_type(a2, pur) <: Axis{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},SimpleAxis{DUnitRange}}
    @test promote_type(pur, a2) <: Axis{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},SimpleAxis{DUnitRange}}

    # FIXME this is a problem with promotion on ArrayInterface.OptionallyStaticUnitRange, not AxisIndices
    @test_broken promote_type(a2, p) <: Axis{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},SimpleAxis{DUnitRange}}
    @test_broken promote_type(p, a2) <: Axis{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},SimpleAxis{DUnitRange}}

    @test @inferred(keys(ArrayInterface.to_axis(Axis([:a, :b]), [2]))) == [:b]
end
=#

