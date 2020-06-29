
@testset "Axes - indexing" begin

    @testset "NamedCartesianAxes" begin
        @test @inferred(NamedCartesianAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]))) ==
              @inferred(NamedCartesianAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]))
        @test @inferred(NamedCartesianAxes((dimx = [:a, :b], dimy = ["one", "two"]))) ==
              @inferred(NamedCartesianAxes(NamedAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"])))
    end

    @testset "NamedLinearAxes" begin
        @test @inferred(NamedLinearAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]))) ==
              @inferred(NamedLinearAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]))
        @test @inferred(NamedLinearAxes((dimx = [:a, :b], dimy = ["one", "two"]))) ==
              @inferred(NamedLinearAxes(NamedAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"])))
    end

    @testset "NamedCartesianAxes" begin
        @test @inferred(NamedMetaCartesianAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaCartesianAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]; metadata="some metadata"))
        @test @inferred(NamedMetaCartesianAxes((dimx = [:a, :b], dimy = ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaCartesianAxes(NamedMetaAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"]; metadata="some metadata")))
    end

    @testset "NamedLinearAxes" begin
        @test @inferred(NamedMetaLinearAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaLinearAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]; metadata="some metadata"))
        @test @inferred(NamedMetaLinearAxes((dimx = [:a, :b], dimy = ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaLinearAxes(NamedMetaAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"]; metadata="some metadata")))
    end
end
