
@testset "insert!" begin
    v = AxisVector{Int}()
    push!(v, 1)
    insert!(v, 1, 1)
    insert!(v, 1, 1.0)
    @test v == [1, 1, 1]
end


