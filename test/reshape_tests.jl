
@testset "reshape" begin
    V = AxisIndicesArray(Vector(1:8), [:a, :b, :c, :d, :e, :f, :g, :h]);

    A = @inferred(reshape(V, 4, 2));
    @test axes(A) == (Axis([:a, :b, :c, :d] => Base.OneTo(4)), SimpleAxis(Base.OneTo(2)))

    @test axes(@inferred(reshape(A, 2, :))) == (Axis([:a, :b] => Base.OneTo(2)), SimpleAxis(Base.OneTo(4)))

end

