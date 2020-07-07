@testset "Base" begin
    m = [10 20; 31 40]
    am = AxisArray(m, (2:3, 3:4))

    @testset "$f" for f in (sum, prod, maximum, minimum, extrema)
        @test f(am) == f(m)
        @test f(am; dims=1) == f(m; dims=1)

        @test axes_keys(f(am; dims=1)) == (2:2, 3:4)
    end

    @testset "$f" for f in (cumsum, cumprod, sort)
        @test f(am; dims=1) == f(m; dims=1)

        @test axes_keys(f(am; dims=1)) == (2:3, 3:4) 

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

            @test axes_keys(f!(a1, am)) == (2:2, 3:4) == axes_keys(f!(a1, a))
            @test axes_keys(f!(a2, am)) == (2:3, 3:3) == axes_keys(f!(a2, a))
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

        @test axes_keys(mapslices(join, am; dims=2)) == (2:3, 3:3)
    end

    @testset "mapreduce" begin
        m = [10 20; 31 40]
        maxes = AxisArray(m, (2:3, 3:4))

        @test mapreduce(isodd, |, maxes) == true == mapreduce(isodd, |, m)
        @test mapreduce(isodd, |, maxes; dims=1) == [true false]
        @test mapreduce(isodd, |, maxes; dims=2) == [false true]'
        @test axes_keys(mapreduce(isodd, |, maxes; dims=2)) == (2:3, 3:3)
    end

    @testset "zero" begin
        m = [10 20; 31 40]
        maxes = AxisArray(m, (2:3, 3:4))

        @test zero(maxes) == [0 0; 0 0] == zero(m)
        @test axes_keys(zero(maxes)) == (2:3, 3:4)
    end

    @testset "count" begin
        m = [true false; true true]
        maxes = AxisArray(m, (2:3, 3:4))

        @test count(maxes) == count(m) == 3
        @test_throws Exception count(a; dims=1)
    end

    # TODO test warnings for immutable axes
    @testset "push!, pop!, etc" begin
        v = AxisArray([10, 20, 30], (Axis(UnitMRange(2, 4),UnitMRange(1, 3)),))

        @test length(push!(v, 40)) == 4
        @test axes_keys(pushfirst!(v, 0)) == (1:5,)
        @test v == [0, 10, 20, 30, 40]

        @test pop!(v) == 40
        @test popfirst!(v) == 0
        @test v == [10, 20, 30]
    end

    @testset "append!, empty!" begin
        v = AxisArray([10, 20, 30], (UnitMRange(2, 4),))
        v45 = AxisArray([40, 50], (UnitMRange(3, 4),))
        v0 = AxisArray([0, 0], (UnitMRange(4, 5),))

        @test length(append!(v, v45)) == 5
        v = append!(v, [60,70])
        @test axes_keys(v, 1) == 2:8

        #@test_throws DimensionMismatch append!(ndv, ndv0)
        @test v == 10:10:70 # error was thrown before altering

        @test axes_keys(empty!(v), 1) == 2:1
        @test length(v) == 0
    end

    @testset "map, map!" begin
        maxes = AxisArray([11 12; 21 22], (2:3, 3:4))

        @test keys.(axes(map(+, maxes, maxes, maxes))) == (2:3, 3:4)
        @test keys.(axes(map(+, maxes, parent(maxes), maxes))) == (2:3, 3:4)
        @test keys.(axes(map(+, parent(maxes), maxes))) == (2:3, 3:4)

        # this method only called based on first two arguments:
        #@test dimnames(map(+, parent(maxes), parent(maxes), maxes)) == (:_, :_)

        # one-arg forms work without adding anything... except on 1.0...
        @test keys.(axes(map(sqrt, maxes))) == (2:3, 3:4)
        @test foreach(sqrt, maxes) === nothing

        #= TODO is this something we actually want?
        # map! may return a different wrapper of the same data, like sum!
        semi = AxisArray(rand(2,2), (:x, :_))
        @test dimnames(map!(sqrt, rand(2,2), maxes)) == (:x, :y)
        @test dimnames(map!(sqrt, semi, maxes)) == (:x, :y)
        =#

        zed = similar(maxes, Float64)
        @test map!(sqrt, zed, maxes) == sqrt.(maxes)
        @test zed[1,1] == sqrt(maxes[1,1])
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

