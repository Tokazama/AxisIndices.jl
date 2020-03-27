
using AxisIndices: broadcast_axis
using Base.Broadcast: broadcasted
bstyle = Base.Broadcast.DefaultArrayStyle{1}()

@testset "combine" begin
    @testset "broadcast_axis" begin
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

@testset "Broadcasting" begin
    x = Axis(1:10, 1:10)
    y = SimpleAxis(1:10)
    z = 1:10

    @test @inferred(broadcasted(bstyle, -, 2, x)) ==
          @inferred(broadcasted(bstyle, -, 2, y)) ==
          broadcasted(bstyle, -, 2, z)

    @test @inferred(broadcasted(bstyle, -, x, 2)) ==
          @inferred(broadcasted(bstyle, -, y, 2)) ==
          broadcasted(bstyle, -, z, 2)

    @test @inferred(broadcasted(bstyle, +, 2, x)) ==
          @inferred(broadcasted(bstyle, +, 2, y)) ==
          broadcasted(bstyle, +, 2, z)
    @test isa(broadcasted(bstyle, +, 2, x), Axis)
    @test isa(broadcasted(bstyle, +, 2, y), SimpleAxis)

    @test @inferred(broadcasted(bstyle, +, x, 2)) ==
          @inferred(broadcasted(bstyle, +, y, 2)) ==
          broadcasted(bstyle, +, z, 2)
    @test isa(broadcasted(bstyle, +, x, 2), Axis)
    @test isa(broadcasted(bstyle, +, y, 2), SimpleAxis)

    @test @inferred(broadcasted(bstyle, *, 2, x)) ==
          @inferred(broadcasted(bstyle, *, 2, y)) ==
          broadcasted(bstyle, *, 2, z)

    @test @inferred(broadcasted(bstyle, *, x, 2)) ==
          @inferred(broadcasted(bstyle, *, y, 2)) ==
          broadcasted(bstyle, *, z, 2)
end

