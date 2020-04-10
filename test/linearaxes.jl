
@testset "LinearAxes" begin
    linaxes = LinearAxes((2.0:5.0, 1:4))
    lininds = LinearIndices((1:4, 1:4))
    @test @inferred(linaxes[10]) == 10
    for (axs, inds) in zip(collect(linaxes), collect(lininds))
        @test axs == inds
    end

    for (axs, inds) in zip(linaxes, lininds)
        @test axs == inds
    end
    @test collect(linaxes) == linaxes[1:4,1:4]
end

