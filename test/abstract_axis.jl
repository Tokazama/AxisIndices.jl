
@testset "AbstractAxis" begin
    @testset "keys" begin
        axis = Axis(2:3 => 1:2)

        @test keytype(typeof(Axis(1.0:10.0))) <: Float64
        @test keytype(typeof(parent(axis))) <: Int
        @test haskey(axis, 3)
        @test !haskey(axis, 4)
        @test keys.(axes(axis)) == (2:3,)

        A = AxisArray(ones(3,2), [:one, :two, :three], nothing)
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

    @testset "step(r)" begin
        for (r,b) in ((SimpleAxis(DynamicAxis(10)), DynamicAxis(10)),)
            @test @inferred(step(r)) === step(b)
            @test @inferred(Base.step_hp(r)) === Base.step_hp(b)
            if b isa StepRangeLen
                @test @inferred(stephi(r)) == stephi(b)
                @test @inferred(steplo(r)) == steplo(b)
            end
        end

        @test @inferred(step(SimpleAxis(2))) == 1
        @test @inferred(firstindex(Axis(1:10))) == firstindex(1:10)
    end

    @testset "to_index" begin
        a = Axis(2:10)
        @test @inferred(to_index(a, 1)) == 1
        @test @inferred(to_index(a, 1:2)) == 1:2
        x = Axis([:one, :two])
        @test @inferred(to_index(x, :one)) == 1
        @test @inferred(to_index(x, [:one, :two])) == [1, 2]

        x = Axis(0.1:0.1:0.5)
        @test @inferred(to_index(x, 0.3)) == 3

        x = Axis(["a", "b"])
        @test @inferred(to_index(x, "a")) == 1
        @test @inferred(to_index(x, ==("b"))) == 2
        @test @inferred(to_index(x, "b")) == 2

        @test @inferred(to_index(x, 2)) == 2
        @test @inferred(to_index(x, ["a", "b"])) == [1, 2]
        @test @inferred(to_index(x, in(["a", "b"]))) == [1, 2]
        @test @inferred(to_index(x, 1:2)) == [1, 2]
        @test @inferred(to_index(x, [false, true])) == [2]
        @test @inferred(to_index(x, [true, true])) == [1, 2] 
        @test @inferred(to_index(x, true)) == 1
        @test @inferred(to_index(x, :)) == Base.Slice(parent(x))

        @test_throws BoundsError to_index(x, ==("c"))
        @test_throws BoundsError to_index(x, "c")
        @test_throws BoundsError to_index(x, 3)
        @test_throws BoundsError to_index(x, ["a", "b", "c"])
        @test_throws BoundsError to_index(x, 1:3)
        @test_throws BoundsError to_index(x, [true, true, true])
        @test_throws BoundsError to_index(x, false)
    end

    @testset "to_indices" begin
        A = AxisArray(ones(2,2),  (Axis(1:2), Axis(1.0:2.0)));
        V = AxisArray(ones(2), ["a", "b"]);

        @testset "linear indexing" begin
            @test @inferred(AxisIndices.to_indices(A, (1,))) == (1,)
            @test @inferred(AxisIndices.to_indices(A, (1:2,))) == (1:2,)

            @testset "Linear indexing doesn't ruin vector indexing" begin
                @test @inferred(AxisIndices.to_indices(V, (1:2,))) == (1:2,)
                @test @inferred(AxisIndices.to_indices(V, (1,))) == (1,)
                @test @inferred(AxisIndices.to_indices(V, ("a",))) == (1,)
            end
        end

        @test @inferred(AxisIndices.to_indices(A, (1, 1))) == (1, 1)
        @test @inferred(AxisIndices.to_indices(A, (1, 1:2))) == (1, 1:2)
        @test @inferred(AxisIndices.to_indices(A, (1:2, 1))) == (1:2, 1)
        @test @inferred(AxisIndices.to_indices(A, (1, :))) == (1, Base.Slice(Axis(1.0:2.0)))
        @test @inferred(AxisIndices.to_indices(A, (:, 1))) == (Base.Slice(Axis(1:2)), 1)
        @test @inferred(AxisIndices.to_indices(A, ([true, true], :))) == (Base.LogicalIndex(Bool[1, 1]), Base.Slice(Axis(1.0:2.0)))
        @test @inferred(AxisIndices.to_indices(A, (CartesianIndices((1,)), 1))) == (Axis(1:1 => 1:1), 1)
        @test @inferred(AxisIndices.to_indices(A, (1, 1.0))) == (1,1)

        A = AxisArray(reshape(1:27, 3, 3, 3));
        @test @inferred AxisIndices.to_indices(A, ([CartesianIndex(1,1,1), CartesianIndex(1,2,1)],)) == (CartesianIndex{3}[CartesianIndex(1, 1, 1), CartesianIndex(1, 2, 1)],)
        @test @inferred(A[[CartesianIndex(1,1,1), CartesianIndex(1,2,1)]]) == [1, 4]
    end

    @testset "to_axes" begin
        A = ones(2,2)
        args = (:,:)
        new_indices = axes(A)

        @test @inferred(to_axes(AxisArray(A), new_indices)) ==
              (SimpleAxis(Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

        A = ones(2)
        args = (:,)
        new_indices = axes(A)
        @test @inferred(to_axes(AxisArray(A), new_indices)) == (SimpleAxis(Base.OneTo(2)),)

        A = ones(2,2)
        args = (:,1)
        new_indices = (Base.OneTo(2),)
        @test @inferred(to_axes(AxisArray(A), (Base.OneTo(2), 1))) == (SimpleAxis(Base.OneTo(2)),)
    end

    @testset "checkindex" begin
        @test @inferred(checkindex(Bool, Axis([:a, :b]), :a))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), :c))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), 1))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), 3))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), true))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), [:a, :b]))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), [:a, :c]))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), [1, 2]))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), [1, 3]))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), [true, true]))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), [true, true, true]))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), 1..2))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), in([:a, :b])))
        #@test !@inferred(checkindex(Bool, Axis([:a, :b]), in([:a, :c])))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), ==(:a)))
        @test !@inferred(checkindex(Bool, Axis([:a, :b]), ==(:c)))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), <(:b)))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), <(2)))
        @test @inferred(checkindex(Bool, Axis([:a, :b]), :))


    @testset "checkbounds" begin
        x = Axis(1:10)
        @test Base.checkindex(Bool, x, Base.Slice(1:10))
        @test Base.checkindex(Bool, x, [1,2,3])
        @test !Base.checkindex(Bool, x, [0, 1,2,3])

        @test checkbounds(Bool, Axis(1:2), CartesianIndex(1))
        @test !checkbounds(Bool, Axis(1:2), CartesianIndex(3))

        x2 = Axis(1:2)

        @test checkbounds(Bool, x2, 2)
        @test !checkbounds(Bool, x2, 3)

        @test Base.checkindex(Bool, x2, x2 .> 3)

        @test Base.checkindex(Bool, x2, 1:2)
        @test !Base.checkindex(Bool, x2, 1:3)

        @test Base.checkindex(Bool, x2, [true, true])
        @test !Base.checkindex(Bool, x2, [true, true, true])

        @test Base.checkindex(Bool, x2, first(to_indices(1:2, ([true, true],))))
        @test !Base.checkindex(Bool, x2, first(to_indices(1:2, ([true, true, true],))))

        @test Base.checkindex(Bool, x2, 1:1:2)
        @test !Base.checkindex(Bool, x2, 1:1:3)

        # trigger errors when functions return bad indices
        @test_throws BoundsError AxisIndices.to_index(Axis(1:10), ==(11))
    end
        #= TODO I don't think this should ever happen
            @testset "CartesianElement" begin
                @test @inferred(checkindex(Bool, Axis([:a, :b]), CartesianIndex(1)))
                #@test !@inferred(checkindex(Bool, Axis([:a, :b]), CartesianIndex(3)))
            end
        =#
    end

    @testset "values/indices" begin
        @test valtype(typeof(Axis(1.0:10.0))) <: Int
        a1 = Axis(2:3 => 1:2)

        @test allunique(a1)
        @test in(2, a1)
        @test !in(3, a1)
        @test eachindex(a1) == 1:2

        @testset "Floats as keys #13" begin
            A = AxisArray(collect(1:5), 0.1:0.1:0.5)
            @test @inferred(A[0.3]) == 3
        end
    end

    @testset "isequal" begin
        x = 1:10
        y = 1:1:10
        z = StaticRanges.GapRange(1:5,6:10)
        axis = SimpleAxis(x)
        @test ==(x, axis)
        @test ==(axis, x)
        @test ==(y, axis)
        @test ==(axis, y)
        @test ==(z, axis)
        @test ==(axis, z)
        @test ==(axis, axis)
    end
