
# differences from OffsetArrays
# * indexing preserves the offset so things like:
#!!! note this is different than what OffsetArryas does because offset arrays produced 0:1
# which doesn't make sense given the axis doesn't have a length of 2
#    @test S[0] == 3
#    @test axes(S) == (0:0,)


#=@testset "offset" begin
    @test @inferred(offset(OneTo(10))) == 0
    @test @inferred(offset(2:3)) == -1
end=#

getoffset(axis::AbstractAxis) = first_key(axis) - first(indices(axis))

@testset "OffsetAxis" begin
    inds = Base.OneTo(3)
    ks = 1:3
    offset = 0
    @test @inferred(OffsetAxis(ks)) === OffsetAxis(1:3, Base.OneTo(3))
    @test @inferred(OffsetAxis(ks, inds)) === OffsetAxis(1:3, Base.OneTo(3))
    @test @inferred(OffsetAxis(offset, inds)) === OffsetAxis(1:3, Base.OneTo(3))
    @test @inferred(OffsetAxis(OffsetAxis(ks))) === OffsetAxis(1:3, Base.OneTo(3))

    @test @inferred(OffsetAxis{Int16}(ks)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
    @test @inferred(OffsetAxis{Int16}(ks, inds)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
    @test @inferred(OffsetAxis{Int16}(offset, inds)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))
    @test @inferred(OffsetAxis{Int16}(OffsetAxis(ks))) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(3))

    @test @inferred(OffsetAxis{Int16,Int16}(ks)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16,Int16}(ks, inds)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16,Int16}(offset, inds)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16,Int16}(OffsetAxis(ks))) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))

    @test @inferred(OffsetAxis{Int16,Int16,UnitRange{Int16},Base.OneTo{Int16}}(ks)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16,Int16,UnitRange{Int16},Base.OneTo{Int16}}(ks, inds)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis{Int16,Int16,UnitRange{Int16},Base.OneTo{Int16}}(offset, inds)) === OffsetAxis(Int16(1):Int16(3), Base.OneTo(Int16(3)))

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

@testset "Single-entry arrays in dims 0:5" begin
    for n = 0:5
        for z in (OffsetArray(ones(Int, ntuple(d->1,n)), ntuple(x->x-1,n)),
                  fill!(OffsetArray{Float64}(undef, ntuple(x->x:x, n)), 1),
                  fill!(OffsetArray{Float64}(undef, ntuple(x->x:x, n)...), 1),
                  fill!(OffsetArray{Float64,n}(undef, ntuple(x->x:x, n)), 1),
                  fill!(OffsetArray{Float64,n}(undef, ntuple(x->x:x, n)...), 1))
            @testset "n = $n" begin
                @test length(LinearIndices(z)) == 1
                @test axes(z) == ntuple(x->x:x, n)
                @test z[1] == 1
            end
        end
    end
    a0 = reshape([3])
    a = OffsetArray(a0)
    @test axes(a) == ()
    @test ndims(a) == 0
    @test a[] == 3
end

@testset "OffsetVector constructors" begin
    local v = rand(5)
    @test OffsetVector(v, -2) == OffsetArray(v, -2)
    @test OffsetVector(v, -2:2) == OffsetArray(v, -2:2)
    @test typeof(OffsetVector{Float64}(undef, -2:2)) == typeof(OffsetArray{Float64}(undef, -2:2))
end

@testset "undef, missing, and nothing constructors" begin
    y = OffsetArray{Float32}(undef, (IdentityUnitRange(-1:1),))
    @test axes(y) == (IdentityUnitRange(-1:1),)
    @test eltype(y) === Float32

    y = OffsetArray{Float64}(undef, -1:1, -7:7, -128:512, -5:5, -1:1, -3:3, -2:2, -1:1)
    @test axes(y) == (-1:1, -7:7, -128:512, -5:5, -1:1, -3:3, -2:2, -1:1)
    @test eltype(y) === Float64

    for (T, t) in ((Missing, missing), (Nothing, nothing))
        @test !isassigned(OffsetArray{Union{T,Vector{Int}}}(undef, -1:1, -1:1), -1, -1)
        @test OffsetArray{Union{T,Vector{Int}}}(t, -1:1, -1:1)[-1, -1] === t
        @test !isassigned(OffsetVector{Union{T,Vector{Int}}}(undef, -1:1), -1)
        # FIXME
        #@test OffsetVector{Union{T,Vector{Int}}}(t, -1:1)[-1] === t
    end
