
@testset "checkbounds" begin

    x = Axis(1:10)
    @test Base.checkindex(Bool, x, Base.Slice(1:10))
    @test Base.checkindex(Bool, x, [1,2,3])
    @test !Base.checkindex(Bool, x, [0, 1,2,3])

    @test checkbounds(Bool, Axis(1:2), CartesianIndex(1))
    @test !checkbounds(Bool, Axis(1:2), CartesianIndex(3))

    x2 = Axis(1:2)
    @test Base.checkindex(Bool, x2, x2 .> 3)

    @test Base.checkindex(Bool, x2, 1:2)
    @test !Base.checkindex(Bool, x2, 1:3)

    @test Base.checkindex(Bool, x2, [true, true])
    @test !Base.checkindex(Bool, x2, [true, true, true])

    # trigger errors when functions return bad indices
    @test_throws BoundsError Base.to_index(Axis(1:10), ==(11))
end
