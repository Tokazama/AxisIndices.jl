@testset "combine" begin
    @testset "combine_axis" begin
        @test combine_axis(Axis(1:2), Axis(1:2))       isa Axis{Int64,Int64,UnitRange{Int64},Base.OneTo{Int64}}
        @test combine_axis(Axis(1:2), SimpleAxis(1:2)) isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}
        @test combine_axis(Axis(1:2), 1:2)             isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}
        @test combine_axis(Axis(1:2), Axis2(1:2, 1:2)) isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test combine_axis(Axis2(1:2, 1:2), Axis(1:2))       isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}
        @test combine_axis(Axis2(1:2, 1:2), SimpleAxis(1:2)) isa SimpleAxis{Int64,UnitRange{Int64}}

        @test combine_axis(SimpleAxis(1:2), SimpleAxis(1:2)) isa SimpleAxis{Int,UnitRange{Int}}
        @test combine_axis(SimpleAxis(1:2), 1:2)             isa SimpleAxis{Int,UnitRange{Int}}
        @test combine_axis(SimpleAxis(1:2), Axis(1:2))       isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}
        #@test combine_axis(SimpleAxis(1:2), Axis2(1:2, 1:2)) isa Axis2{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test combine_axis(1:2, SimpleAxis(1:2)) isa SimpleAxis{Int,UnitRange{Int}}
        @test combine_axis(1:2, 1:2)             isa UnitRange{Int}
        @test combine_axis(1:2, Axis(1:2))       isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test combine_keys(1:2, Symbol.(1:2)) isa Vector{Symbol}
        @test combine_keys(Symbol.(1:2), 1:2) isa Vector{Symbol}

        @test combine_keys(1:2, string.(1:2)) isa Vector{String}
        @test combine_keys(string.(1:2), 1:2) isa Vector{String}

        @test_throws ErrorException("No method available for combining keys of type Int64 and String.") combine_keys(12, "x")

        @test combine_axis(1:2, SimpleAxis(1:2)) isa SimpleAxis{Int,UnitRange{Int}}
    end

    @test combine_axis(SimpleAxis(1:2), SimpleAxis(1:2)) == SimpleAxis(1:2)
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