end

@testset "Offset range construction" begin
    r = -2:5
    y = OffsetArray(r, r)
    @test axes(y) == (r,)
    y = OffsetArray(r, (r,))
    @test axes(y) == (r,)
end

@testset "OffsetArray of OffsetArray construction" begin
    # guarantee no unnecessary nesting of `OffsetArray`s
    r = -2:5
    d = collect(r)
    y = OffsetArray(d, r)
    @test axes(y, 1) == -2:5

    # range constructor
    y0 = OffsetArray(y, 0:7)
    @test axes(y0, 1) == 0:7
    @test y0[0] == r[1]
    @test typeof(parent(y0)) <: Array

    # FIXME
    #= offset constructor
    y1 = OffsetArray(y, +2)
    @test y1[0] == r[1]
    @test typeof(parent(y1)) <: Array
    =#
end

@testset "Traits" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))                   # IndexLinear
    S = OffsetArray(view(A0, 1:2, 1:2), (-1,2))   # IndexCartesian
    @test axes(A) == axes(S) == (0:1, 3:4)
    @test size(A) == size(A0)
    @test size(A, 1) == size(A0, 1)
    @test length(A) == length(A0)
    @test A == OffsetArray(A0, 0:1, 3:4)
    @test_throws DimensionMismatch OffsetArray(A0, 0:2, 3:4)
    @test_throws DimensionMismatch OffsetArray(A0, 0:1, 2:4)
end

@testset "Scalar indexing" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))
    S = OffsetArray(view(A0, 1:2, 1:2), (-1,2))

    @test @inferred(A[0,3]) ==
          @inferred(A[0,3,1]) ==
          @inferred(A[1]) ==
          @inferred(S[0,3]) ==
          @inferred(S[0,3,1]) ==
          @inferred(S[1]) == 1
    @test A[1,3] == A[1,3,1] == A[2] == S[1,3] == S[1,3,1] == S[2] == 2
    @test A[0,4] == A[0,4,1] == A[3] == S[0,4] == S[0,4,1] == S[3] == 3
    @test A[1,4] == A[1,4,1] == A[4] == S[1,4] == S[1,4,1] == S[4] == 4
    @test @inbounds(A[0,3]) == @inbounds(A[0,3,1]) == @inbounds(A[1]) == @inbounds(S[0,3]) == @inbounds(S[0,3,1]) == @inbounds(S[1]) == 1
    @test @inbounds(A[1,3]) == @inbounds(A[1,3,1]) == @inbounds(A[2]) == @inbounds(S[1,3]) == @inbounds(S[1,3,1]) == @inbounds(S[2]) == 2
    @test @inbounds(A[0,4]) == @inbounds(A[0,4,1]) == @inbounds(A[3]) == @inbounds(S[0,4]) == @inbounds(S[0,4,1]) == @inbounds(S[3]) == 3
    @test @inbounds(A[1,4]) == @inbounds(A[1,4,1]) == @inbounds(A[4]) == @inbounds(S[1,4]) == @inbounds(S[1,4,1]) == @inbounds(S[4]) == 4
    @test_throws BoundsError A[1,1]
    @test_throws BoundsError S[1,1]
    @test_throws BoundsError A[0,3,2]
    @test_throws BoundsError A[0,3,0]
    Ac = copy(A)
    Ac[0,3] = 10
    @test Ac[0,3] == 10
    Ac[0,3,1] = 11
    @test Ac[0,3] == 11
    @inbounds Ac[0,3,1] = 12
    @test Ac[0,3] == 12

    y = OffsetArray{Float64}(undef, -1:1, -7:7, -128:512, -5:5, -1:1, -3:3, -2:2, -1:1)
    y[-1,-7,-128,-5,-1,-3,-2,-1] = 14
    y[-1,-7,-128,-5,-1,-3,-2,-1] += 5
    @test y[-1,-7,-128,-5,-1,-3,-2,-1] == 19
