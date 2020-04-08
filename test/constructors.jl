
A_fixed = ones(2, 2)

A_static = SMatrix{2,2}(A_fixed)

@testset "AxisIndicesArray(::AbstractArray)" begin
    A_fixed_axes = @inferred(AxisIndicesArray(A_fixed));
    A_static_axes = @inferred(AxisIndicesArray(A_static));

    @test @inferred(axes(A_fixed_axes)) isa Tuple{SimpleAxis{Int64,OneTo{Int64}},SimpleAxis{Int64,OneTo{Int64}}}
    @test @inferred(axes(A_static_axes)) isa Tuple{SimpleAxis{Int64,UnitSRange{Int64,1,2}},SimpleAxis{Int64,UnitSRange{Int64,1,2}}}
end

@testset "AxisIndicesArray(::AbstractArray, ::Tuple{Keys...})" begin
    A_fixed_axes = @inferred(AxisIndicesArray(A_fixed, (["a", "b"], [:one, :two])))
    A_static_axes = @inferred(AxisIndicesArray(A_static))

    @test isa(@inferred(axes(A_fixed_axes)),
              Tuple{SimpleAxis{Int64,OneToMRange{Int64}},SimpleAxis{Int64,OneToMRange{Int64}}})
    @test isa(@inferred(axes(A_static_axes)),
              Tuple{SimpleAxis{Int64,OneToSRange{Int64,2}},SimpleAxis{Int64,OneToSRange{Int64,2}}})
end

#=
@testset "to_axis-dynamic" begin
    @test isa(@inferred(to_axis(["a", "b"], as_dynamic(axes(A_, 1)))),
              Axis{String,Int64,Array{String,1},OneToMRange{Int64}})

    @test isa(@inferred(to_axis(1:2, as_dynamic(axes(A_dynamic, 1)))),
              Axis{Int64,Int64,UnitMRange{Int64},OneToMRange{Int64}})

    @test isa(@inferred(to_axis(axes(A_dynamic, 1), as_dynamic(axes(A_dynamic, 1)))),
              SimpleAxis{Int64,OneToMRange{Int64}})
end

@inferred(as_static(["a", "b"], Val((2,))))

@testset "to_axis-dynamic" begin
    @test isa(@inferred(to_axis(["a", "b"], axes(A_static, 1))),
              Axis{String,Int64,SArray{Tuple{2},String,1,2},UnitSRange{Int64,1,2}})

    @test isa(@inferred(to_axis(1:2, axes(A_static, 1))),
              Axis{String,Int64,Array{String,1},OneToMRange{Int64}})

    @test isa(@inferred(to_axis(axes(A_static, 1), axes(A_static, 1))),
              SimpleAxis{Int64,OneToMRange{Int64}})
end

@testset "to_axis-static" begin
    typeof(as_axis(A_dynamic, ["a", "b"], axes(A_dynamic, 1), check_length))
end

=#
