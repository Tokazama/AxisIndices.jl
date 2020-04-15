
@testset "append tests" begin
    @test append_axis!(CombineStack(), [1, 2], [3, 4]) == [1, 2, 3, 4]
    @test_throws ErrorException append_axis!(CombineStack(), 1:3, 3:4)
end