end

@testset "Vector indexing" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))
    S = OffsetArray(view(A0, 1:2, 1:2), (-1,2))

    @test A[:, 3] == S[:, 3] == OffsetArray([1,2], (getoffset(axes(A, 1)),))
    @test A[:, 4] == S[:, 4] == OffsetArray([3,4], (getoffset(axes(A, 1)),))
    @test_throws BoundsError A[:, 1]
    @test_throws BoundsError S[:, 1]
    @test A[0, :] == S[0, :] == OffsetArray([1,3], (getoffset(axes(A, 2)),))
    @test A[1, :] == S[1, :] == OffsetArray([2,4], (getoffset(axes(A, 2)),))
    @test_throws BoundsError A[2, :]
    @test_throws BoundsError S[2, :]
    @test A[0:1, 3] == S[0:1, 3] == [1,2]
    @test A[[1,0], 3] == S[[1,0], 3] == [2,1]
    @test A[0, 3:4] == S[0, 3:4] == [1,3]
    @test A[1, [4,3]] == S[1, [4,3]] == [4,2]
    @test A[:, :] == S[:, :] == A
end

@testset "CartesianIndexing" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))
    S = OffsetArray(view(A0, 1:2, 1:2), (-1,2))

    @test A[CartesianIndex((0,3))] == S[CartesianIndex((0,3))] == 1
    @test A[CartesianIndex((0,3)),1] == S[CartesianIndex((0,3)),1] == 1
    @test @inbounds(A[CartesianIndex((0,3))]) == @inbounds(S[CartesianIndex((0,3))]) == 1
    @test @inbounds(A[CartesianIndex((0,3)),1]) == @inbounds(S[CartesianIndex((0,3)),1]) == 1
    @test_throws BoundsError A[CartesianIndex(1,1)]
    @test_throws BoundsError A[CartesianIndex(1,1),0]
    @test_throws BoundsError A[CartesianIndex(1,1),2]
    @test_throws BoundsError S[CartesianIndex(1,1)]
    @test_throws BoundsError S[CartesianIndex(1,1),0]
    @test_throws BoundsError S[CartesianIndex(1,1),2]
    @test eachindex(A) == 1:4
    #@test eachindex(axes(A, 1)) == 1:4
    #@test collect(axes(A, 1)) == 1:4
    @test eachindex(S) == CartesianIndices(OffsetAxis.((0:1,3:4)))
end

@testset "logical indexing" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1, 2))

    @test A[A .> 2] == [3,4]
end

