
@testset "copyto!" begin
    a = AxisArray{Int}(undef, (-3:-1,))
    fill!(a, -1)
    copyto!(a, (1,2))   # non-array iterables
    @test a[-3] == 1
    @test a[==(-2)] == 2
    @test a[==(-1)] == -1
    fill!(a, -1)
    copyto!(a, -2, (1, 2))
    @test a[==(-3)] == -1
    @test a[==(-2)] == 1
    @test a[==(-1)] == 2
    fill!(a, -1)
    copyto!(a, -2, (1,2,3), 2)
    @test a[==(-3)] == -1
    @test a[==(-2)] == 2
    @test a[==(-1)] == 3

    # FIXME
    b = 1:2    # copy between AbstractArrays
    bo = AxisArray(1:2, (-3:-2,))
    fill!(a, -1)
    copyto!(a, bo)
    @test a[-3] == 1
    @test a[-2] == 2
    @test a[-1] == -1

    fill!(a, -1)
    copyto!(a, -2, bo)
    @test a[==(-3)] == -1
    @test a[==(-2)] == 1
    @test a[==(-1)] == 2
    fill!(a, -1)
    copyto!(a, -1, b, 2)
    @test a[-1] == 2
    @test a[-2] == a[-3] == -1
    # FIXME
    am = AxisArray{Int}(undef, (1:1, 7:9))  # for testing linear indexing
    fill!(am, -1)
    copyto!(am, b)
    @test am[1] == 1
    @test am[2] == 2
    @test am[3] == -1
    @test am[1,==(7)] == 1
    @test am[1,==(8)] == 2
    @test am[1,==(9)] == -1
end

