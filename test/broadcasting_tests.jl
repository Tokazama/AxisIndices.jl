
@testset "combine" begin
    @testset "broadcast_axis" begin
        @test @inferred(broadcast_axis(Axis(1:2), Axis(1:2)))       isa Axis{Int64,Int64,UnitRange{Int64},Base.OneTo{Int64}}
        @test @inferred(broadcast_axis(Axis(1:2), SimpleAxis(1:2))) isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}
        @test @inferred(broadcast_axis(Axis(1:2), 1:2))             isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test @inferred(broadcast_axis(SimpleAxis(1:2), SimpleAxis(1:2))) isa SimpleAxis{Int,UnitRange{Int}}
        @test @inferred(broadcast_axis(SimpleAxis(1:2), 1:2))             isa SimpleAxis{Int,UnitRange{Int}}
        @test @inferred(broadcast_axis(SimpleAxis(1:2), Axis(1:2)))       isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test @inferred(broadcast_axis(1:2, SimpleAxis(1:2))) isa SimpleAxis{Int,UnitRange{Int}}
        @test @inferred(broadcast_axis(1:2, 1:2))             isa UnitRange{Int}
        @test @inferred(broadcast_axis(1:2, Axis(1:2)))       isa Axis{Int64,Int64,UnitRange{Int64},UnitRange{Int64}}

        @test @inferred(broadcast_axis(1:2, Symbol.(1:2))) isa Vector{Symbol}
        @test @inferred(broadcast_axis(Symbol.(1:2), 1:2)) isa Vector{Symbol}

        @test @inferred(broadcast_axis(1:2, string.(1:2))) isa Vector{String}
        @test @inferred(broadcast_axis(string.(1:2), 1:2)) isa Vector{String}

        #@test_throws ErrorException("No method available for combining keys of type Int64 and String.") combine_keys(12, "x")

        @test @inferred(broadcast_axis(1:2, SimpleAxis(1:2))) isa SimpleAxis{Int,UnitRange{Int}}
    end

    @test @inferred(broadcast_axis(SimpleAxis(1:2), SimpleAxis(1:2))) == SimpleAxis(1:2)
    @test @inferred(Base.Broadcast.broadcast_shape((1:10,), (1:10, 1:10), (1:10,))) == (1:10, 1:10)
    @test Broadcast.combine_axes(CartesianIndices((1,)), CartesianIndices((3, 2, 2)), CartesianIndices((3, 2, 2))) ==
            @inferred(Broadcast.combine_axes(CartesianAxes((1,)), CartesianIndices((3, 2, 2)), CartesianAxes((3, 2, 2))))
    @test Broadcast.combine_axes(LinearIndices((1,)), LinearIndices((3, 2, 2)), LinearIndices((3, 2, 2))) ==
            @inferred(Broadcast.combine_axes(LinearAxes((1,)), CartesianAxes((3, 2, 2)), CartesianAxes((3, 2, 2))))

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

@testset "Binary broadcasting operations (.+)" begin

    #= TODO moved to docs
    @testset "standard case" begin
        a = AxisIndicesArray(ones(3), (2:4,))
        @test a .+ a == 2ones(3)
        @test keys(axes(a .+ a, 1)) == 2:4

        @test a .+ a.+ a == 3ones(3)
        @test keys(axes(a .+ a .+ a, 1)) == 2:4

        @test (a .= 0 .* a .+ 7) == [7, 7, 7]
    end
    =#

    #= TODO Need to explain how order matters
    @testset "Order matters" begin
        x = AxisIndicesArray(ones(3, 5), (:, nothing))
        y = AxisIndicesArray(ones(3, 5), (nothing, :y))

        lhs = x .+ y
        rhs = y .+ x
        @test dimnames(lhs) == (:x, :y) == dimnames(rhs)
        @test lhs == 2ones(3, 5) == rhs
    end
    =#

   @testset "broadcasting" begin
        v = AxisIndicesArray(zeros(3,), (2:4,))
        m = AxisIndicesArray(ones(3, 3), (2:4, 3:5))
        s = 0

        @test @inferred(v .+ m) == ones(3, 3) == @inferred(m .+ v)
        @test @inferred(s .+ m) == ones(3, 3) == @inferred(m .+ s)
        @test @inferred(s .+ v .+ m) == ones(3, 3) == @inferred(m .+ s .+ v)

        @test keys.(axes(v .+ m)) == (2:4, 3:5) == keys.(axes(m .+ v))
        @test keys.(axes(s .+ m)) == (2:4, 3:5) == keys.(axes(m .+ s))
        @test keys.(axes(s .+ v .+ m)) == (2:4, 3:5) == keys.(axes(m .+ s .+ v))
    end
end

