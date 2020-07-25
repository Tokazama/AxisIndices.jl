
#@test isempty(detect_ambiguities(IdentityAxis, Base, Core))

# TODO: once we can rely on Julia 0.6, the try/catch won't be necessary
try
    @testset "IdentityAxis" begin
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
            @test r+r == OffsetArray(4:2:8, axes(r))
            # TODO this can't be done with other AbstractUnitRange types so why here?
            # @test r-r == OffsetArray([0,0,0], axes(r))
            @test (9:2:13)-r == 7:9
            @test -r == OffsetArray(-2:-1:-4, axes(r))
            @test reverse(r) == OffsetArray(4:-1:2, axes(r))
            @test r / 2 == r ./ 2 == OffsetArray(1:0.5:2, axes(r))
            @test 2 \ r == 2 .\ r == OffsetArray(1:0.5:2, axes(r))

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
    end
catch err
    if err.fail == 0 && err.error == 0
        println("some tests are marked with @test_broken")
    else
        rethrow(err)
    end
end

nothing
