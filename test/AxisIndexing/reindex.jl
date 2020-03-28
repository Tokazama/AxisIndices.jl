
@testset "reindex" begin
    axs = (Axis(2:10), Axis(2:10), Axis(2:10))
    @test @inferred(reindex(axs, (1, 1:9, 1:9))) == (Axis(2:10), Axis(2:10))
end

