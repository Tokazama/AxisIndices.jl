@testset "Linear Algebra" begin
    @testset "lu" begin
        m = AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))
        x = lu(m)

        @test keys.(axes(m[x.p, :])) == (keys(axes(m, 1))[x.p], 3:4)
    end

    @testset "eigen" begin
        m = AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))
        x = eigen(m)
        @test keys.(axes(x.vectors)) == (2:3, 3:4)
        @test eigvals(m) == eigvals(parent(m))
    end

    @testset "svd" begin
        m = AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))
        x = svd(m)
        u, s, v = x
        @test size(x) == (2, 2)
        @test size(x) == (2, 2)
        @test size(x, 1) == 2
        @test keys.(axes(x.S)) == (1:2,)
    end

    @testset "qr" begin
        for pivot in (true, false)
            for data in ([1.0 2; 3 4], [big"1.0" 2; 3 4])
                m = AxisIndicesArray(data, (2:3, 3:4))
                x = qr(m, Val(pivot));

                @test keys.(axes(x.Q)) == (2:3, 1:2)
                @test keys.(axes(x.R)) == (1:2, 3:4)
                @test keys.(axes(x.Q * x.R)) == (2:3, 3:4)

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
        m = AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))
        @test diag(m) == diag(parent(m))
    end
end

