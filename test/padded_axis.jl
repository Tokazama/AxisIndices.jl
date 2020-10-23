
@testset "PaddedAxis" begin
    x = [:a, :b, :c, :d, :e]
    @test AxisArray(x, circular_pad(first_pad=3, last_pad=3)) == [:c, :d, :e, :a, :b, :c, :d, :e, :a, :b, :c]
    @test AxisArray(x, replicate_pad(first_pad=3, last_pad=3)) == [:a, :a, :a, :a, :b, :c, :d, :e, :e, :e, :e]
    @test AxisArray(x, symmetric_pad(first_pad=3, last_pad=3)) == [:d, :c, :b, :a, :b, :c, :d, :e, :d, :c, :b]
    @test AxisArray(x, reflect_pad(first_pad=3, last_pad=3)) == [:c, :b, :a, :a, :b, :c, :d, :e, :e, :d, :c]
    @test AxisArray(1:2, zero_pad(sym_pad=2)) == [0, 0, 1, 2, 0, 0]
    @test AxisArray(1:2, one_pad(sym_pad=2)) == [1, 1, 1, 2, 1, 1]

    A = @inferred(AxisArray(reshape(1:6, 3, 2), replicate_pad(first_pad=2, last_pad=2), replicate_pad(first_pad=2, last_pad=2)))
    @test @inferred(IndexStyle(A)) isa IndexCartesian
end

