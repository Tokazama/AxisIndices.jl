
@testset "ReadonlyMappedArray" begin
    a = AxisIndicesArray([1,4,9,16], ["one", "two", "three", "four"])
    s = view(a', 1:1, [1,2,4])

    b = @inferred(mappedarray(sqrt, a))
    @test parent(parent(b)) === parent(a)
    @test eltype(b) == Float64
    @test @inferred(getindex(b, 1)) == 1
    @test b[2] == 2 == b["two"]
    @test b[3] == 3 == b["three"]
    @test b[4] == 4 == b["four"]
    @test_throws ErrorException b[3] = 0
    @test isa(eachindex(b), AbstractUnitRange)
    b = mappedarray(sqrt, a')
    @test isa(eachindex(b), AbstractUnitRange)
    b = mappedarray(sqrt, s)
    @test isa(eachindex(b), CartesianIndices)
end

@testset "MappedArray" begin
    intsym = Int == Int64 ? :Int64 : :Int32
    a = AxisIndicesArray([1,4,9,16], ["one", "two", "three", "four"])
    s = view(a', 1:1, [1,2,4])
    c = @inferred(mappedarray(sqrt, x->x*x, a))
    @test parent(parent(c)) === parent(a)
    @test @inferred(getindex(c, 1)) == 1
    @test c[2] == 2 == c["two"]
    @test c[3] == 3 == c["three"]
    @test c[4] == 4 == c["four"]
    c[3] = 2
    @test a[3] == 4
    @test_throws InexactError(intsym, Int, 2.2^2) c[3] = 2.2  # because the backing array is Array{Int}
    @test isa(eachindex(c), AbstractUnitRange)
    b = @inferred(mappedarray(sqrt, a'))
    @test isa(eachindex(b), AbstractUnitRange)
    c = @inferred(mappedarray(sqrt, x->x*x, s))
    @test isa(eachindex(c), CartesianIndices)

    sb = similar(b)
    @test isa(sb, AxisIndicesArray{Float64})
    @test size(sb) == size(b)

    a = AxisIndicesArray([0x01 0x03; 0x02 0x04], ["a", "b"], ["one", "two"])
    b = @inferred(mappedarray(y->N0f8(y,0), x->x.i, a))
    for i = 1:4
        @test b[i] == N0f8(i/255)
    end
    b[2,1] = 10/255
    @test a[2,1] == 0x0a
    @test a["b", "one"] == 0x0a
end

@testset "of_eltype" begin
    a = AxisIndicesArray([0.1 0.3; 0.2 0.4], ["a", "b"], ["one", "two"])
    b = @inferred(of_eltype(N0f8, a))
    @test b[1,1] === N0f8(0.1) === b["a", "one"]
    b = @inferred(of_eltype(zero(N0f8), a))
    b[2,1] = N0f8(0.5)
    @test a[2,1] == a["b", "one"] == N0f8(0.5)
    @test !(b === a)
    b = @inferred(of_eltype(Float64, a))
    @test b === a
    b = @inferred(of_eltype(0.0, a))
    @test b === a
end

@testset "No zero(::T)" begin
    astr = @inferred(mappedarray(length, AxisIndicesArray(["abc", "onetwothree"])))
    @test eltype(astr) == Int
    @test astr == [3, 11]
    a = @inferred(mappedarray(x->x+0.5, Int[]))
    @test eltype(a) == Float64

    # typestable string
    astr = @inferred(mappedarray(uppercase, AxisIndicesArray(["abc", "def"])))
    @test eltype(astr) == String
    @test astr == ["ABC","DEF"]
end

@testset "ReadOnlyMultiMappedArray" begin
    a = AxisIndicesArray(reshape(1:6, 2, 3), ["a", "b"], ["one", "two", "three"])
    b = AxisIndicesArray(fill(10.0f0, 2, 3), ["a", "b"], ["one", "two", "three"])
    M = @inferred(mappedarray(+, a, b))
    @test @inferred(eltype(M)) == Float32
    @test @inferred(IndexStyle(M)) == IndexLinear()
    @test @inferred(IndexStyle(typeof(M))) == IndexLinear()
    @test @inferred(size(M)) === size(a)
    @test @inferred(axes(M)) === axes(a)
    @test M == a + b
    @test @inferred(M[1]) === 11.0f0
    @test @inferred(M[CartesianIndex(1, 1)]) === 11.0f0

    c = AxisIndicesArray(view(reshape(1:9, 3, 3), 1:2, :), ["a", "b"], ["one", "two", "three"])
    M = @inferred(mappedarray(+, c, b))
    @test @inferred(eltype(M)) == Float32
    @test @inferred(IndexStyle(M)) == IndexCartesian()
    @test @inferred(IndexStyle(typeof(M))) == IndexCartesian()
    @test @inferred(axes(M)) === axes(c)
    @test M == c + b
    @test @inferred(M[1]) === 11.0f0
    @test @inferred(M[CartesianIndex(1, 1)]) === 11.0f0
end

@testset "MultiMappedArray" begin
    intsym = Int == Int64 ? :Int64 : :Int32
    a = AxisIndicesArray([0.1 0.2; 0.3 0.4], ["a", "b"], ["one", "two"])
    b = AxisIndicesArray(N0f8[0.6 0.5; 0.4 0.3], ["a", "b"], ["one", "two"])
    c = AxisIndicesArray([0 1; 0 1], ["a", "b"], ["one", "two"])
    f = RGB{N0f8}
    finv = c->(red(c), green(c), blue(c))
    M = @inferred(mappedarray(f, finv, a, b, c))
    @test @inferred(eltype(M)) == RGB{N0f8}
    @test @inferred(IndexStyle(M)) == IndexLinear()
    @test @inferred(IndexStyle(typeof(M))) == IndexLinear()
    @test @inferred(size(M)) === size(a)
    @test @inferred(axes(M)) === axes(a)
    @test M[1,1] === RGB{N0f8}(0.1, 0.6, 0)
    @test M[2,1] === RGB{N0f8}(0.3, 0.4, 0)
    @test M[1,2] === RGB{N0f8}(0.2, 0.5, 1)
    @test M[2,2] === RGB{N0f8}(0.4, 0.3, 1)
    M[1,2] = RGB(0.25, 0.35, 0)
    @test M[1,2] === RGB{N0f8}(0.25, 0.35, 0)
    @test a[1,2] == N0f8(0.25)
    @test b[1,2] == N0f8(0.35)
    @test c[1,2] == 0
    R = reinterpret(N0f8, M)
    @test R == N0f8[0.1 0.25; 0.6 0.35; 0 0; 0.3 0.4; 0.4 0.3; 0 1]
    R[2,1] = 0.8
    @test b[1,1] === N0f8(0.8) === b["a", "one"]

    a = AxisIndicesArray(view(reshape(0.1:0.1:0.6, 3, 2), 1:2, 1:2), ["a", "b"], ["one", "two"])
    M = @inferred(mappedarray(f, finv, a, b, c))
    @test @inferred(eltype(M)) == RGB{N0f8}
    @test @inferred(IndexStyle(M)) == IndexCartesian()
    @test @inferred(IndexStyle(typeof(M))) == IndexCartesian()
    @test @inferred(axes(M)) === axes(a)
    @test M[1,1] === RGB{N0f8}(0.1, 0.8, 0) === M["a", "one"]
    @test_throws ErrorException("indexed assignment fails for a reshaped range; consider calling collect") M[1,2] = RGB(0.25, 0.35, 0)

    a = AxisIndicesArray(reshape(0.1:0.1:0.6, 3, 2), ["a", "b", "c"], ["one", "two"])
    @test_throws DimensionMismatch mappedarray(f, finv, a, b, c)
end

#= TODO MappedArrays tests
@testset "OffsetArrays" begin
    a = OffsetArray(randn(5), -2:2)
    aabs = mappedarray(abs, a)
    @test axes(aabs) == (-2:2,)
    for i = -2:2
        @test aabs[i] == abs(a[i])
    end
end
=#
