
using OffsetArrays
using OffsetArrays: IdOffsetRange, IdentityUnitRange, no_offset_view


@testset "Offset Axes" begin
    oneto = Base.OneTo(2)
    a = Axis(oneto)
    b = OffsetAxis(1, oneto)
    #b = Axis(oneto, IdOffsetRange(oneto, 1))
    c = Axis(OffsetAxis(1, oneto), OffsetAxis(1, oneto))
    #c = Axis(IdOffsetRange(oneto, 1), IdOffsetRange(oneto, 1))
    d = Axis(OffsetAxis(2, oneto), OffsetAxis(1, oneto))
    #d = Axis(IdOffsetRange(oneto, 2), IdOffsetRange(oneto, 1))
    e = SimpleAxis(values(b))
    f = SimpleAxis(2:3)

    @test b[2] == c[2] == d[2]
    @test_throws BoundsError b[1]

    # `keys(v) == OneTo(10)` so `firstindex(keys(v)) == 1` but `firstindex(values(v)) == 2`
    @test b[2] == 2
    # `keys(v) == IdOffsetRange(oneto, 1)` so `firstindex(keys(v)) == 2` and `firstindex(values(v)) == 2`
    @test c[2] == 2
    # `keys(v) == IdOffsetRange(oneto, 2)` so `firstindex(keys(v)) == 3` and `firstindex(values(v)) == 2`
    @test d[isequal(3)] == 2
    @test e[isequal(2)] == 2

    @test values(b[in(1:2)]) == 2:3
    @test values(c[in(2:3)]) == 2:3
    @test values(d[in(3:4)]) == 2:3

    oneto = Base.OneTo(2)
    a = Axis(oneto)
    b = Axis(["a", "b"], IdOffsetRange(oneto, 1))
    @test b["a"] == 2
    @test b[["a", "b"]] == [2, 3]

end

#= TODO
@testset "Single-entry arrays in dims 0:5" begin
    for n = 0:5
        for z in (OffsetArray(ones(Int,ntuple(d->1,n)), ntuple(x->x-1,n)),
                  fill!(OffsetArray{Float64}(undef, ntuple(x->x:x, n)), 1),
                  fill!(OffsetArray{Float64}(undef, ntuple(x->x:x, n)...), 1),
                  fill!(OffsetArray{Float64,n}(undef, ntuple(x->x:x, n)), 1),
                  fill!(OffsetArray{Float64,n}(undef, ntuple(x->x:x, n)...), 1))
            @test length(LinearIndices(AxisArray(z))) == 1
            @test axes(z) == ntuple(x->x:x, n)
            @test z[1] == 1
        end
    end
    a0 = reshape([3])
    a = OffsetArray(a0)
    @test axes(a) == ()
    @test ndims(a) == 0
    @test a[] == 3
end
=#

@testset "Offset range construction" begin
    r = -2:5
    y = AxisArray(OffsetArray(r, r))
    @test axes(y) == (r,)
    y = AxisArray(OffsetArray(r, (r,)))
    @test axes(y) == (r,)
end

@testset "Traits" begin
    A0 = [1 3; 2 4]
    A = AxisArray(OffsetArray(A0, (-1,2)))                   # IndexLinear
    S = AxisArray(OffsetArray(view(A0, 1:2, 1:2), (-1,2)))   # IndexCartesian
    @test axes(A) == axes(S) == (0:1, 3:4)
    @test size(A) == size(A0)
    @test size(A, 1) == size(A0, 1)
    @test length(A) == length(A0)
    @test A == OffsetArray(A0, 0:1, 3:4)
end

