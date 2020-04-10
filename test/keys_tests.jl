
@testset "keys" begin
    a1 = Axis(2:3 => 1:2)

    @test keytype(typeof(Axis(1.0:10.0))) <: Float64
    @test haskey(a1, 3)
    @test !haskey(a1, 4)
     
    @testset "reverse_keys" begin
        axis = Axis(1:10)
        saxis = SimpleAxis(1:10)
        @test reverse_keys(axis) == reverse_keys(saxis)
        @test keys(reverse_keys(axis)) == keys(reverse_keys(saxis))
    end
end

