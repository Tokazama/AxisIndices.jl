@testset "Linear Algebra" begin
    @testset "lu" begin
        m = AxisArray([1.0 2; 3 4], (2:3, 3:4))
        x = @inferred(lu(m))

        @test axes_keys(m[x.p, :]) == (keys(axes(m, 1))[x.p], 3:4)
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
                    @test keys.(axes(x.p)) == (2:3,)
                    @test keys.(axes(x.P)) == (2:3, 2:3)
                    @test keys.(axes(x.P * m)) == (2:3, 3:4)
                    @test keys.(axes(m[x.p, :])) == (keys(axes(m, 1))[x.p], 3:4)
                end
            end
        end
    end

    @testset "diagonal" begin
        m = AxisArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"]);
        @test @inferred(diag(m)) == diag(parent(m))
        @test @inferred(diag(m, 1)) == diag(parent(m), 1)
        @test @inferred(diag(m, 1; dim=Val(2))) == diag(parent(m), 1)
    end
end

