
#=
using Revise
using Pkg
Pkg.activate("./")
using AxisIndices
using Static
=#

# one parameter
s = SimpleAxis(10)
k = AxisKeys(1.0:10.0)(s)
os = AxisOffset(static(2))(SimpleAxis(static(10)))
cs = AxisOrigin(static(0))(SimpleAxis(static(10)))
ns = AxisName(:x)(s)
s1 = OnePads(3, 3)(k)
s0 = ZeroPads(3, 3)(k)
reps = ReplicatePads(static(3), static(3))(SimpleAxis(static(10)))
refs = ReflectPads(3, 3)(s)
syms = SymmetricPads(3, 3)(s)
cirs = CircularPads(3, 3)(s)

# nested parameters
ok = AxisOffset(static(3))(k)
ck = AxisOrigin()(k)
k1 = OnePads(3, 3)(k)
k0 = ZeroPads(static(3), 3)(k)
repk = ReplicatePads(3, 3)(k)
refk = ReflectPads(3, 3)(k)
symk = SymmetricPads(3, 3)(k)
cirk = CircularPads(3, 3)(k)
ok1 =

f = SimpleAxis |> AxisKeys(1.0:10.0) |> OnePads(static(3), static(3))
f(static(10))
f(SimpleAxis(static(10)))
AxisOffset(static(3))(())



@testset "range interface" begin
    @testset "first" begin
        @test @inferred(first(s)) === 1
        @test @inferred(first(k)) === 1
        @test @inferred(first(os)) === 3
        @test @inferred(first(cs)) === -5
        @test @inferred(first(ok)) === 4
        @test @inferred(first(ck)) === -5
        @test @inferred(first(k1)) === -2
        @test @inferred(first(ok1)) === 1

        @test @inferred(known_first(s)) === 1
        @test @inferred(known_first(k)) === 1
        @test @inferred(known_first(os)) === 3
        @test @inferred(known_first(cs)) === -5
        @test @inferred(known_first(ok)) === 4
        @test @inferred(known_first(ck)) === nothing
        @test @inferred(known_first(k1)) === nothing
        @test @inferred(known_first(k0)) === -2
        @test @inferred(known_first(ok1)) === 1
    end

    @testset "last" begin
        @test @inferred(last(s)) === 10
        @test @inferred(last(k)) === 10
        @test @inferred(last(os)) === 12
        @test @inferred(last(cs)) === 4
        @test @inferred(last(ok)) === 13
        @test @inferred(last(ck)) === 4
        @test @inferred(last(k1)) === 13

        @test @inferred(known_last(s)) === nothing
        @test @inferred(known_last(os)) === 12
        @test @inferred(known_last(cs)) === 4
        @test @inferred(known_last(ck)) === nothing
        @test @inferred(known_last(reps)) === 13
    end

    @testset "length" begin
        @test @inferred(length(s)) === 10
        @test @inferred(length(k)) === 10
        @test @inferred(length(os)) === 10
        @test @inferred(length(cs)) === 10
        @test @inferred(length(ok)) === 10
        @test @inferred(length(ck)) === 10
        @test @inferred(length(k1)) === 16

        @test @inferred(known_length(s)) === nothing
        @test @inferred(known_length(os)) === 10
        @test @inferred(known_length(cs)) === 10
        @test @inferred(known_length(ck)) === nothing
        @test @inferred(known_length(reps)) === 16
    end
end

@testset "to_index" begin
    a = KeyedAxis(2:10)
    @test @inferred(to_index(a, 1)) == 1
    @test @inferred(to_index(a, 1:2)) == 1:2
    x = KeyedAxis([:one, :two])
    @test @inferred(to_index(x, :one)) == 1
    @test @inferred(to_index(x, [:one, :two])) == [1, 2]

    x = KeyedAxis(0.1:0.1:0.5)
    @test @inferred(to_index(x, 0.3)) == 3

    x = KeyedAxis(["a", "b"])
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

