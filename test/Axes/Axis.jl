
@testset "AbstractAxis types" begin
    @testset "Axis" begin
        axis = Axis()

        a1 = Axis(2:3 => 1:2)
        axis = Axis(1:10)

        @test UnitRange(a1) == 1:2

        @test @inferred(Axis(a1)) isa typeof(a1)

        @test @inferred(Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:10)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}

        @test @inferred(Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}(1:10)) isa Axis{Int,Int,UnitRange{Int},UnitMRange{Int}}

        @test @inferred(Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}(1:10)) isa Axis{Int,Int,UnitMRange{Int},UnitRange{Int}}

        @test @inferred(Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}(1:10)) isa Axis{Int,Int,UnitMRange{Int},UnitMRange{Int}}

        @test @inferred(Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}(1:2)) isa Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}
        @test @inferred(Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}(UnitRange(UInt(1), UInt(2)))) isa Axis{UInt,Int,UnitRange{UInt},UnitRange{Int}}

        @test Axis{String,Int,Vector{String},Base.OneTo{Int}}(Axis(["a", "b"])) isa Axis{String,Int,Vector{String},Base.OneTo{Int}}

        @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
        @test Axis{Int,Int,UnitRange{Int},UnitRange{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},UnitRange{Int}}
        @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(Base.OneTo(2)) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}
        @test Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}(1:2) isa Axis{Int,Int,UnitRange{Int},Base.OneTo{Int}}
    end

    #= FIXME StructAxis
    @testset "StructAxis" begin
        axis = @inferred(StructAxis{NamedTuple{(:one,:two,:three),Tuple{Int64,Int32,Int16}}}())
        @test axis[1:2] == [1, 2]
        @test keys(axis[1:2]) == [:one, :two]
        #@test AxisIndices.AxisCore.to_types(axis, :one) <: Int
        #@test AxisIndices.AxisCore.to_types(axis, [:one, :two]) <: Tuple{Int,Int32}

        axis = StructAxis{NamedTuple{(:a,:b),Tuple{Int,Int}}}()
        x = AxisArray(reshape(1:4, 2, 2), axis);
        x2 = struct_view(x);
        @test x2[1] isa NamedTuple{(:a,:b),Tuple{Int,Int}}

        x = AxisArray(reshape(1:4, 2, 2), StructAxis{Rational}());
        x2 = struct_view(x);
        @test x2[1] isa Rational
        @test AxisIndices.structdim(x) == 1
    end
    =#
    #@test @inferred(AxisIndices.to_axis(a1)) == a1

    @testset "CenteredAxis" begin
        centered_axis = @inferred(CenteredAxis(1:10))
        @test @inferred(keys(centered_axis)) == -5:4
        @test @inferred(parent(centered_axis)) == 1:10
        @test typeof(centered_axis)(parent(centered_axis)) isa typeof(centered_axis)
        centered_axis = @inferred(CenteredAxis{Int32}(UnitSRange(1, 10)))
        @test typeof(centered_axis)(parent(centered_axis)) isa typeof(centered_axis)
        @test keytype(centered_axis) <: Int32
        centered_axis = @inferred(CenteredAxis{Int32}(UnitSRange(1, 10)))
        @test eltype(centered_axis) <: Int32
        ca2 = centered_axis[-1:1]
        @test @inferred(keys(ca2)) == -1:1
        @test @inferred(parent(ca2)) == 5:7
        #@test is_indices_axis(typeof(centered_axis))

        #=
        @testset "simialar_type" begin
            @test similar_type(centered_axis, OneTo{Int}) <:
                CenteredAxis{Int64,UnitRange{Int64},OneTo{Int64}}
            @test similar_type(centered_axis, OneToSRange{Int,10}) <:
                CenteredAxis{Int64,UnitSRange{Int64,-5,4},OneToSRange{Int64,10}}
            @test similar_type(centered_axis, UnitSRange{Int,1,10}) <:
                CenteredAxis{Int64,UnitSRange{Int64,-5,4},UnitSRange{Int64,1,10}}
            @test similar_type(centered_axis, UnitSRange{Int,1,10}, OneToSRange{Int,10}) <:
                CenteredAxis{Int64,UnitSRange{Int64,1,10},OneToSRange{Int64,10}}
            @test similar_type(centered_axis, UnitRange{Int}, OneToSRange{Int,10}) <:
                CenteredAxis{Int64,UnitRange{Int64},OneToSRange{Int64,10}}
            @test_throws ErrorException similar_type(centered_axis, OneToSRange{Int}, OneToSRange{Int,10})

            # codecov doesn't catch these with the previous methods like it should but we should
            # make sure they are still necessary so as no to maintain dead code.
            @test AxisIndices.OffsetAxes._centered_axis_similar_type(OneTo{Int}) <:
                CenteredAxis{Int64,UnitRange{Int64},OneTo{Int64}}
            @test AxisIndices.OffsetAxes._centered_axis_similar_type(OneToSRange{Int,10}) <:
                CenteredAxis{Int64,UnitSRange{Int64,-5,4},OneToSRange{Int64,10}}
            @test AxisIndices.OffsetAxes._centered_axis_similar_type(UnitSRange{Int,1,10}) <:
                CenteredAxis{Int64,UnitSRange{Int64,-5,4},UnitSRange{Int64,1,10}}
            @test AxisIndices.OffsetAxes._centered_axis_similar_type(UnitSRange{Int,1,10}, OneToSRange{Int,10}) <:
                CenteredAxis{Int64,UnitSRange{Int64,1,10},OneToSRange{Int64,10}}
            @test AxisIndices.OffsetAxes._centered_axis_similar_type(UnitRange{Int}, OneToSRange{Int,10}) <:
                CenteredAxis{Int64,UnitRange{Int64},OneToSRange{Int64,10}}
        end
        =#
    end

    @testset "IdentityAxis" begin
        r = IdentityAxis(0, -5)
        @test isempty(r)
        @test length(r) == 0
        @test size(r) == (0,)
        r = IdentityAxis(0, 2)
        @test !isempty(r)
        @test length(r) == 3
        @test size(r) == (3,)
        @test axes(r) == (0:2,)
        @test step(r) == 1
        @test first(r) == 0
        @test last(r) == 2
        @test minimum(r) == 0
        @test maximum(r) == 2
        @test r[0] == 0
        @test r[1] == 1
        @test r[2] == 2
        @test_throws BoundsError r[3]
        @test_throws BoundsError r[-1]
        @test r[0:2] == IdentityAxis(0:2)
        @test r[r] == r

        @test r .+ 1 != 1:3
        # TODO @test r .+ 1 == AxisArray(1:3, axes(r))
        @test r .+ 1 === 1 .+ r
        # TODO @test r .- 1 === AxisArray(-1:1, axes(r))
        # TODO @test 1 .- r === OffsetArray(1:-1:-1, axes(r))
        # TODO @test 2 * r === 2 .* r === r * 2 === r .* 2 === OffsetArray(0:2:4, axes(r))
        k = -1
        for i in r
            @test i == (k+=1)
        end
        @test k == length(r)-1
        @test collect(r) == [0,1,2]
        # TODO @test intersect(r, IdentityAxis(-1,1)) === intersect(IdentityAxis(-1,1), r) === IdentityAxis(0,1)
        @test intersect(r, -1:5) === intersect(-1:5, r) === 0:2
        @test intersect(r, 2:5) === intersect(2:5, r) === 2:2
        # TODO @test string(r) == "IdentityAxis(0:2)"

        r = IdentityAxis(2:4)
        # TODO @test r != 2:4
        @test checkindex(Bool, r, 4)
        @test !checkindex(Bool, r, 5)
        @test checkindex(Bool, r, :)
        @test checkindex(Bool, r, 2:4)
        @test !checkindex(Bool, r, 1:5)
        @test !checkindex(Bool, r, trues(4))
        @test !checkindex(Bool, r, trues(5))
        # TODO @test convert(UnitRange, r) == 2:4
        @test convert(StepRange, r) == 2:1:4
        # TODO  @test !in(1, r)
        @test in(2, r)
        # TODO @test in(4, r)
        @test !in(5, r)
        @test issorted(r)
        @test maximum(r) == 4
        @test minimum(r) == 2
        # TODO @test sortperm(r) == r
        # TODO @test r != 2:4
        @test 1:4 == IdentityAxis(1:4) == 1:4
        @test r+r == AxisArray(4:2:8, axes(r))
        # TODO this can't be done with other AbstractUnitRange types so why here?
        # @test r-r == OffsetArray([0,0,0], axes(r))
        @test (9:2:13)-r == 7:9
        @test -r == AxisArray(-2:-1:-4, axes(r))
        @test reverse(r) == AxisArray(4:-1:2, axes(r))
        @test r / 2 == r ./ 2 == AxisArray(1:0.5:2, axes(r))
        @test 2 \ r == 2 .\ r == AxisArray(1:0.5:2, axes(r))

        r = IdentityAxis{Int16}(0, 4)
        @test length(r) === 5
        @test iterate(r) == (0,0)
        k = -1
        for i in r
            @test i == (k+=1)
        end
        @test k == length(r)-1
        #=
        x, y = promote(IdentityAxis(2,4), IdentityAxis{Int16}(3,7))
        @test x === IdentityAxis(2:4)
        @test y === IdentityAxis(3:7)
        x, y = promote(IdentityAxis(4:5), 0:7)
        @test x === 4:5
        @test y === 0:7
        @test convert(IdentityAxis{Int16}, IdentityAxis(2:5)) === IdentityAxis{Int16}(2:5)
        @test convert(IdentityAxis{Int}, IdentityAxis(2:5)) === IdentityAxis(2:5)
        @test convert(UnitRange, IdentityAxis(2:4)) === 2:4
        r = IdentityAxis(Int128(1),Int128(10))
        @test length(r) === Int128(10)
        =#
    end

        #= TODO problems with `==` due to == on axes
        @testset "View axes" begin
            a = rand(8)
            idr = IdentityAxis(2:4)
            v = view(a, idr)
            @test axes(v) == (2:4,)
            @test v == OffsetArray(a[2:4], 2:4)

            a = rand(5, 5)
            idr2 = IdentityAxis(3:4)
            v = view(a, idr, idr2)
            @test axes(v) == (2:4, 3:4)
            @test v == OffsetArray(a[2:4, 3:4], 2:4, 3:4)
        end
        =#

    @testset "OffsetAxis" begin
        inds = Base.OneTo(3)
        ks = 1:3
        offset = 0
        @test @inferred(OffsetAxis(ks)) === OffsetAxis(1:3, Base.OneTo(3))
        @test @inferred(OffsetAxis(ks, inds)) === OffsetAxis(1:3, Base.OneTo(3))
        @test @inferred(OffsetAxis(offset, inds)) === OffsetAxis(1:3, Base.OneTo(3))
        @test @inferred(OffsetAxis(OffsetAxis(ks))) === OffsetAxis(1:3, Base.OneTo(3))

        @test @inferred(OffsetAxis{Int16}(ks)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
        @test @inferred(OffsetAxis{Int16}(ks, inds)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
        @test @inferred(OffsetAxis{Int16}(offset, inds)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
        @test @inferred(OffsetAxis{Int16}(OffsetAxis(ks))) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))

        @test @inferred(OffsetAxis{Int16}(ks)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
        @test @inferred(OffsetAxis{Int16}(ks, inds)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
        @test @inferred(OffsetAxis{Int16}(offset, inds)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
        @test @inferred(OffsetAxis{Int16}(OffsetAxis(ks))) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))

        @test @inferred(OffsetAxis{Int16,Int16,Base.OneTo{Int16}}(ks)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
        @test @inferred(OffsetAxis{Int16,Int16,Base.OneTo{Int16}}(ks, inds)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
        @test @inferred(OffsetAxis{Int16,Int16,Base.OneTo{Int16}}(offset, inds)) ==
            OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))

        #=
        function same_value(r1, r2)
            length(r1) == length(r2) || return false
            for (v1, v2) in zip(r1, r2)
                v1 == v2 || return false
            end
            return true
        end

        function check_indexed_by(r, rindx)
            for i in rindx
                r[i]
            end
            @test_throws BoundsError r[minimum(rindx)-1]
            @test_throws BoundsError r[maximum(rindx)+1]
            return nothing
        end

        ro = OffsetAxis(Base.OneTo(3))
        rs = OffsetAxis(-2, 3:5)
        @test typeof(ro) !== typeof(rs)
        @test same_value(ro, 1:3)
        check_indexed_by(ro, 1:3)
        @test same_value(rs, 1:3)
        check_indexed_by(rs, 1:3)
        @test @inferred(typeof(ro)(ro)) === ro
        @test @inferred(OffsetAxis{Int}(ro))   === ro
        @test @inferred(OffsetAxis{Int16}(ro)) === OffsetAxis(Base.OneTo(Int16(3)))
        @test @inferred(OffsetAxis(ro))        === ro
        @test values(ro) === ro.values
        @test values(rs) === rs.values
        # construction/coercion preserves the values, altering the axes if needed
        r2 = @inferred(typeof(rs)(ro))
        @test typeof(r2) === typeof(rs)
        @test same_value(ro, 1:3)
        check_indexed_by(ro, 1:3)
        r2 = @inferred(typeof(ro)(rs))
        @test typeof(r2) === typeof(ro)
        @test same_value(r2, 1:3)
        check_indexed_by(r2, 1:3)
        # check the example in the comments
        r = OffsetAxis{Int}(3:4)
        @test same_value(r, 3:4)
        check_indexed_by(r, 1:2)
        r = OffsetAxis{Int}(3:4)
        @test same_value(r, 3:4)
        check_indexed_by(r, 3:4)
        r = OffsetAxis{Int}(-2, 3:4)
        @test same_value(r, 1:2)
        check_indexed_by(r, 1:2)

        # conversion preserves both the values and the axes, throwing an error if this is not possible
        @test @inferred(oftype(ro, ro)) === ro
        @test @inferred(convert(OffsetAxis{Int}, ro)) === ro
        @test @inferred(convert(OffsetAxis{Int}, rs)) === rs
        @test @inferred(convert(OffsetAxis{Int16}, ro)) === OffsetAxis(Base.OneTo(Int16(3)))
        r2 = @inferred(oftype(rs, ro))
        @test typeof(r2) === typeof(rs)
        @test same_value(r2, 1:3)
        check_indexed_by(r2, 1:3)
        # These two broken tests can be fixed by uncommenting the `convert` definitions
        # in axes.jl, but unfortunately Julia may not quite be ready for this. (E.g. `reinterpretarray.jl`)
        @test_broken try oftype(ro, rs); false catch err true end  # replace with line below
        # @test_throws ArgumentError oftype(ro, rs)
        @test @inferred(oftype(ro, Base.OneTo(2))) === OffsetAxis(Base.OneTo(2))
        @test @inferred(oftype(ro, 1:2)) === OffsetAxis(Base.OneTo(2))
        @test_broken try oftype(ro, 3:4); false catch err true end

        # @test_throws ArgumentError oftype(ro, 3:4)
        #
        @testset "values -> keys" begin
            # firstindex(keys(axis)) == 3, firstindex(axis) == 2
            @test @inferred(AxisIndices.v2k(Axis(OffsetAxis(2, 1:10), OffsetAxis(1, 1:10)), 2)) == 3
            # firstindex(keys(axis)) == 3, firstindex(axis) == 1
            @test @inferred(AxisIndices.v2k(Axis(OffsetAxis(2, 1:10), 1:10), 1)) == 3
            # firstindex(keys(axis)) == 1, firstindex(axis) == 2
            @test @inferred(AxisIndices.v2k(Axis(1:10, OffsetAxis(1, 1:10)), 2)) == 1
            # firstindex(keys(axis)) == 1, firstindex(axis) == 1
            @test @inferred(AxisIndices.v2k(Axis(1:10, 1:10), 1)) == 1

            # firstindex(keys(axis)) == 3, firstindex(axis) == 2
            @test @inferred(AxisIndices.v2k(Axis(OffsetAxis(2, 1:10), OffsetAxis(1, 1:10)), 2:3)) == 3:4
            # firstindex(keys(axis)) == 3, firstindex(axis) == 1
            @test @inferred(AxisIndices.v2k(Axis(OffsetAxis(2, 1:10), 1:10), 1:2)) == 3:4
            # firstindex(keys(axis)) == 1, firstindex(axis) == 2
            @test @inferred(AxisIndices.v2k(Axis(1:10, OffsetAxis(1, 1:10)), 2:3)) == 1:2
            # firstindex(keys(axis)) == 1, firstindex(axis) == 1
            @test @inferred(AxisIndices.v2k(Axis(1:10, 1:10), 1:2)) == 1:2
        end

        @testset "keys -> values" begin
            # firstindex(keys(axis)) == 3, firstindex(axis) == 2
            @test @inferred(AxisIndices.k2v(Axis(OffsetAxis(2, 1:10), OffsetAxis(1, 1:10)), 3)) == 2
            # firstindex(keys(axis)) == 3, firstindex(axis) == 1
            @test @inferred(AxisIndices.k2v(Axis(OffsetAxis(2, 1:10), 1:10), 3)) == 1
            # firstindex(keys(axis)) == 1, firstindex(axis) == 2
            @test @inferred(AxisIndices.k2v(Axis(1:10, OffsetAxis(1, 1:10)), 1)) == 2
            # firstindex(keys(axis)) == 1, firstindex(axis) == 1
            @test @inferred(AxisIndices.k2v(Axis(1:10, 1:10), 1)) == 1

            # firstindex(keys(axis)) == 3, firstindex(axis) == 2
            @test @inferred(AxisIndices.k2v(Axis(OffsetAxis(2, 1:10), OffsetAxis(1, 1:10)), 3:4)) == 2:3
            # firstindex(keys(axis)) == 3, firstindex(axis) == 1
            @test @inferred(AxisIndices.k2v(Axis(OffsetAxis(2, 1:10), 1:10), 3:4)) == 1:2
            # firstindex(keys(axis)) == 1, firstindex(axis) == 2
            @test @inferred(AxisIndices.k2v(Axis(1:10, OffsetAxis(1, 1:10)), 1:2)) == 2:3
            # firstindex(keys(axis)) == 1, firstindex(axis) == 1
            @test @inferred(AxisIndices.k2v(Axis(1:10, 1:10), 1:2)) == 1:2
        end
        =#
    end
end

@test OffsetArray(OffsetArray(ones(2, 2))) isa OffsetArray

@testset "keys" begin
    axis = Axis(2:3 => 1:2)

    @test keytype(typeof(Axis(1.0:10.0))) <: Float64
    @test haskey(axis, 3)
    @test !haskey(axis, 4)
    @test keys.(axes(axis)) == (2:3,)

    A = AxisArray(ones(3,2), [:one, :two, :three])

    @testset "reverse" begin
        x = [1, 2, 3]
        y = AxisArray(x)
        z = AxisArray(x, Axis([:one, :two, :three]))

        revx = reverse(x)
        revy = @inferred(reverse(y))
        revz = @inferred(reverse(z))

        @testset "reverse vectors values properly" begin
            @test revx == revz == revy
        end

        @testset "reverse vectors keys" begin
            @test keys(axes(revy, 1)) == [3, 2, 1]
            @test keys(axes(revz, 1)) == [:three, :two, :one]
        end

        @testset "reverse arrays" begin
            b = [1 2; 3 4]
            x = AxisArray(b, [:one, :two], ["a", "b"])

            xrev1 = reverse(x, dims=1)
            xrev2 = reverse(x, dims=2)
            @test keys.(axes(xrev1)) == ([:two, :one], ["a", "b"])
            @test keys.(axes(xrev2)) == ([:one, :two], ["b", "a"])
        end
    end
end