@testset "view" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))

    S = view(A, :, 3)
    @test S == OffsetArray([1,2], (getoffset(axes(A, 1)),))
    @test S[0] == 1
    @test S[1] == 2
    @test_throws BoundsError S[2]
    @test axes(S) == (IdentityUnitRange(0:1),)
    S = view(A, 0, :)
    @test S == OffsetArray([1,3], (getoffset(axes(A, 2)),))
    @test S[3] == 1
    @test S[4] == 3
    @test_throws BoundsError S[1]
    @test axes(S) == (IdentityUnitRange(3:4),)

    # NOTE: These differs from OffsetArrays in that offset axes are preserved
    @testset "preserve offset axes" begin
        S = view(A, 0:0, 4)
        @test S == [3]
        @test S[0] == 3
        @test_throws BoundsError S[1]
        @test axes(S) === (OffsetAxis(0:0, Base.OneTo(1)),)
        S = view(A, 1, 3:4)
        @test S == [2,4]
        @test S[3] == 2
        @test S[4] == 4
        @test_throws BoundsError S[1]
        @test axes(S) === (OffsetAxis(3:4, Base.OneTo(2)),)

    end

    S = view(A, :, :)
    @test S == A
    @test S[0,3] == S[1] == 1
    @test S[1,3] == S[2] == 2
    @test S[0,4] == S[3] == 3
    @test S[1,4] == S[4] == 4
    @test_throws BoundsError S[1,1]
    @test axes(S) === (OffsetAxis(0:1, Base.OneTo(2)), OffsetAxis(3:4, Base.OneTo(2)))  # OffsetArrays uses == IdentityUnitRange.((0:1, 3:4))
    S = view(A, axes(A)...)
    @test S == A
    @test S[0,3] == S[1] == 1
    @test S[1,3] == S[2] == 2
    @test S[0,4] == S[3] == 3
    @test S[1,4] == S[4] == 4
    @test_throws BoundsError S[1,1]
    @test axes(S) === (OffsetAxis(0:1, Base.OneTo(2)), OffsetAxis(3:4, Base.OneTo(2)))
    # issue 100
    S = view(A, axes(A, 1), 3)
    @test S == A[:, 3]
    @test S[0] == 1
    @test S[1] == 2
    @test_throws BoundsError S[length(S)]
    @test axes(S) === (OffsetAxis(0:1, Base.OneTo(2)),)
    # issue 100
    S = view(A, 1, axes(A, 2))
    @test S == A[1, :]
    @test S[3] == 2
    @test S[4] == 4
    @test_throws BoundsError S[1]
    @test axes(S) === (OffsetAxis(3:4, Base.OneTo(2)),)

    # this bit also differs from OffsetArrays
    A0 = collect(reshape(1:24, 2, 3, 4))
    A = OffsetArray(A0, (-1,2,1))
    S = view(A, axes(A, 1), 3:4, axes(A, 3))
    @test S == A[:, 3:4, :]
    @test S[0, 3, 2] == A[0, 3, 2]
    @test S[0, 4, 2] == A[0, 4, 2]
    @test S[1, 3, 2] == A[1, 3, 2]
    @test axes(S) === (OffsetAxis(0:1, Base.OneTo(2)), OffsetAxis(3:4, Base.OneTo(2)), OffsetAxis(2:5, Base.OneTo(4)))
end

@testset "iteration" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))

    let a
        for (a,d) in zip(A, A0)
            @test a == d
        end
    end
end

@testset "readdlm/writedlm" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))

    io = IOBuffer()
    writedlm(io, A)
    seek(io, 0)
    @test readdlm(io, eltype(A)) == parent(A)
end

@testset "map" begin
    am = OffsetArray{Int}(undef, (1:1, 7:9))  # for testing linear indexing
    fill!(am, -1)
    copyto!(am, 1:2)

    dest = similar(am)
    map!(+, dest, am, am)
    @test dest[1,7] == 2
    @test dest[1,8] == 4
    @test dest[1,9] == -2
end


@testset "@inbounds" begin
    a = OffsetArray(zeros(7), -3:3)
    unsafe_fill!(x) = @inbounds(for i in axes(x,1); x[i] = i; end)
    function unsafe_sum(x)
        s = zero(eltype(x))
        @inbounds for i in axes(x,1)
            s += x[i]
        end
        s
    end
    unsafe_fill!(a)
    for i = -3:3
        @test a[i] == i
    end
    @test unsafe_sum(a) == 0
end

@testset "broadcasting" begin
    A = OffsetArray(rand(4,4), (-3,5))

    @test A.+1 == OffsetArray(parent(A).+1, map(getoffset, axes(A)))
    @test 2*A == OffsetArray(2*parent(A), map(getoffset, axes(A)))
    @test A+A == OffsetArray(parent(A)+parent(A), map(getoffset, axes(A)))
    @test A.*A == OffsetArray(parent(A).*parent(A), map(getoffset, axes(A)))
end

