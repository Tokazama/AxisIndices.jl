@testset "Linear Algebra" begin
    @testset "lu" begin
        m = AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))
        x = lu(m)

        @test keys.(axes(x.L)) == (2:3, 1:2)
        @test keys.(axes(x.U)) == (1:2, 3:4)
        @test keys.(axes(x.p)) == (2:3,)
        @test keys.(axes(x.P)) == (2:3, 2:3)

        @test keys.(axes(x.P * m)) == (2:3, 3:4)
        @test keys.(axes(x.L * x.U)) == (2:3, 3:4)
        @test keys.(axes(m[x.p, :])) == (keys(axes(m, 1))[x.p], 3:4)
    end

    @testset "lq" begin
        m = AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))
        x = lq(m)
        @test keys.(axes(x.L)) == (2:3,1:2)
        @test keys.(axes(x.Q)) == (1:2, 3:4)
        @test keys.(axes(x.L * x.Q)) == (2:3, 3:4)
    end

    @testset "svd" begin
        m = AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))
        x = svd(m)
        @test size(x) == (2, 2)
        @test size(x) == (2, 2)
        @test size(x, 1) == 2
        @test keys.(axes(x.U)) == (2:3, 1:2)
        @test keys.(axes(x.S)) == (1:2,)

        @test keys.(axes(x.V)) == (3:4, 1:2)
        @test keys.(axes(x.Vt)) == (1:2, 3:4)

        @test keys.(axes(x.U * Diagonal(x.S) * x.Vt)) == (2:3, 3:4)
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
end

