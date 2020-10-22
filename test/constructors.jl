
#= TODO move these col/row methods somewhere
@testset "column methods" begin
    A = AxisArray(ones(2,2), ["a", "b"], [:one, :two])
    @test @inferred(col_axis(A)) isa Axis{Symbol,Int64,<:AbstractVector{Symbol},Base.OneTo{Int64}}
    @test @inferred(col_keys(A)) == [:one, :two]
    @test @inferred(col_type(A)) <: Axis{Symbol,Int64,<:AbstractVector{Symbol},Base.OneTo{Int64}}
end

@testset "row methods" begin
    A = AxisArray(ones(2,2), ["a", "b"], [:one, :two])
    @test @inferred(row_axis(A)) isa Axis{String,Int64,<:AbstractVector{String},Base.OneTo{Int64}}
    @test @inferred(row_keys(A)) == ["a", "b"]
    @test @inferred(row_type(A)) <: Axis{String,Int64,<:AbstractVector{String},Base.OneTo{Int64}}
end
=#

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