@testset "rot/reverse" begin
    A = OffsetArray(rand(4,4), (-3,5))

    @test rotl90(A) == OffsetArray(rotl90(parent(A)), reverse(map(getoffset, axes(A))))
    @test rotr90(A) == OffsetArray(rotr90(parent(A)), (getoffset(axes(A, 2)), getoffset(axes(A, 1))))
    @test reverse(A, dims = 1) == OffsetArray(reverse(parent(A), dims = 1), map(getoffset, axes(A)))
    @test reverse(A, dims = 2) == OffsetArray(reverse(parent(A), dims = 2), map(getoffset, axes(A)))
end

@testset "no nesting" begin
    A = randn(2, 3)
    x = A[2, 2]
    O1 = OffsetArray(A, -1:0, -1:1)
    O2 = OffsetArray(O1, 0:1, 0:2)
    @test parent(O1) ≡ parent(O2)
    @test eltype(O1) ≡ eltype(O2)
    O2[1, 1] = x + 1            # just a sanity check
    @test A[2, 2] == x + 1
end

@testset "mutating functions for OffsetVector" begin
    # push!
    o = OffsetVector(Int[], -1)
    @test push!(o) === o
    @test axes(o, 1) == 0:-1
    @test push!(o, 1) === o
    @test axes(o, 1) == 0:0
    @test o[end] == 1
    @test push!(o, 2, 3) === o
    @test axes(o, 1) == 0:2
    @test o[end-1:end] == [2, 3]
    # pop!
    o = OffsetVector([1, 2, 3], -1)
    @test pop!(o) == 3
    @test axes(o, 1) == 0:1
    # empty!
    o = OffsetVector([1, 2, 3], -1)
    @test empty!(o) === o
    @test axes(o, 1) == 0:-1
end

@testset "searchsorted (#85)" begin
    o = OffsetVector([1,3,4,5],-2)
    @test searchsortedfirst(o,-2) == -1
    @test searchsortedfirst(o, 1) == -1
    @test searchsortedfirst(o, 2) ==  0
    @test searchsortedfirst(o, 5) ==  2
    @test searchsortedfirst(o, 6) ==  3
    @test searchsortedlast(o, -2) == -2
    @test searchsortedlast(o,  1) == -1
    @test searchsortedlast(o,  2) == -1
    @test searchsortedlast(o,  5) ==  2
    @test searchsortedlast(o,  6) ==  2
    @test searchsorted(o, -2) == -1:-2
    @test searchsorted(o,  1) == -1:-1
    @test searchsorted(o,  2) ==  0:-1
    @test searchsorted(o,  5) ==  2:2
    @test searchsorted(o,  6) ==  3:2
end

@testset "Resizing OffsetVectors" begin
    local a = OffsetVector(rand(5),-3)
    @test axes(a,1) == -2:2
    @test length(a) == 5
    resize!(a, 3)
    @test length(a) == 3
    @test axes(a,1) == -2:0
    @test_throws ArgumentError resize!(a,-3)
end


@testset "reductions" begin
    A = OffsetArray(rand(4,4), (-3,5))
    @test maximum(A) == maximum(parent(A))
    @test minimum(A) == minimum(parent(A))
    @test extrema(A) == extrema(parent(A))
    @test sum(A) == sum(parent(A))
    @test sum(A, dims=1) == OffsetArray(sum(parent(A), dims=1), map(getoffset, axes(A)))
    @test sum(A, dims=2) == OffsetArray(sum(parent(A), dims=2), map(getoffset, axes(A)))
    @test sum(A, dims=(1,2)) == OffsetArray(sum(parent(A), dims=(1,2)), map(getoffset, axes(A)))
    @test sum(view(OffsetArray(reshape(1:27, 3, 3, 3), 0, 0, 0), :, :, 1:2), dims=(2,3)) ==
          reshape([51,57,63], 3, 1, 1)
    C = similar(A)
    cumsum!(C, A, dims = 1)
    @test parent(C) == cumsum(parent(A), dims = 1)
    @test parent(cumsum(A, dims = 1)) == cumsum(parent(A), dims = 1)
    cumsum!(C, A, dims = 2)
    @test parent(C) == cumsum(parent(A), dims = 2)
    R = similar(A, (1:1, 6:9))
    maximum!(R, A)
    @test parent(R) == maximum(parent(A), dims = 1)
    R = similar(A, (-2:1, 1:1))
    maximum!(R, A)
    @test parent(R) == maximum(parent(A), dims = 2)
    amin, iamin = findmin(A)
    pmin, ipmin = findmin(parent(A))
    @test amin == pmin
    @test A[iamin] == amin
    @test amin == parent(A)[ipmin]
    amax, iamax = findmax(A)
    pmax, ipmax = findmax(parent(A))
    @test amax == pmax
    @test A[iamax] == amax
    @test amax == parent(A)[ipmax]

    amin, amax = extrema(parent(A))
    @test clamp.(A, (amax+amin)/2, amax) == OffsetArray(clamp.(parent(A), (amax+amin)/2, amax), axes(A))
