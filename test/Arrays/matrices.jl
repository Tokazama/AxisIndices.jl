
@testset "matrices" begin

@testset "matmul" begin
   @testset "Matrix-Matrix" begin
        a = AxisArray(ones(2, 3), (3:4, 1:3));
        b = AxisArray(ones(3, 2), (2:4, 2:3));

        @testset "standard case" begin
            @test a * b == 3ones(2, 2)
            @test keys.(axes(a * b)) == (3:4, 2:3)

            # TODO errors
            @test ones(4, 3) * b == 3ones(4, 2)
            @test keys.(axes(ones(4, 3) * b)) == (1:4, 2:3)

            @test a * ones(3, 7) == 3ones(2, 7)
            @test keys.(axes(a * ones(3,7))) == (3:4, 1:7)
        end
    end

    m = AxisArray(ones(1, 1), (Axis(2:2), Axis(3:3),));
    v = AxisArray(ones(1), (Axis(4:4),));

    @testset "Matrix-Vector" begin
        @test m * v == ones(1)
        @test keys.(axes(m * v)) == (2:2,)
    end

    @testset "Vector-Matrix" begin
        @test v * m == ones(1, 1)
        @test keys.(axes(v * m)) == (4:4, 3:3)
    end

    @testset "Vector-Vector" begin
        v = [1, 2, 3]
        av = AxisArray(v, (Axis(2:4),))
        @test_throws MethodError av * av
        @test av' * av == 14
        @test av' * av == adjoint(av) * v == transpose(av) * v
        @test av' * av == adjoint(v) * av == transpose(v) * av
        @test av * av' == [1 2 3; 2 4 6; 3 6 9]
    end

    @testset "Transpose/Adjoint" begin
        A = ones(3, 3)
        @test A * AxisArray(ones(3)) == A * ones(3)
        @test A' * AxisArray(ones(3)) == A' * ones(3)
        @test A' * AxisArray(ones(3)) == A' * ones(3)
        @test A' * AxisArray(ones(3,3)) == A' * ones(3, 3)
        @test ones(3)' * A == AxisArray(ones(3))' * A
        @test ones(1, 3) * A == AxisArray(ones(1, 3)) * A

        @test transpose(A) * AxisArray(ones(3)) == transpose(A) * ones(3)
        @test transpose(A) * AxisArray(ones(3)) == transpose(A) * ones(3)
        @test transpose(A) * AxisArray(ones(3,3)) == transpose(A) * ones(3, 3)
        @test transpose(ones(3)) * A == transpose(AxisArray(ones(3))) * A
    end

    @testset "Hermitian" begin
        A = Hermitian([1 0 2+2im 0 3-3im; 0 4 0 5 0; 6-6im 0 7 0 8+8im; 0 9 0 1 0; 2+2im 0 3-3im 0 4])
        @test A * AxisArray(ones(5)) == A * ones(5)
        @test A' * AxisArray(ones(5)) == A' * ones(5)
        @test A' * AxisArray(ones(5)) == A' * ones(5)
        @test A' * AxisArray(ones(5,5)) == A' * ones(5, 5)
        @test ones(5)' * A == AxisArray(ones(5))' * A
        @test ones(1, 5) * A == AxisArray(ones(1, 5)) * A

        @test transpose(A) * AxisArray(ones(5)) == transpose(A) * ones(5)
        @test transpose(A) * AxisArray(ones(5)) == transpose(A) * ones(5)
        @test transpose(A) * AxisArray(ones(5,5)) == transpose(A) * ones(5, 5)
        @test transpose(ones(5)) * A == transpose(AxisArray(ones(5))) * A
    end
   
    @testset "UpperTriangular" begin
        A = UpperTriangular([1.0 2.0 3.0;
                             4.0 5.0 6.0;
                             7.0 8.0 9.0])
        @test A * AxisArray(ones(3)) == A * ones(3)
        @test A' * AxisArray(ones(3)) == A' * ones(3)
        @test A' * AxisArray(ones(3)) == A' * ones(3)
        @test A' * AxisArray(ones(3,3)) == A' * ones(3, 3)
        @test ones(3)' * A == AxisArray(ones(3))' * A
        @test ones(1, 3) * A == AxisArray(ones(1, 3)) * A

        @test transpose(A) * AxisArray(ones(3)) == transpose(A) * ones(3)
        @test transpose(A) * AxisArray(ones(3)) == transpose(A) * ones(3)
        @test transpose(A) * AxisArray(ones(3,3)) == transpose(A) * ones(3, 3)
        @test transpose(ones(3)) * A == transpose(AxisArray(ones(3))) * A
    end

end

end
