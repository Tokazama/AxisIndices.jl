
@testset "dropdims" begin
    axs = (Axis(["a", "b"]), Axis([:a]), Axis([1.0]), Axis(1:2))
    @test map(keys, AxisIndices.AxisIndexing.drop_axes(axs, 2)) == (["a", "b"], [1.0], 1:2)
    @test map(keys, AxisIndices.AxisIndexing.drop_axes(axs, (2, 3))) == (["a", "b"], 1:2)

    a = AxisIndicesArray(ones(10, 1, 1, 20), (2:11, [:a], 4:4, 5:24));

    @test dropdims(a; dims=2) == ones(10, 1, 20)
    @test axes_keys(dropdims(a; dims=2)) == (2:11, 4:4, 5:24)

    @test dropdims(a; dims=(2, 3)) == ones(10, 20)
    @test axes_keys(dropdims(a; dims=(2, 3))) == (2:11, 5:24)
end