end

@testset "copyto!" begin
    a = OffsetArray{Int}(undef, (-3:-1,))
    fill!(a, -1)
    copyto!(a, (1,2))   # non-array iterables
    @test a[-3] == 1
    @test a[-2] == 2
    @test a[-1] == -1
    fill!(a, -1)
    copyto!(a, -2, (1,2))
    @test a[-3] == -1
    @test a[-2] == 1
    @test a[-1] == 2
    @test_throws BoundsError copyto!(a, 1, (1,2))
    fill!(a, -1)
    copyto!(a, -2, (1,2,3), 2)
    @test a[-3] == -1
    @test a[-2] == 2
    @test a[-1] == 3
    @test_throws BoundsError copyto!(a, -2, (1,2,3), 1)
    fill!(a, -1)
    copyto!(a, -2, (1,2,3), 1, 2)
    @test a[-3] == -1
    @test a[-2] == 1
    @test a[-1] == 2

    #= FIXME
    b = 1:2    # copy between AbstractArrays
    bo = OffsetArray(1:2, (-3,))
    @test_throws BoundsError copyto!(a, b)
    fill!(a, -1)
    copyto!(a, bo)
    @test a[-3] == -1
    @test a[-2] == 1
    @test a[-1] == 2
    if VERSION < v"1.5-"
        @test_throws BoundsError copyto!(a, b)
        fill!(a, -1)
        copyto!(a, bo)
        @test a[-3] == -1
        @test a[-2] == 1
        @test a[-1] == 2
    else
        #
        # the behavior of copyto! is corrected as the documentation says "first n element"
        # https://github.com/JuliaLang/julia/pull/34049
        fill!(a, -1)
        copyto!(a, bo)
        @test a[-3] == 1
        @test a[-2] == 2
        @test a[-1] == -1
    end

    fill!(a, -1)
    copyto!(a, -2, bo)
    @test a[-3] == -1
    @test a[-2] == 1
    @test a[-1] == 2
    @test_throws BoundsError copyto!(a, -4, bo)
    @test_throws BoundsError copyto!(a, -1, bo)
    fill!(a, -1)
    copyto!(a, -3, b, 2)
    @test a[-3] == 2
    @test a[-2] == a[-1] == -1
    @test_throws BoundsError copyto!(a, -3, b, 1, 4)
    am = OffsetArray{Int}(undef, (1:1, 7:9))  # for testing linear indexing
    fill!(am, -1)
    copyto!(am, b)
    @test am[1] == 1
    @test am[2] == 2
    @test am[3] == -1
    @test am[1,7] == 1
    @test am[1,8] == 2
    @test am[1,9] == -1
    =#
end

