
@testset "AxisArray" begin

    A_fixed = ones(2, 2)

    # TODO properly import StaticArrays
    A_static = StaticRanges.SMatrix{2,2}(A_fixed)

    @testset "AxisArray(::AbstractArray)" begin
        A_fixed_axes = @inferred(AxisArray(A_fixed));
        A_static_axes = @inferred(AxisArray(A_static));

        @test @inferred(axes(A_fixed_axes)) isa Tuple{SimpleAxis{Int64,OneTo{Int64}},SimpleAxis{Int64,OneTo{Int64}}}
        @test @inferred(axes(A_static_axes)) isa Tuple{SimpleAxis{Int64,OneToSRange{Int64,2}},SimpleAxis{Int64,OneToSRange{Int64,2}}}
    end

    @testset "AxisArray(::AbstractArray, ::Tuple{Keys...})" begin
        A_fixed_axes = @inferred(AxisArray(A_fixed, (["a", "b"], [:one, :two])));
        A_static_axes = @inferred(AxisArray(A_static));

        @test isa(@inferred(axes(A_fixed_axes)),
                  Tuple{Axis{String,Int64,<:AbstractVector{String},OneTo{Int64}},Axis{Symbol,Int64,<:AbstractVector{Symbol},OneTo{Int64}}})
        @test isa(@inferred(axes(A_static_axes)),
                  Tuple{SimpleAxis{Int64,OneToSRange{Int64,2}},SimpleAxis{Int64,OneToSRange{Int64,2}}})
    end

    @testset "AxisArray(::Array{T,0})" begin
        A = AxisArray(Array{Int,0}(undef, ()))
        @test A isa AxisArray{Int,0}
    end

    # FIXME
    @testset "AxisArray{T,N}(::AbstractArray...)" begin
        @test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), ["a", "b"], [:one, :two]))) <: Array{Int,2}
        # TODO why would I need these constructors?
        #@test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), (2, 2)))) <: Array{Int,2}
        #@test parent_type(@inferred(AxisArray{Int,2}(ones(2,2), 2, 2))) <: Array{Int,2}

    end

    @testset "AxisArray(undef, ::Tuple{Keys...})" begin
        @test parent_type(@inferred(AxisArray{Int}(undef, (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int}(undef, ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int}(undef, (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int}(undef, 2, 2))) <: Array{Int,2}

        @test parent_type(@inferred(AxisArray{Int,2}(undef, (["a", "b"], [:one, :two])))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(undef, ["a", "b"], [:one, :two]))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(undef, (2, 2)))) <: Array{Int,2}
        @test parent_type(@inferred(AxisArray{Int,2}(undef, 2, 2))) <: Array{Int,2}
    end

    @testset "AxisArray{T,N,P}" begin
        A = AxisArray(reshape(1:4, 2, 2))
        @test typeof(@inferred(convert(AxisArray{Int32,2,Array{Int32,2}}, A))) <: AxisArray{Int32,2,Array{Int32,2}}
    end

    @testset "collect(::AxisArray)" begin
        x = AxisArray(reshape(1:10, 2, 5))
        @test typeof(parent(collect(x))) <: typeof(collect(parent(x)))
        @test x isa AxisArray
    end
end