@testset "Scalar indexing" begin
    A0 = [1 3; 2 4]
    A = AxisArray(OffsetArray(A0, (-1,2)));
    S = AxisArray(OffsetArray(view(A0, 1:2, 1:2), (-1,2)));

    @test @inferred(A[0,3]) == @inferred(A[0,3,1]) == @inferred(A[1]) == @inferred(S[0,3]) == @inferred(S[0,3,1]) == @inferred(S[1]) == 1
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

    y = AxisArray(OffsetArray{Float64}(undef, -1:1, -7:7, -128:512, -5:5, -1:1, -3:3, -2:2, -1:1))
    y[-1,-7,-128,-5,-1,-3,-2,-1] = 14
    y[-1,-7,-128,-5,-1,-3,-2,-1] += 5
    @test y[-1,-7,-128,-5,-1,-3,-2,-1] == 19
end

@testset "CartesianAxisCore" begin
    A0 = [1 3; 2 4]
    A = AxisArray(OffsetArray(A0, (-1,2)));
    S = AxisArray(OffsetArray(view(A0, 1:2, 1:2), (-1,2)));

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
    @test eachindex(S) == CartesianIndices(IdentityUnitRange.((0:1,3:4)))
end

@testset "Vector indexing" begin
    A0 = [1 3; 2 4]
    A_1 = OffsetArray(A0, (-1,2))
    S_1 = OffsetArray(view(A0, 1:2, 1:2), (-1,2))

    A = AxisArray(OffsetArray(A0, (-1,2)))
    S = AxisArray(OffsetArray(view(A0, 1:2, 1:2), (-1,2)))

    s = S[:, 3]
    s == S_1[:,3]
    o = OffsetArray([1,2], (parent(A).offsets[1],))
    @test A[:, 3] == S[:, 3] == OffsetArray([1,2], (parent(A).offsets[1],))
    @test A[:, 4] == S[:, 4] == OffsetArray([3,4], (parent(A).offsets[1],))
    @test_throws BoundsError A[:, 1]
    @test_throws BoundsError S[:, 1]
    @test A[0, :] == S[0, :] == OffsetArray([1,3], (parent(A).offsets[2],))
    @test A[1, :] == S[1, :] == OffsetArray([2,4], (parent(A).offsets[2],))
    @test_throws BoundsError A[2, :]
    @test_throws BoundsError S[2, :]
    @test A[0:1, 3] == S[0:1, 3] == [1,2]
    @test A[[1,0], 3] == S[[1,0], 3] == [2,1]
    @test A[0, 3:4] == S[0, 3:4] == [1,3]
    @test A[1, [4,3]] == S[1, [4,3]] == [4,2]
    @test A[:, :] == S[:, :] == A
end

#= TODO
@testset "Vector indexing with offset ranges" begin
    r = AxisArray(OffsetArray(8:10, -1:1))
    r1 = r[0:1]
    @test r1 == 9:10
    r1 = (8:10)[AxisArray(OffsetArray(1:2, -5:-4))]
    @test axes(r1) == (IdentityUnitRange(-5:-4),)
    @test parent(r1) == 8:9
    r1 = AxisArray(OffsetArray(8:10, -1:1))[OffsetArray(0:1, -5:-4)]
    @test axes(r1) == (IdentityUnitRange(-5:-4),)
    @test parent(r1) == 9:10
end

