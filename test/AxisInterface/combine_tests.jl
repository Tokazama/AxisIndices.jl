using AxisIndices: broadcast_axis


@testset "combine" begin
    @testset "combine" begin
        @test broadcast_axis(Axis(1:2), Axis(1:2))       isa Axis{Int64,Int64,UnitRange{Int64},Base.OneTo{Int64}}
        @test broadcast_axis(Axis(1:2), SimpleAxis(1:2)) isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}
        @test broadcast_axis(Axis(1:2), 1:2)             isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test broadcast_axis(SimpleAxis(1:2), SimpleAxis(1:2)) isa SimpleAxis{Int,UnitRange{Int}}
        @test broadcast_axis(SimpleAxis(1:2), 1:2)             isa SimpleAxis{Int,UnitRange{Int}}
        @test broadcast_axis(SimpleAxis(1:2), Axis(1:2))       isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test broadcast_axis(1:2, SimpleAxis(1:2)) isa SimpleAxis{Int,UnitRange{Int}}
        @test broadcast_axis(1:2, 1:2)             isa UnitRange{Int}
        @test broadcast_axis(1:2, Axis(1:2))       isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test broadcast_axis(1:2, Symbol.(1:2)) isa Vector{Symbol}
        @test broadcast_axis(Symbol.(1:2), 1:2) isa Vector{Symbol}

        @test broadcast_axis(1:2, string.(1:2)) isa Vector{String}
        @test broadcast_axis(string.(1:2), 1:2) isa Vector{String}

        #@test_throws ErrorException("No method available for combining keys of type Int64 and String.") combine_keys(12, "x")

        @test broadcast_axis(1:2, SimpleAxis(1:2)) isa SimpleAxis{Int,UnitRange{Int}}
    end

    @test broadcast_axis(SimpleAxis(1:2), SimpleAxis(1:2)) == SimpleAxis(1:2)
    @test Base.Broadcast.broadcast_shape((1:10,), (1:10, 1:10), (1:10,)) == (1:10, 1:10)
    @test Broadcast.combine_axes(CartesianIndices((1,)), CartesianIndices((3, 2, 2)), CartesianIndices((3, 2, 2))) ==
            Broadcast.combine_axes(CartesianAxes((1,)), CartesianIndices((3, 2, 2)), CartesianAxes((3, 2, 2)))
    @test Broadcast.combine_axes(LinearIndices((1,)), LinearIndices((3, 2, 2)), LinearIndices((3, 2, 2))) ==
            Broadcast.combine_axes(LinearAxes((1,)), CartesianAxes((3, 2, 2)), CartesianAxes((3, 2, 2)))

    cartinds = CartesianIndices((2, 2))
    cartaxes = CartesianAxes((2:3, 3:4))
    @test keys.(Broadcast.combine_axes(cartaxes, cartaxes, cartaxes)) == (2:3, 3:4)
    @test keys.(Broadcast.combine_axes(cartaxes, cartaxes, cartinds)) == (2:3, 3:4)
    @test keys.(Broadcast.combine_axes(cartaxes, cartinds, cartaxes)) == (2:3, 3:4)
    @test keys.(Broadcast.combine_axes(cartinds, cartaxes, cartaxes)) == (2:3, 3:4)
end

#=
broadcast_axis(::AxisIndices.PromoteConvert{Int64}, ::AxisIndices.Resize, ::UnitRange{Int64}, ::UnitRange{Int64}) at /Users/zchristensen/Box/Zachs_Lab_Notebook/AxisInd
ices.jl/src/traits.jl:171 (repeats 80000 times)

is_applied(PromoteConvert{Int}(), 1:2)

ps = PromoteConvert{Int}()
cs = AxisIndices.Resize()
AxisIndices.broadcast_axis(ps, cs, 1:2, 1:2)
=#
