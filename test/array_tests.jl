
@testset "Array Interface" begin
    x = AxisArray([1 2; 3 4]);
    @test parent_type(typeof(x)) == parent_type(x) == Array{Int,2}
    @test size(x) == (2, 2)
    @test parentindices(x) == parentindices(parent(x))

    @test similar_type(x, Array{Float64,2}) <: AxisArray{Float64,2,Array{Float64,2},Tuple{SimpleAxis{Int64,OneTo{Int64}},SimpleAxis{Int64,OneTo{Int64}}}}

    @test x[CartesianIndex(2,2)] == 4
    x[CartesianIndex(2,2)] = 5
    @test x[CartesianIndex(2,2)] == 5

    @test eltype(similar(x, Float64, (2:3, 4:5))) <: Float64
    @test_throws DimensionMismatch AxisArray(rand(2,2), (2:9,2:1))

    x = AxisArray(reshape(1:8, 2, 2, 2));
    @test @inferred(x[CartesianIndex(1,1), 1]) == 1
    @test @inferred(x[CartesianIndex(1,1), :]) == parent(parent(x)[CartesianIndex(1,1), :])
    @test @inferred(x[:, CartesianIndex(1,1)]) == parent(parent(x)[:, CartesianIndex(1,1)])
    @test @inferred(x[[true,true], CartesianIndex(1,1)]) == parent(parent(x)[[true,true], CartesianIndex(1,1)])
end

@testset "PermuteDimsArray" begin
    x = AxisArray(ones(2,2))
    y = PermutedDimsArray(x, (2, 1))
    @test axes(y) isa Tuple{SimpleAxis, SimpleAxis}
    @test axes(y, 1) isa SimpleAxis
end

@testset "I/O" begin
    io = IOBuffer()
    x = AxisArray([1 2; 3 4])
    write(io, x)

    seek(io, 0)
    y = AxisArray(Array{Int}(undef, 2, 2))
    read!(io, y)

    @test y == x
end

@testset "Interface" begin
    A = typeof(AxisArray(ones(1), SimpleAxis(1)))
    @test @inferred(axes_type(A)) <: Tuple{SimpleAxis{Int,Base.OneTo{Int}}}
    @test @inferred(AxisIndices.keys_type(A)) <: Base.OneTo{Int}
    @test @inferred((A -> AxisIndices.indices_type(A, 1))(A)) <: Base.OneTo{Int}
    @test @inferred((A -> AxisIndices.keys_type(A, 1))(A)) <: Base.OneTo{Int}
end

@testset "resize!" begin
    x = AxisArray(ones(3))
    resize!(x, 2)
    @test x == [1, 1]
end

@testset "view" begin
    A = [1 2; 3 4]
    Aaxes = AxisArray(A, ["a", "b"], 2.0:3.0)

    A_view = @inferred(view(A, :, 1))
    Aaxes_view = @inferred(view(Aaxes, :, 1))
    @test A_view == Aaxes_view

    fill!(A_view, 0)
    fill!(Aaxes_view, 0)
    @test A_view == Aaxes_view
    @test A_view == Aaxes_view
end

@testset "push!" begin
    x = AxisArray([1], [:a])
    push!(x, :b => 2)
    @test axes_keys(x, 1) == [:a, :b]
    @test x == [1, 2]
    pushfirst!(x, :pre_a => 0)
    @test axes_keys(x, 1) == [:pre_a, :a, :b]
    @test x == [0, 1, 2]
end

