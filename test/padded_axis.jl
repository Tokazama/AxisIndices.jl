
@testset "PaddedAxis" begin
    x = [:a, :b, :c, :d, :e]
    @test AxisArray(x, circular_pad(first_pad=3, last_pad=3)) == [:c, :d, :e, :a, :b, :c, :d, :e, :a, :b, :c]
    @test AxisArray(x, replicate_pad(first_pad=3, last_pad=3)) == [:a, :a, :a, :a, :b, :c, :d, :e, :e, :e, :e]
    @test AxisArray(x, symmetric_pad(first_pad=3, last_pad=3)) == [:d, :c, :b, :a, :b, :c, :d, :e, :d, :c, :b]
    @test AxisArray(x, reflect_pad(first_pad=3, last_pad=3)) == [:c, :b, :a, :a, :b, :c, :d, :e, :e, :d, :c]
    @test AxisArray(1:2, one_pad(sym_pad=2)) == [1, 1, 1, 2, 1, 1]
    @test AxisArray(1:2, zero_pad(sym_pad=2)) == [0, 0, 1, 2, 0, 0]

    x = reshape(1:6, 3, 2)
    ax = @inferred(AxisArray(x, replicate_pad(sym_pad=2), replicate_pad(sym_pad=2)))
    @test ax == @inferred(replicate_pad(x; sym_pad=2))
    @test eltype(x) <: eltype(ax)
    @test axes(ax) == (-1:5, -1:4)
    cax = collect(ax)
    @test cax == ax
    @test axes(cax, 1) isa OffsetAxis
    @test @inferred(IndexStyle(ax)) isa IndexCartesian

    axis = zero_pad(SimpleAxis(ArrayInterface.StaticInt(2)); sym_pad=ArrayInterface.StaticInt(2))
    @test ArrayInterface.known_first(axis) === -1
    @test ArrayInterface.known_last(axis) === 4
    @test ArrayInterface.known_length(axis) === 6

    axis = zero_pad(1:2, sym_pad=2)
    @test ArrayInterface.known_first(axis) === nothing
    @test ArrayInterface.known_last(axis) === nothing
    @test ArrayInterface.known_length(axis) === nothing

    axis = eachindex(AxisArray(3:4, one_pad(sym_pad=2)))
    x = map(identity, axis)
    @test x == axis
    @test axes(x, 1) == axis
end