end

#= FIXME we don't pop! axes
@testset "pop" begin
    for x in (Axis((1,10),DynamicAxis(10)),
              SimpleAxis(DynamicAxis(10)))
        y = collect(x)
        #@test pop(x) == pop(y)
        @test pop!(x) == pop!(y)
        @test x == y
    end
end
=#

@testset "last" begin
    @test last(Axis(2:3)) == 2
    @test last(Axis(2:3, 2:3)) == 3
end

@testset "empty length" begin
    sa = SimpleAxis(DynamicAxis(10))
    ka = Axis(collect(1:10), SimpleAxis(DynamicAxis(10)))
    @test length(empty!(sa)) == 0
    @test length(empty!(ka)) == 0
end

@testset "can_change_size" begin
    @test @inferred(!ArrayInterface.can_change_size(SimpleAxis{DUnitRange}))
    @test @inferred(ArrayInterface.can_change_size(SimpleAxis{DynamicAxis}))
    @test @inferred(!ArrayInterface.can_change_size(Axis{UnitRange{Int},SimpleAxis{DUnitRange}}))
    @test @inferred(ArrayInterface.can_change_size(Axis{DynamicAxis,SimpleAxis{DynamicAxis}}))
end

@testset "CenteredAxis" begin
    ca = @inferred(CenteredAxis(1:10))
    @test @inferred(keys(ca)) == -5:4
    @test @inferred(parent(ca)) == 1:10
end