# TODO it seems odd to me that indexing with an offset array would change the axes
# of the resulting returned array
#=
@testset "Vector indexing with offset ranges" begin
    r = OffsetArray(8:10, -1:1)
    r1 = r[0:1]
    @test r1 == 9:10  # FIXME for some reason this doesn't work with `===` like OffsetArrays.jl
    r1 = (8:10)[OffsetArray(1:2, -5:-4)]
    @test axes(r1) == (OffsetAxis(-5:-4),)
    @test parent(r1) === 8:9
    r1 = OffsetArray(8:10, -1:1)[OffsetArray(0:1, -5:-4)]
    @test axes(r1) == (IdentityUnitRange(-5:-4),)
    @test parent(r1) === 9:10
end
=#


#=
####
#### type defined for testing no_offset_view
####

struct NegativeArray{T,N,S <: AbstractArray{T,N}} <: AbstractArray{T,N}
    parent::S
end

# Note: this defines the axes-of-the-axes to be OneTo.
# In general this isn't recommended, because
#    positionof(A, i, j, ...) == map(getindex, axes(A), (i, j, ...))
# is quite desirable, and this requires that the axes be "identity" ranges, i.e.,
# `r[i] == i`.
# Nevertheless it's useful to test this on a "broken" implementation
# to make sure we still get the right answer.
Base.axes(A::NegativeArray) = map(n -> (-n):(-1), size(A.parent))

Base.size(A::NegativeArray) = size(A.parent)

function Base.getindex(A::NegativeArray{T,N}, I::Vararg{Int,N}) where {T,N}
    getindex(A.parent, (I .+ size(A.parent) .+ 1)...)
end

@testset "no offset view" begin
    # OffsetArray fallback
    A = randn(3, 3)
    O1 = OffsetArray(A, -1:1, 0:2)
    O2 = OffsetArray(O1, -2:0, -3:(-1))
    @test no_offset_view(O2) ≡ A

    # generic fallback
    A = collect(reshape(1:12, 3, 4))
    N = NegativeArray(A)
    @test N[-3, -4] == 1
    V = no_offset_view(N)
    @test collect(V) == A

    # bidirectional
    B = BidirectionalVector([1, 2, 3])
    pushfirst!(B, 0)
    OB = OffsetArrays.no_offset_view(B)
    @test axes(OB, 1) == 1:4
    @test collect(OB) == 0:3
end
=#


#=
# v  = OffsetArray([1,1e100,1,-1e100], (-3,))*1000
# v2 = OffsetArray([1,-1e100,1,1e100], (5,))*1000
# @test isa(v, OffsetArray)
# cv  = OffsetArray([1,1e100,1e100,2], (-3,))*1000
# cv2 = OffsetArray([1,-1e100,-1e100,2], (5,))*1000
# @test isequal(cumsum_kbn(v), cv)
# @test isequal(cumsum_kbn(v2), cv2)
# @test isequal(sum_kbn(v), sum_kbn(parent(v)))

@testset "Collections" begin
    A = OffsetArray(rand(4,4), (-3,5))

    @test unique(A, dims=1) == OffsetArray(parent(A), 0, first(axes(A, 2)) - 1)
    @test unique(A, dims=2) == OffsetArray(parent(A), first(axes(A, 1)) - 1, 0)
    v = OffsetArray(rand(8), (-2,))
    @test sort(v) == OffsetArray(sort(parent(v)), axes(v, 1).offset)
    @test sortslices(A; dims=1) == OffsetArray(sortslices(parent(A); dims=1), map(offset, axes(A)))
    @test sortslices(A; dims=2) == OffsetArray(sortslices(parent(A); dims=2), map(offset, axes(A)))
    @test sort(A, dims = 1) == OffsetArray(sort(parent(A), dims = 1), map(offset, axes(A)))
    @test sort(A, dims = 2) == OffsetArray(sort(parent(A), dims = 2), map(offset, axes(A)))

    @test mapslices(v->sort(v), A, dims = 1) == OffsetArray(mapslices(v->sort(v), parent(A), dims = 1), A.offsets)
    @test mapslices(v->sort(v), A, dims = 2) == OffsetArray(mapslices(v->sort(v), parent(A), dims = 2), A.offsets)
end

