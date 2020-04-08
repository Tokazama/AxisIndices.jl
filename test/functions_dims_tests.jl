@testset "dropdims" begin
    a = AxisIndicesArray(ones(10, 1, 1, 20), (2:11, [:a], 4:4, 5:24));

    @test dropdims(a; dims=2) == ones(10, 1, 20)
    @test axes_keys(dropdims(a; dims=2)) == (2:11, 4:4, 5:24)

    @test dropdims(a; dims=(2, 3)) == ones(10, 20)
    @test axes_keys(dropdims(a; dims=(2, 3))) == (2:11, 5:24)
end

#= TODO

dims = 2
a = AxisIndicesArray(ones(10, 1, 1, 20), (2:11, 3:3, 4:4, 5:24))

p = dropdims(parent(a); dims=dims)
axs = AxisIndices.drop_axes(a, dims)

AxisIndices.unsafe_reconstruct(a, p, axs)
@testset "reshape" begin
    a = NamedDimsArray(rand(2, 3), (:r, :c))

    @test reshape(nda, 3, 2) isa Array
    @test reshape(nda, 1, :) isa Array
    @test reshape(nda, :) isa Array
    @test vec(nda) isa Array
end
=#

# FIXME spits out Crazy errors
@testset "selectdim" begin
    a = AxisIndicesArray(reshape(1:6, (2, 3)), (2:3, 2:4))

    @test selectdim(a, 1, 1) == a[1, :]
    @test axes_keys(selectdim(a, 1, 1)) == (2:4,)

    @test vec(selectdim(a, 1, 1:1)) == a[1, :]
    @test axes_keys(selectdim(a, 1, 1:1)) == (2:2, 2:4)
end

@testset "$f" for f in (adjoint, transpose, permutedims)
    @testset "Vector $f" begin
        v = AxisIndicesArray([10, 20, 30], (2:4,))
        @test f(v) == [10 20 30]
        @test axes_keys(f(v)) == (1:1, 2:4)

        if f === permutedims
            # unlike adjoint and tranpose, permutedims should not be its own inverse
            # The new dimension should stick around
            @test f(f(v)) == reshape([10, 20, 30], Val(2))
            @test keys.(axes(f(f(v)))) == (2:4, 1:1)
        else
            # Make sure vector double adjoint gets you back to the start.
            @test f(f(v)) == [10, 20, 30]
            @test keys.(axes(f(f(v)))) == (2:4,)
        end
    end

    @testset "Matrix $f" begin
        m = AxisIndicesArray([10 20 30; 11 22 33], (2:3, 2:4))
        @test f(m) == [10 11; 20 22; 30 33]
        @test keys.(axes(f(m))) == (2:4, 2:3)

        # Make sure implementation of matrix double adjoint is correct
        # since it is easy for the implementation of vector double adjoint broke it
        @test f(f(m)) == [10 20 30; 11 22 33]
        @test keys.(axes(f(f(m)))) == (2:3, 2:4)
    end
end

@testset "permutedims" begin
    v = AxisIndicesArray([10, 20, 30], (2:4,))
    @test axes_keys(permutedims(transpose(v))) == (2:4, 1:1)

    a = AxisIndicesArray(ones(10, 20, 30, 40), (2:11, 2:21, 2:31, 2:41));
    @test (axes_keys(permutedims(a, (1, 2, 3, 4))) ==
           axes_keys(permutedims(a, 1:4)) ==
           (2:11, 2:21, 2:31, 2:41)
    )

    @test (keys.(axes(permutedims(a, (1, 3, 2, 4)))) == (2:11, 2:31, 2:21, 2:41))
end

# We test pinv here as it is defined in src/function_dims.jl
# using the same logic as permutedims, transpose etc
@testset "pinv" begin
    @testset "Matrix" begin
        a = AxisIndicesArray([1.0 2 3; 4 5 6], (2:3, 4:6))
        @test keys.(axes(pinv(a))) == (4:6, 2:3)
        @test a * pinv(a) ≈ [1.0 0; 0 1]
        @test keys.(axes(a * pinv(a))) == (2:3, 2:3)
    end

    @testset "Vector" begin
        v = AxisIndicesArray([1.0, 2, 3], (2:4,))
        @test keys.(axes(pinv(v))) == (1:1, 2:4)

        @test keys.(axes(pinv(pinv(v)))) == (2:4,)
        @test pinv(pinv(v)) ≈ v
    end
end

