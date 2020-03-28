
@testset "Array Interface" begin
    x = AxisIndicesArray([1 2; 3 4])
    @test AxisIndices.parent_type(typeof(x)) == AxisIndices.parent_type(x) == Array{Int,2}
    @test size(x) == (2, 2)
    @test parentindices(x) == parentindices(parent(x))

    @test x[CartesianIndex(2,2)] == 4
    x[CartesianIndex(2,2)] = 5
    @test x[CartesianIndex(2,2)] == 5

    @test axes_keys(similar(x, (2:3, 4:5))) == (2:3, 4:5)
    @test eltype(similar(x, Float64, (2:3, 4:5))) <: Float64
    @test_throws ErrorException AxisIndicesArray(rand(2,2), (2:9,2:1))
end

@testset "PermuteDimsArray" begin
    x = AxisIndicesArray(ones(2,2))
    y = PermutedDimsArray(x, (2, 1))
    @test axes(y) isa Tuple{SimpleAxis, SimpleAxis}
    @test axes(y, 1) isa SimpleAxis
end

@testset "I/O" begin
    io = IOBuffer()
    x = AxisIndicesArray([1 2; 3 4])
    write(io, x)

    seek(io, 0)
    y = AxisIndicesArray(Array{Int}(undef, 2, 2))
    read!(io, y)

    @test y == x
end

@testset "Interface" begin
    A = typeof(AxisIndicesArray(ones(1), SimpleAxis(1)))
    @test @inferred(AxisIndices.axes_type(A)) <: Tuple{SimpleAxis{Int,Base.OneTo{Int}}}
    @test @inferred(AxisIndices.keys_type(A)) <: Base.OneTo{Int}
    @test @inferred((A -> AxisIndices.values_type(A, 1))(A)) <: Base.OneTo{Int}
    @test @inferred((A -> AxisIndices.keys_type(A, 1))(A)) <: Base.OneTo{Int}
end