@testset "fill" begin
    B = fill(5, 1:3, -1:1)
    @test axes(B) == (1:3,-1:1)
    @test all(B.==5)
end
=#

# TODO I have a different approach to this. The offset is preserved
#=
@testset "similar" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))

    B = similar(A, Float32)
    @test isa(B, OffsetArray{Float32,2})
    @test axes(B) === axes(A)
    B = similar(A, (3,4))
    @test isa(B, Array{Int,2})
    @test size(B) == (3,4)
    @test axes(B) === (Base.OneTo(3), Base.OneTo(4))
    B = similar(A, (-3:3,1:4))
    @test isa(B, OffsetArray{Int,2})
    @test axes(B) == IdentityUnitRange.((-3:3, 1:4))
    B = similar(parent(A), (-3:3,1:4))
    @test isa(B, OffsetArray{Int,2})
    @test axes(B) == IdentityUnitRange.((-3:3, 1:4))
    @test isa([x for x in [1,2,3]], Vector{Int})
    @test similar(Array{Int}, (0:0, 0:0)) isa OffsetArray{Int, 2}
    @test similar(Array{Int}, (1, 1)) isa Matrix{Int}
    @test similar(Array{Int}, (Base.OneTo(1), Base.OneTo(1))) isa Matrix{Int}
end
=#

#=
@testset "reshape" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))

    B = reshape(A0, -10:-9, 9:10)
    @test isa(B, OffsetArray{Int,2})
    @test parent(B) === A0
    @test axes(B) == IdentityUnitRange.((-10:-9, 9:10))
    B = reshape(A, -10:-9, 9:10)
    @test isa(B, OffsetArray{Int,2})
    @test pointer(parent(B)) === pointer(A0)
    @test axes(B) == IdentityUnitRange.((-10:-9, 9:10))
    b = reshape(A, -7:-4)
    @test axes(b) == (IdentityUnitRange(-7:-4),)
    @test isa(parent(b), Vector{Int})
    @test pointer(parent(b)) === pointer(parent(A))
    @test parent(b) == A0[:]
    a = OffsetArray(rand(3,3,3), -1:1, 0:2, 3:5)
    # Offset axes are required for reshape(::OffsetArray, ::Val) support
    b = reshape(a, Val(2))
    @test isa(b, OffsetArray{Float64,2})
    @test pointer(parent(b)) === pointer(parent(a))
    @test axes(b) == IdentityUnitRange.((-1:1, 1:9))
    b = reshape(a, Val(4))
    @test isa(b, OffsetArray{Float64,4})
    @test pointer(parent(b)) === pointer(parent(a))
    @test axes(b) == (axes(a)..., IdentityUnitRange(1:1))

    @test reshape(OffsetArray(-1:0, -1:0), :, 1) == reshape(-1:0, 2, 1)
    @test reshape(OffsetArray(-1:2, -1:2), -2:-1, :) == reshape(-1:2, -2:-1, 2)
end
=#

#=
@testset "Indexing with OffsetArray axes" begin
    A0 = [1 3; 2 4]

    i1 = OffsetArray([2,1], (-5,))
    i1 = OffsetArray([2,1], -5)
    b = A0[i1, 1]
    @test axes(b) == (IdentityUnitRange(-4:-3),)
    @test b[-4] == 2
    @test b[-3] == 1
    b = A0[1,i1]
    @test axes(b) == (IdentityUnitRange(-4:-3),)
    @test b[-4] == 3
    @test b[-3] == 1
    v = view(A0, i1, 1)
    @test axes(v) == (IdentityUnitRange(-4:-3),)
    v = view(A0, 1:1, i1)
    @test axes(v) == (Base.OneTo(1), IdentityUnitRange(-4:-3))

    for r in (1:10, 1:1:10, StepRangeLen(1, 1, 10), LinRange(1, 10, 10))
        for s in (IdentityUnitRange(2:3), OffsetArray(2:3, 2:3))
            @test axes(r[s]) == axes(s)
        end
    end
end

=#