@testset "view" begin
    A0 = [1 3; 2 4]
    A = AxisArray(OffsetArray(A0, (-1,2)))

    S = view(A, :, 3)
    @test S == AxisArray(OffsetArray([1,2], (A.offsets[1],)))
    @test S[0] == 1
    @test S[1] == 2
    @test_throws BoundsError S[2]
    @test axes(S) == (IdentityUnitRange(0:1),)
    S = view(A, 0, :)
    @test S == AxisArray(OffsetArray([1,3], (A.offsets[2],)))
    @test S[3] == 1
    @test S[4] == 3
    @test_throws BoundsError S[1]
    @test axes(S) == (IdentityUnitRange(3:4),)
    S = view(A, 0:0, 4)
    @test S == [3]
    @test S[1] == 3
    @test_throws BoundsError S[0]
    @test axes(S) == (Base.OneTo(1),)
    S = view(A, 1, 3:4)
    @test S == [2,4]
    @test S[1] == 2
    @test S[2] == 4
    @test_throws BoundsError S[3]
    @test axes(S) == (Base.OneTo(2),)
    S = view(A, :, :)
    @test S == A
    @test S[0,3] == S[1] == 1
    @test S[1,3] == S[2] == 2
    @test S[0,4] == S[3] == 3
    @test S[1,4] == S[4] == 4
    @test_throws BoundsError S[1,1]
    @test axes(S) == IdentityUnitRange.((0:1, 3:4))
    S = view(A, axes(A)...)
    @test S == A
    @test S[0,3] == S[1] == 1
    @test S[1,3] == S[2] == 2
    @test S[0,4] == S[3] == 3
    @test S[1,4] == S[4] == 4
    @test_throws BoundsError S[1,1]
    @test axes(S) == OffsetArrays.IdOffsetRange.((0:1, 3:4))
    # issue 100
    S = view(A, axes(A, 1), 3)
    @test S == A[:, 3]
    @test S[0] == 1
    @test S[1] == 2
    @test_throws BoundsError S[length(S)]
    @test axes(S) == (OffsetArrays.IdOffsetRange(0:1), )
    # issue 100
    S = view(A, 1, axes(A, 2))
    @test S == A[1, :]
    @test S[3] == 2
    @test S[4] == 4
    @test_throws BoundsError S[1]
    @test axes(S) == (OffsetArrays.IdOffsetRange(3:4), )

    A0 = collect(reshape(1:24, 2, 3, 4))
    A = OffsetArray(A0, (-1,2,1))
    S = view(A, axes(A, 1), 3:4, axes(A, 3))
    @test S == A[:, 3:4, :]
    @test S[0, 1, 2] == A[0, 3, 2]
    @test S[0, 2, 2] == A[0, 4, 2]
    @test S[1, 1, 2] == A[1, 3, 2]
    @test axes(S) == (OffsetArrays.IdOffsetRange(0:1), Base.OneTo(2), OffsetArrays.IdOffsetRange(2:5))
end

@testset "similar" begin
    A0 = [1 3; 2 4]
    A = AxisArray(OffsetArray(A0, (-1, 2)))

    B = similar(A, Float32)
    @test isa(B, AxisArray(OffsetArray{Float32,2}))
    @test axes(B) == axes(A)
    B = similar(A, (3,4))
    @test isa(B, Array{Int,2})
    @test size(B) == (3,4)
    @test axes(B) == (Base.OneTo(3), Base.OneTo(4))
    B = similar(A, (-3:3,1:4))
    @test isa(B, OffsetArray{Int,2})
    @test axes(B) == IdentityUnitRange.((-3:3, 1:4))
    B = similar(parent(A), (-3:3,1:4))
    @test isa(B, OffsetArray{Int,2})
end

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

@testset "AxisCore with OffsetArray axes" begin
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

@testset "logical indexing" begin
    A0 = [1 3; 2 4]
    A = OffsetArray(A0, (-1,2))

    @test A[A .> 2] == [3,4]
end

@testset "copyto!" begin
    a = AxisArray(OffsetArray{Int}(undef, (-3:-1,)))
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

    b = 1:2    # copy between AbstractArrays
    bo = AxisArray(OffsetArray(1:2, (-3,)))
    if VERSION < v"1.5-"
        @test_throws BoundsError copyto!(a, b)
        fill!(a, -1)
        copyto!(a, bo)
        @test a[-3] == -1
        @test a[-2] == 1
        @test a[-1] == 2
    else
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
end

@testset "map" begin
    am = AxisArray(OffsetArray{Int}(undef, (1:1, 7:9)))  # for testing linear indexing
    fill!(am, -1)
    copyto!(am, 1:2)

    dest = similar(am)
    map!(+, dest, am, am)
    @test dest[1,7] == 2
    @test dest[1,8] == 4
    @test dest[1,9] == -2
end

