
@testset "OffsetAxis" begin
    inds = Base.OneTo(3)
    ks = 1:3
    offset = 0
    @test @inferred(OffsetAxis(ks)) === OffsetAxis(1:3, Base.OneTo(3))
    @test @inferred(OffsetAxis(ks, inds)) === OffsetAxis(1:3, Base.OneTo(3))
    @test @inferred(OffsetAxis(offset, inds)) === OffsetAxis(1:3, Base.OneTo(3))
    @test @inferred(OffsetAxis(OffsetAxis(ks))) === OffsetAxis(1:3, Base.OneTo(3))

    @test @inferred(OffsetAxis{Int16}(ks)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
    @test @inferred(OffsetAxis{Int16}(ks, inds)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
    @test @inferred(OffsetAxis{Int16}(offset, inds)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
    @test @inferred(OffsetAxis{Int16}(OffsetAxis(ks))) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))

    @test @inferred(OffsetAxis{Int16}(ks)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16}(ks, inds)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16}(offset, inds)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16}(OffsetAxis(ks))) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))

    @test @inferred(OffsetAxis{Int16,UnitRange{Int16},Base.OneTo{Int16}}(ks)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16,UnitRange{Int16},Base.OneTo{Int16}}(ks, inds)) ===
        OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16,UnitRange{Int16},Base.OneTo{Int16}}(offset, inds)) ===
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
