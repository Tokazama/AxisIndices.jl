
@testset "insert!" begin
    v = AxisVector{Int}()
    push!(v, 1)
    insert!(v, 1, 1)
    insert!(v, 1, 1.0)
    @test v == [1, 1, 1]

    v = AxisVector([1,2,3])
    @test axes_keys(@inferred(reverse(v))) == (3:-1:1,)

    v = AxisVector([1,2,3], ["a", "b", "c"])
    @test axes_keys(@inferred(reverse(v))) == (["c", "b", "a"],)

    # TODO should this be a strict key array still?
    v = OffsetVector([1,2,3], 1)
    @test axes_keys(@inferred(reverse(v))) == (4:-1:2,)
end