@testset "reductions" begin
    A = AxisArray(OffsetArray(rand(4,4), (-3,5)))
    @test maximum(A) == maximum(parent(A))
    @test minimum(A) == minimum(parent(A))
    @test extrema(A) == extrema(parent(A))
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
    @test sort(v) == OffsetArray(sort(parent(v)), v.offsets)
    @test sortslices(A; dims=1) == OffsetArray(sortslices(parent(A); dims=1), A.offsets)
    @test sortslices(A; dims=2) == OffsetArray(sortslices(parent(A); dims=2), A.offsets)
    @test sort(A, dims = 1) == OffsetArray(sort(parent(A), dims = 1), A.offsets)
    @test sort(A, dims = 2) == OffsetArray(sort(parent(A), dims = 2), A.offsets)

    @test mapslices(v->sort(v), A, dims = 1) == OffsetArray(mapslices(v->sort(v), parent(A), dims = 1), A.offsets)
    @test mapslices(v->sort(v), A, dims = 2) == OffsetArray(mapslices(v->sort(v), parent(A), dims = 2), A.offsets)
end

@testset "rot/reverse" begin
    A = OffsetArray(rand(4,4), (-3,5))

    @test rotl90(A) == OffsetArray(rotl90(parent(A)), A.offsets[[2,1]])
    @test rotr90(A) == OffsetArray(rotr90(parent(A)), A.offsets[[2,1]])
    @test reverse(A, dims = 1) == OffsetArray(reverse(parent(A), dims = 1), A.offsets)
    @test reverse(A, dims = 2) == OffsetArray(reverse(parent(A), dims = 2), A.offsets)
end

@testset "fill" begin
    B = fill(5, 1:3, -1:1)
    @test axes(B) == (1:3,-1:1)
    @test all(B.==5)
end

@testset "broadcasting" begin
    A = OffsetArray(rand(4,4), (-3,5))

    @test A.+1 == OffsetArray(parent(A).+1, A.offsets)
    @test 2*A == OffsetArray(2*parent(A), A.offsets)
    @test A+A == OffsetArray(parent(A)+parent(A), A.offsets)
    @test A.*A == OffsetArray(parent(A).*parent(A), A.offsets)
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

@testset "Resizing OffsetVectors" begin
    local a = OffsetVector(rand(5),-3)
    axes(a,1) == -2:2
    length(a) == 5
    resize!(a,3)
    length(a) == 3
    axes(a,1) == -2:0
    @test_throws ArgumentError resize!(a,-3)
end

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

@testset "no nesting" begin
    A = randn(2, 3)
    x = A[2, 2]
    O1 = AxisArray(OffsetArray(A, -1:0, -1:1))
    O2 = AxisArray(OffsetArray(O1, 0:1, 0:2))
    @test parent(O1) ≡ parent(O2)
    @test eltype(O1) ≡ eltype(O2)
    O2[1, 1] = x + 1            # just a sanity check
    @test A[2, 2] == x + 1
end

@testset "mutating functions for OffsetVector" begin
    # push!
    o = AxisArray(OffsetVector(Int[], -1))
    @test push!(o) === o
    @test axes(o, 1) == 0:-1
    @test push!(o, 1) === o
    @test axes(o, 1) == 0:0
    @test o[end] == 1
    @test push!(o, 2, 3) === o
    @test axes(o, 1) == 0:2
    @test o[end-1:end] == [2, 3]
    # pop!
    o = AxisArray(OffsetVector([1, 2, 3], -1))
    @test pop!(o) == 3
    @test axes(o, 1) == 0:1
    # empty!
    o = AxisArray(OffsetVector([1, 2, 3], -1))
    @test empty!(o) === o
    @test axes(o, 1) == 0:-1
end

=#

@testset "iteration" begin
    A0 = [1 3; 2 4]
    A = AxisArray(OffsetArray(A0, (-1, 2)))

    let a
        for (a,d) in zip(A, A0)
            @test a == d
        end
    end
end

