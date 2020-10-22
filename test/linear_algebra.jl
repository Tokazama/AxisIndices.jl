
@testset "Linear Algebra" begin
    @testset "lu" begin
        m = AxisArray([1.0 2; 3 4], (2:3, 3:4))
        x = @inferred(lu(m))

        @test m[x.p, :] == parent(m)[parent(x).p,:]
        @test x.factors == lu(parent(m)).factors
    end

    # FIXME inferrence for eigen
    @testset "eigen" begin
        m = AxisArray([1.0 2; 3 4], (2:3, 3:4))
        x = eigen(m)
        @test keys.(axes(x.vectors)) == (2:3, 3:4)
        @test eigvals(m) == eigvals(parent(m))
    end

    @testset "svd" begin
        m = AxisArray([1.0 2; 3 4], (2:3, 3:4))
        x = svd(m)
        u, s, v = x
        @test size(x) == (2, 2)
        @test size(x) == (2, 2)
        @test size(x, 1) == 2
        @test keys.(axes(x.S)) == (1:2,)

        F = svd(AxisArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))));
        io = IOBuffer()
        show(io, F)
        str = String(take!(io))
        @test str[1:7] == "AxisSVD"
    end

    @testset "LQ" begin
        m = AxisArray([1.0 2; 3 4], (2:3, 3:4))
        x = @inferred(lq(m))
        @test x.factors == lq(parent(m)).factors
    end

    @testset "qr" begin
        for pivot in (true, false)
            for data in ([1.0 2; 3 4], [big"1.0" 2; 3 4])
                m = AxisArray(data, (2:3, 3:4))
                x = @inferred(qr(m, Val(pivot)));

                @test keys.(axes(x.Q)) == (2:3, 1:2)
                @test keys.(axes(x.R)) == (1:2, 3:4)
                @test keys.(axes(x.Q * x.R)) == (2:3, 3:4)
                @test x.factors == qr(parent(m), Val(pivot)).factors

                pivot && @testset "pivoted" begin
                    @test x isa QRPivoted
                    @test x.p == [3, 2]
                    @test keys.(axes(x.P)) == (2:3, 2:3)
                    @test keys.(axes(x.P * m)) == (2:3, 3:4)
                    @test m[x.p,:] == parent(m)[parent(x).p,:]
                end
            end
        end
    end

    @testset "diagonal" begin
        m = AxisArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"], nothing);
        @test @inferred(diag(m)) == diag(parent(m))
        @test @inferred(diag(m, 1)) == diag(parent(m), 1)
        @test @inferred(diag(m, 1; dim=Val(2))) == diag(parent(m), 1)
    end
end

#= TODO figure allocations
@testset "allocations: matmul names" begin
    @test 0 == @allocated (() -> matrix_prod_names((:foo, :bar), (:bar,)))()
    @test 0 == @allocated (() -> symmetric_names((:foo, :bar), 1))()
end
=#


@testset "Mutmul with special types" begin
    a = AxisArray(ones(5,5), (2:6, 3:7))
    @testset "$T" for T in (Diagonal, Symmetric, Tridiagonal, SymTridiagonal, BitArray,)
        x = T(ones(5,5))
        @test keys.(axes(x * a)) == (1:5, 3:7)
        @test keys.(axes(a * x)) == (2:6, 1:5)
    end
end

@testset "inv" begin
    a = AxisArray([1.0 2; 3 4], (2:3, 4:5));
    @test keys.(axes(inv(a))) == (4:5, 2:3)
    @test a * inv(a) ≈ [1.0 0; 0 1]
    @test keys.(axes(a * inv(a))) == (2:3, 2:3)

    @test inv(a) * a ≈ [1.0 0; 0 1]
    @test keys.(axes(inv(a) * a)) == (4:5, 4:5)
end

@testset "cov/cor" begin
    @testset "$f" for f in (cov, cor)
        @testset "matrix input, matrix result" begin
            A = rand(3, 5)
            a = AxisArray(A, (2:4, 2:6))
            @test f(a; dims=1) == f(A, dims=1)
            @test keys.(axes(f(a; dims=1))) == (2:6, 2:6)
            @test keys.(axes(f(a, dims=2))) == (2:4, 2:4)
            @test keys.(axes(f(a, dims=3))) == (2:4, 2:4)
            @test keys.(axes(f(a[:,2:4], dims=3))) == (2:4, 2:4)
        end
        @testset "vector input, scalar result" begin
            v = rand(4)
            av = AxisArray(v, (2:5,))
            @test f(av) isa Number
            @test f(av) == f(v)
        end
    end
    @testset "cov corrected=$bool" for bool in (true, false)
        # test that kwargs get passed on correctly
        A = rand(2, 4)
        a = AxisArray(A)
        @test cov(a; corrected=bool) == cov(A; corrected=bool)
        @test cov(a; corrected=bool, dims=2)  == cov(A; corrected=bool, dims=2)
    end
end
