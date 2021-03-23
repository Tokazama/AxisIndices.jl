
@testset "size" begin
    x = Axis(UnitRange(1, 3), UnitRange(1, 3))
    #@test StaticRanges.Size(typeof(x)) === StaticRanges.Size{(3,)}()

    @test size(x) == (3,)
    @test size(x, 1) == 3
end

@testset "insert!" begin
    v = AxisVector{Int}()
    push!(v, 1)
    insert!(v, 1, 1)
    insert!(v, 1, 1.0)
    @test v == [1, 1, 1]

    v = AxisVector([1,2,3])
    @test keys.(axes(@inferred(reverse(v)))) == (3:-1:1,)

    v = AxisVector([1,2,3], ["a", "b", "c"])
    @test keys.(axes(@inferred(reverse(v)))) == (["c", "b", "a"],)

    # TODO should this be a strict key array still?
    v = OffsetVector([1,2,3], 1)
    @test keys.(axes(@inferred(reverse(v)))) == (4:-1:2,)

    @test_throws MethodError insert!(AxisArray(1:2), 2, 2)
end

@testset "AxisArray constructors" begin

    A_fixed = ones(2, 2)

    # TODO properly import StaticArrays
    A_static = SMatrix{2,2}(A_fixed)

    @testset "AxisArray(::AbstractArray)" begin
        A_fixed_axes = @inferred(AxisArray(A_fixed));
        A_static_axes = @inferred(AxisArray(A_static));

        @test @inferred(all(i -> length(i) == 2, axes(A_fixed_axes)))
        @test @inferred(all(i -> known_length(i) == 2, axes(A_static_axes)))
    end

    @testset "AxisArray(::AbstractArray, ::Tuple{Keys...})" begin
        A_fixed_axes = @inferred(AxisArray(A_fixed, (["a", "b"], [:one, :two])));
        A_static_axes = @inferred(AxisArray(A_static));


        @test @inferred(all(i -> length(i) == 2, axes(A_fixed_axes)))
        @test @inferred(all(i -> known_length(i) == 2, axes(A_static_axes)))
    end

    @testset "AxisArray(::Array{T,0})" begin
        A = AxisArray(Array{Int,0}(undef, ()))
        @test A isa AxisArray{Int,0}
    end

    # FIXME
    @testset "AxisArray{T,N}(::AbstractArray...)" begin
        @test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), ["a", "b"], [:one, :two]))) <: Array{Int,2}
        # TODO why would I need these constructors?
        #@test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), (2, 2)))) <: Array{Int,2}
        #@test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), 2, 2))) <: Array{Int,2}

    end

    @testset "AxisArray(undef, ::Tuple{Keys...})" begin
        @test parent_type(@inferred(AxisArray{Int}(undef, (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int}(undef, ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int}(undef, (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int}(undef, 2, 2))) <: Array{Int,2}

        @test parent_type(@inferred(AxisArray{Int,2}(undef, (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(undef, ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(undef, (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(undef, 2, 2))) <: Array{Int,2}
    end

    #= FIXME
    @testset "AxisArray{T,N,P}" begin
        A = AxisArray(reshape(1:4, 2, 2))
        @test typeof(@inferred(convert(AxisArray{Int32,2,Array{Int32,2}}, A))) <: AxisArray{Int32,2,Array{Int32,2}}
    end
    =#

    @testset "collect(::AxisArray)" begin
        x = AxisArray(reshape(1:10, 2, 5))
        @test typeof(parent(collect(x))) <: typeof(collect(parent(x)))
        @test x isa AxisArray
    end
end

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
            @test AxisArray(ones(3)) * ones(3)' == ones(3) * ones(3)'

            @test transpose(A) * AxisArray(ones(3)) == transpose(A) * ones(3)
            @test transpose(A) * AxisArray(ones(3)) == transpose(A) * ones(3)
            @test transpose(A) * AxisArray(ones(3,3)) == transpose(A) * ones(3, 3)
            @test transpose(ones(3)) * A == transpose(AxisArray(ones(3))) * A
            @test AxisArray(ones(3)) * transpose(ones(3)) == ones(3) * transpose(ones(3))
        end

        @testset "Hermitian" begin
            A = Hermitian([1 0 2+2im 0 3-3im; 0 4 0 5 0; 6-6im 0 7 0 8+8im; 0 9 0 1 0; 2+2im 0 3-3im 0 4])
            @test A * AxisArray(ones(5)) == A * ones(5)
            @test A' * AxisArray(ones(5)) == A' * ones(5)
            @test A' * AxisArray(ones(5)) == A' * ones(5)
            @test A' * AxisArray(ones(5,5)) == A' * ones(5, 5)
            @test AxisArray(ones(5,5)) * A' == ones(5,5) * A'
            @test ones(5)' * A == AxisArray(ones(5))' * A
            @test ones(1, 5) * A == AxisArray(ones(1, 5)) * A

            @test AxisArray(ones(5,5)) * transpose(A) == ones(5,5) * transpose(A)
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

@testset "Base" begin
    m = [10 20; 31 40]
    am = AxisArray(m, (2:3, 3:4))

    @testset "$f" for f in (sum, prod, maximum, minimum, extrema)
        @test f(am) == f(m)
        @test f(am; dims=1) == f(m; dims=1)

        @test keys.(axes(f(am; dims=1))) == (2:2, 3:4)
    end

    @testset "$f" for f in (cumsum, cumprod, sort)
        @test f(am; dims=1) == f(m; dims=1)

        @test keys.(axes(f(am; dims=1))) == (2:3, 3:4) 

        @test f([1, 4, 3]) == f(AxisArray([1, 4, 3]))
    end

    #= TODO
    @testset "sort!" begin
        a = [1 9; 7 3]
        am = AxisArray(a, (2:3, 3:4))

        # Vector case
        veca = [1, 9, 7, 3]
        sort!(AxisArray(veca, :vec); order=Base.Reverse)
        @test issorted(veca; order=Base.Reverse)

        # Higher-dim case: `dims` keyword in `sort!` requires Julia v1.1+
        if VERSION > v"1.1-"
            sort!(nda, dims=:y)
            @test issorted(a[2, :])
            @test_throws UndefKeywordError sort!(nda)

            sort!(nda; dims=:x, order=Base.Reverse)
            @test issorted(a[:, 1]; order=Base.Reverse)
        end
    end
    =#

    @testset "$f!" for (f,f!) in zip((sum, prod, maximum, minimum), (sum!, prod!, maximum!, minimum!))
        a = [10 20; 31 40]
        am = AxisArray(a, (2:3, 3:4)) # size (2,2)

        a1 = sum(am, dims=1)           # size (1,2)
        a2 = sum(am, dims=2)           # size (2,1)
        @testset "ndims==2" begin
            @test f!(a1, am) == f!(a1, a) == f(a, dims=1)
            @test f!(a2, am) == f!(a2, a) == f(a, dims=2)

            @test keys.(axes(f!(a1, am))) == (2:2, 3:4) == keys.(axes(f!(a1, a)))
            @test keys.(axes(f!(a2, am))) == (2:3, 3:3) == keys.(axes(f!(a2, a)))
        end
        @testset "ndims==1 too" begin
            x = AxisArray([3, 4], (2:3,))
            y = AxisArray([5, 6], (3:4,))
            v = AxisArray([7, 8])

            @test f!(parent(x), am) == f!([0,0], a) == dropdims(f(a, dims=2), dims=2)
            @test f!(v, am) == f!(x, a)
            @test f!(y', am) == f!([0 0], am) == f(a, dims=1)
        end
    end

    # FIXME
    #=
    @testset "eachslice" begin
        if VERSION > v"1.1-"
            slices = [[111 121; 211 221], [112 122; 212 222]]
            cat_slices = cat(slices...; dims=3)
            a = AxisArray(cat_slices, (2:3, 3:4, 4:5))

            @test sum(eachslice(a; dims=3)) ==
                  sum(eachslice(cat_slices; dims=3)) ==
                  slices[1] + slices[2]
            #@test_throws ArgumentError eachslice(nda; dims=(1, 2))
            #@test_throws ArgumentError eachslice(a; dims=(1, 2))

            #@test_throws UndefKeywordError eachslice(nda)
            #@test_throws UndefKeywordError eachslice(cat_slices)

            @test axes_keys(first(eachslice(a; dims=2))) == (2:3, 4:5)
        end
    end
    =#

    @testset "mapslices" begin
        m = [10 20; 31 40]
        am = AxisArray(m, (2:3, 3:4))

        @test mapslices(join, am; dims=1) ==
              mapslices(join, m; dims=1) ==
              ["1031" "2040"]

        @test mapslices(join, am; dims=2) ==
              mapslices(join, m, dims=2) ==
              reshape(["1020", "3140"], Val(2))

        @test mapslices(join, am; dims=(1, 2)) ==
              mapslices(join, m; dims=(1, 2)) ==
              reshape(["10312040"], (1, 1))

       @test keys.(axes(mapslices(join, am; dims=2))) == (2:3, 3:3)
    end

    @testset "mapreduce" begin
        m = [10 20; 31 40]
        maxes = AxisArray(m, (2:3, 3:4))

        @test mapreduce(isodd, |, maxes) == true == mapreduce(isodd, |, m)
        @test mapreduce(isodd, |, maxes; dims=1) == [true false]
        @test mapreduce(isodd, |, maxes; dims=2) == [false true]'
        @test keys.(axes(mapreduce(isodd, |, maxes; dims=2))) == (2:3, 3:3)
    end

    @testset "zero" begin
        m = [10 20; 31 40]
        maxes = AxisArray(m, (2:3, 3:4))

        @test zero(maxes) == [0 0; 0 0] == zero(m)
        @test keys.(axes(zero(maxes))) == (2:3, 3:4)
    end

    @testset "count" begin
        m = [true false; true true]
        maxes = AxisArray(m, (2:3, 3:4))

        @test count(maxes) == count(m) == 3
        @test_throws Exception count(a; dims=1)
    end

    # TODO test warnings for immutable axes
    @testset "push!, pop!, etc" begin
        v = AxisArray([10, 20, 30], (Axis(mrange(2, 4)),))

        @test length(push!(v, 40)) == 4
        @test keys.(axes(pushfirst!(v, 0))) == (1:5,)
        @test v == [0, 10, 20, 30, 40]

        @test pop!(v) == 40
        @test popfirst!(v) == 0
        @test v == [10, 20, 30]
    end

    @testset "append!, empty!" begin
        v = AxisArray([10, 20, 30], (mrange(2, 4),))
        v45 = AxisArray([40, 50], (mrange(3, 4),))
        v0 = AxisArray([0, 0], (mrange(4, 5),))

        append!(v, v45)
        @test length(v) == 5
        append!(v, [60,70])
        @test keys(axes(v, 1)) == 2:8

        #@test_throws DimensionMismatch append!(ndv, ndv0)
        @test v == 10:10:70 # error was thrown before altering

        @test keys(axes(empty!(v), 1)) == 2:1
        @test length(v) == 0
    end

    @testset "map, map!" begin
        m = AxisArray([11 12; 21 22], (2:3, 3:4))

        @test keys.(axes(map(+, m, m, m))) == (2:3, 3:4)
        @test keys.(axes(map(+, m, parent(m), m))) == (2:3, 3:4)
        @test keys.(axes(map(+, parent(m), m))) == (2:3, 3:4)

        # this method only called based on first two arguments:
        #@test dimnames(map(+, parent(maxes), parent(maxes), maxes)) == (:_, :_)

        # one-arg forms work without adding anything... except on 1.0...
        @test keys.(axes(map(sqrt, m))) == (2:3, 3:4)
        @test foreach(sqrt, m) === nothing

        #= TODO is this something we actually want?
        # map! may return a different wrapper of the same data, like sum!
        semi = AxisArray(rand(2,2), (:x, :_))
        @test dimnames(map!(sqrt, rand(2,2), maxes)) == (:x, :y)
        @test dimnames(map!(sqrt, semi, maxes)) == (:x, :y)
        =#

        zed = similar(m, Float64)
        @test map!(sqrt, zed, m) == sqrt.(m)
        @test zed[begin,begin] == sqrt(m[begin,begin])
    end

    #= TODO
    @testset "filter" begin
        nda = AxisArray([11 12; 21 22], (:x, :y))
        ndv = AxisArray(1:7, (:z,))

        @test dimnames(filter(isodd, ndv)) == (:z,)
        @test dimnames(filter(isodd, nda)) == (:_,)
    end
    =#

    #= TODO
    @testset "collect(generator)" begin
        nda = AxisArray([11 12; 21 22], (:x, :y))
        ndv = AxisArray([10, 20, 30], (:z,))

        @test dimnames([sqrt(x) for x in nda]) == (:x, :y)

        @test dimnames([x^i for (i,x) in enumerate(ndv)]) == (:z,)
        @test dimnames([x^i for (i,x) in enumerate(nda)]) == (:x, :y)

        # Iterators.product -- has all names
        @test dimnames([x+y for x in nda, y in ndv]) == (:x, :y, :z)
        @test dimnames([x+y for x in nda, y in 1:5]) == (:x, :y, :_)
        @test dimnames([x+y for x in 1:5, y in ndv]) == (:_, :z)
        four = [x*y/z^p for p in 1:2, x in ndv, y in 1:2, z in nda]
        @test dimnames(four) == (:_, :z, :_, :x, :y)

        # Iterators.flatten -- no obvious name to use
        @test dimnames([x+y for x in nda for y in ndv]) == (:_,)

        if VERSION >= v"1.1"
            # can't see inside eachslice generators, until:
            # https://github.com/JuliaLang/julia/pull/32310
            @test dimnames([sum(c) for c in eachcol(nda)]) == (:_,)
        end
    end
    =#

    @testset "equality" begin
        a = AxisArray([10 20; 30 40])
        a2 = AxisArray([10 20; 30 40])
        a3 = AxisArray([10 20; 30 40])
        a4 = AxisArray([11 22; 33 44])
        v = AxisArray([10, 20, 30])

        @testset "$eq" for eq in (Base.:(==), isequal, isapprox)
            @test eq(a, a) == eq(parent(a), a) == eq(a, parent(a))
            @test eq(a, a2)
            @test eq(a, a3)
            @test !eq(a, a4)
        end
        @test isapprox(a, a4; atol=2π)
        @test isapprox(a, parent(a4); atol=2π)
        @test isapprox(parent(a), a4; atol=2π)
        @test AxisArray(1:2) == SimpleAxis(1:2)
    end

end  # Base


@testset "Statistics" begin
    m = [10 20; 30 40]
    maxes = AxisArray(m, (2:3, 3:4))
    @testset "$f" for f in (mean, std, var, median)
        @test f(maxes) == f(m)
        @test f(maxes; dims=1) == f(m; dims=1)

        @test keys.(axes(f(maxes; dims=1))) == (2:2, 3:4)
    end
end

@testset "Array Interface" begin
    x = AxisArray([1 2; 3 4]);
    @test parent_type(typeof(x)) == parent_type(x) == Array{Int,2}
    @test size(x) == (2, 2)
    @test parent(x) == parent(parent(x))

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

@testset "I/O" begin
    io = IOBuffer()
    x = AxisArray([1 2; 3 4])
    write(io, x)

    seek(io, 0)
    y = AxisArray(Array{Int}(undef, 2, 2))
    read!(io, y)

    @test y == x
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

#= FIXME
@testset "push!" begin
    x = AxisArray([1], [:a])
    push!(x, :b => 2)
    @test keys(axes(x, 1)) == [:a, :b]
    @test x == [1, 2]
    pushfirst!(x, :pre_a => 0)
    @test keys(axes(x, 1)) == [:pre_a, :a, :b]
    @test x == [0, 1, 2]
end
=#

#= FIXME cat tests
@testset "cat_axis" begin
    @test @inferred(cat_axis(Axis(mrange(1, 10)), SimpleAxis(mrange(1, 10)), OneTo(20))) == 1:20
    @test @inferred(cat_axis(SimpleAxis(mrange(1, 10)), SimpleAxis(mrange(1, 10)), OneTo(20))) == 1:20
    @test @inferred(cat_axis(SimpleAxis(mrange(1, 10)), Base.OneTo(10), OneTo(20))) == 1:20
    @test @inferred(cat_axis(SimpleAxis(Base.OneTo(10)), mrange(1, 10), OneTo(20))) == 1:20
    @test @inferred(cat_axis(Axis(Base.OneTo(10)), mrange(1, 10), OneTo(20))) == 1:20
end

@testset "cat axes" begin
    @test @inferred(cat_axis(SimpleAxis(1:2), 2:4, 1:5)) === SimpleAxis(1:5)
    a, b = [1; 2; 3; 4; 5], [6 7; 8 9; 10 11; 12 13; 14 15];
    c, d = CartesianAxes((Axis(1:5),)), CartesianAxes((Axis(1:5), Axis(1:2)));
    #hcat_axes((Axis(1:4), Axis(1:2)), (Axis(1:4), Axis(1:2)))
    @test length.(@inferred(hcat_axes(c, d))) == length.(hcat_axes(a, b))
    @test length.(@inferred(hcat_axes(d, c))) == length.(hcat_axes(a, b))
    @test length.(@inferred(hcat_axes(CartesianAxes((10,)), CartesianAxes((10,))))) == (10, 2)
end

@testset "hcat" begin
    a = AxisArray([1; 2; 3; 4; 5], (["a", "b", "c", "d", "e"],));
    b = [6 7; 8 9; 10 11; 12 13; 14 15];
    #@test keys.(@inferred(hcat_axes(a, b))) == (["a", "b", "c", "d", "e"], DynamicAxis(3))

    @test keys.(axes(@inferred(hcat(a, b)))) == (["a", "b", "c", "d", "e"], DynamicAxis(3))
    @test keys.(axes(@inferred(hcat(b, a)))) == (["a", "b", "c", "d", "e"], DynamicAxis(3))

    @test keys.(axes(@inferred(hcat(a, a)))) == (["a", "b", "c", "d", "e"], 1:2)
    @test @inferred(hcat(a)) isa AbstractMatrix
    @test @inferred(hcat(hcat(a))) isa AbstractMatrix
end

@testset "vcat" begin
    a = AxisArray([1 2 3 4 5], (1:1, ["a", "b", "c", "d", "e"],));
    b = [6 7 8 9 10; 11 12 13 14 15];

    @test keys.(axes(vcat(a, b))) == keys.(axes(vcat(b, a)))
    @test keys.(axes(vcat(a, a))) == (1:2, ["a", "b", "c", "d", "e"])
    @test vcat(a) == a
end

@testset "cat" begin
    a = AxisArray(reshape(1:12, (3, 4)), (["a", "b", "c"], 2:5))
    b = parent(a)
    @test keys.(axes(cat(a, a, dims=3))) == (["a", "b", "c"], 2:5, Base.OneTo(2))
    @test keys.(axes(cat(b, a, dims=3))) == (["a", "b", "c"], 2:5, Base.OneTo(2))
    @test keys.(axes(cat(a, b, dims=3))) == (["a", "b", "c"], 2:5, Base.OneTo(2))

    @test keys.(axes(cat(a, a, a, dims=3))) == (["a", "b", "c"], 2:5, Base.OneTo(3))
    @test keys.(axes(cat(a, a, b, dims=3))) == (["a", "b", "c"], 2:5, Base.OneTo(3))
    @test keys.(axes(cat(a, b, a, dims=3))) == (["a", "b", "c"], 2:5, Base.OneTo(3))
    @test keys.(axes(cat(b, a, a, dims=3))) == (["a", "b", "c"], 2:5, Base.OneTo(3))

    # TODO this involves combining strings
    # @test keys(cat(a, a, dims=(1, 2))) == (['a','b','c', 'a','b','c'], [2,3,4,5, 2,3,4,5])
end
=#

@testset "dropdims" begin
    axs = (Axis(["a", "b"]), Axis([:a]), Axis([1.0]), Axis(1:2))
    @test map(keys, AxisIndices.drop_axes(axs, 2)) == (["a", "b"], [1.0], 1:2)
    @test map(keys, AxisIndices.drop_axes(axs, (2, 3))) == (["a", "b"], 1:2)

    a = AxisArray(ones(10, 1, 1, 20), (2:11, [:a], 4:4, 5:24));

    @test dropdims(a; dims=2) == ones(10, 1, 20)
    @test keys.(axes(dropdims(a; dims=2))) == (2:11, 4:4, 5:24)

    @test dropdims(a; dims=(2, 3)) == ones(10, 20)
    @test keys.(axes(dropdims(a; dims=(2, 3)))) == (2:11, 5:24)
end

@testset "promote_shape" begin
    @test promote_shape(CartesianAxes((3, 4)), CartesianAxes((3,4,1,1,1))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianAxes((3,4,1,1,1)), CartesianAxes((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianIndices((3,4,1,1,1)), CartesianAxes((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))

    @test promote_shape(CartesianAxes((3,4,1,1,1)), CartesianIndices((3, 4))) ==
            (Base.OneTo(3), Base.OneTo(4), Base.OneTo(1), Base.OneTo(1), Base.OneTo(1))
end

@testset "+" begin
    a = AxisArray(ones(3), (2:4,))

    @testset "standard case" begin
        @test +(a) == ones(3)
        @test keys(axes(+(a), 1)) == 2:4

        @test +(a, a) == 2ones(3)
        @test keys(axes(+(a, a), 1)) == 2:4

        @test +(a, a, a) == 3ones(3)
        @test keys(axes(+(a, a, a), 1)) == 2:4
    end

    #= TODO decide what to do with axes that don't match
    @testset "Dimension disagreement" begin
        @test_throws DimensionMismatch +(
            NamedDimsArray{(:a, :b, :c, :d)}(zeros(3, 3, 3, 3)),
            NamedDimsArray{(:w, :x, :y, :z)}(ones(3, 3, 3, 3))
        )

        @test_throws DimensionMismatch +(
            NamedDimsArray{(:time,)}(zeros(3,)),
            NamedDimsArray{(:time, :value)}(ones(3, 3))
        )
    end
    =#

    @testset "Mixed array types" begin
        axs = (2:4, 3:5, 4:6, 5:7)
        lhs_sum = +(AxisArray(zeros(3, 3, 3, 3), axs), ones(3, 3, 3, 3));
        @test lhs_sum == ones(3, 3, 3, 3)
        @test keys.(axes(lhs_sum)) == axs

        rhs_sum = +(zeros(3, 3, 3, 3), AxisArray(ones(3, 3, 3, 3), axs))
        @test rhs_sum == ones(3, 3, 3, 3)
        @test keys.(axes(rhs_sum)) == axs

        #= TODO
        casts = (AxisArray{(:foo, :bar)}, identity)
        for (T1, T2, T3, T4) in Iterators.product(casts, casts, casts, casts)
            all(isequal(identity), (T1, T2, T3, T4)) && continue
            total = T1(ones(3, 6)) + T2(2ones(3, 6)) + T3(3ones(3, 6)) + T4(4ones(3, 6))
            @test total == 10ones(3, 6)
            @test dimnames(total) == (:foo, :bar)
        end
        =#
    end
end


@testset "-" begin
    # This is actually covered by the tests for + above, since that uses the same code
    # just one extra as a sensability check
    a = AxisArray(ones(3, 100), (2:4, 3:102))
    @test a - a == zeros(3, 100)
    @test keys.(axes(a - a)) == (2:4, 3:102)
end


@testset "scalar product" begin
    ax = (Axis(1:10), Axis(2:21), Axis(3:32), Axis(4:43), Axis(5:54))
    a = AxisArray(ones(10, 20, 30, 40, 50), ax);
    @test 10a == 10ones(10, 20, 30, 40, 50)
    @test keys.(axes(10a)) == keys.(ax)
end

@testset "reshape" begin
    V = AxisArray(Vector(1:8), [:a, :b, :c, :d, :e, :f, :g, :h]);

    A = @inferred(reshape(V, 4, 2));
    @test axes(A) == (Axis([:a, :b, :c, :d] => Base.OneTo(4)), SimpleAxis(Base.OneTo(2)))

    @test axes(@inferred(reshape(A, 2, :))) == (Axis([:a, :b] => Base.OneTo(2)), SimpleAxis(Base.OneTo(4)))
end

#= TODO

dims = 2
a = AxisArray(ones(10, 1, 1, 20), (2:11, 3:3, 4:4, 5:24))

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

@testset "selectdim" begin
    a = AxisArray(reshape(1:6, (2, 3)), (2:3, 2:4));
    p = parent(a)

    @test selectdim(a, 1, 2) == a[2, :]
    @test keys.(axes(selectdim(a, 1, 2))) == (2:4,)

    @test vec(selectdim(a, 1, 2:2)) == a[2, :]
    @test keys.(axes(selectdim(a, 1, 2:2))) == (2:2, 2:4)
end

for f in (adjoint, transpose)
    @testset "$f" begin
        @testset "Vector $f" begin
            v = AxisArray([10, 20, 30], (2:4,))
            @test f(v) == [10 20 30]
            @test keys.(axes(f(v))) == (1:1, 2:4)

            # Make sure vector double adjoint gets you back to the start.
            @test f(f(v)) == [10, 20, 30]
            @test keys.(axes(f(f(v)))) == (2:4,)
        end

        @testset "Matrix $f" begin
            m = AxisArray([10 20 30; 11 22 33], (2:3, 2:4))
            @test f(m) == [10 11; 20 22; 30 33]
            @test keys.(axes(f(m))) == (2:4, 2:3)

            # Make sure implementation of matrix double adjoint is correct
            # since it is easy for the implementation of vector double adjoint broke it
            @test f(f(m)) == [10 20 30; 11 22 33]
            @test keys.(axes(f(f(m)))) == (2:3, 2:4)
        end
    end
end

# We test pinv here as it is defined in src/function_dims.jl
# using the same logic as permutedims, transpose etc
@testset "pinv" begin
    @testset "Matrix" begin
        a = AxisArray([1.0 2 3; 4 5 6], (2:3, 4:6))
        @test keys.(axes(pinv(a))) == (4:6, 2:3)
        @test a * pinv(a) ≈ [1.0 0; 0 1]
        @test keys.(axes(a * pinv(a))) == (2:3, 2:3)
    end

    @testset "Vector" begin
        v = AxisArray([1.0, 2, 3], (2:4,))
        @test keys.(axes(pinv(v))) == (1:1, 2:4)

        @test keys.(axes(pinv(pinv(v)))) == (2:4,)
        @test pinv(pinv(v)) ≈ v
    end
end

#= FIXME
@testset "ReinterpretAxisArray" begin
    x = [1.0 2 3; 4 5 6]
    rx = reinterpret(Float32, x)
    ax = AxisArray(x, (2:3, 4:6))
    rax = reinterpret(Float32, ax)
    @test axes(rax) == (2:5, 4:6)
    @test rax == rx
end
=#
