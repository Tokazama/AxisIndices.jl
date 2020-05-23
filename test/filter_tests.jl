
@testset "filter" begin
    a = AxisIndicesArray([11 12; 21 22], (2:3, 3:4))
    v = AxisIndicesArray(1:7, (2:8,))

    @test axes_keys(@inferred(filter(isodd, v))) == ([2, 4, 6, 8],)
    @test axes_keys(filter(isodd, a)) == ([2, 3],)
end

