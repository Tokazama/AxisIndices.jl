
@testset "Axes - indexing" begin

    @testset "NamedCartesianAxes" begin
        @test @inferred(NamedCartesianAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]))) ==
              @inferred(NamedCartesianAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]))
        @test @inferred(NamedCartesianAxes((dimx = [:a, :b], dimy = ["one", "two"]))) ==
              @inferred(NamedCartesianAxes(NamedAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"])))
    end

    @testset "NamedLinearAxes" begin
        @test @inferred(NamedLinearAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]))) ==
              @inferred(NamedLinearAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]))
        @test @inferred(NamedLinearAxes((dimx = [:a, :b], dimy = ["one", "two"]))) ==
              @inferred(NamedLinearAxes(NamedAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"])))
    end

    @testset "NamedCartesianAxes" begin
        @test @inferred(NamedMetaCartesianAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaCartesianAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]; metadata="some metadata"))
        @test @inferred(NamedMetaCartesianAxes((dimx = [:a, :b], dimy = ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaCartesianAxes(NamedMetaAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"]; metadata="some metadata")))
    end

    @testset "NamedLinearAxes" begin
        @test @inferred(NamedMetaLinearAxes{(:dimx, :dimy)}(([:a, :b], ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaLinearAxes{(:dimx, :dimy)}([:a, :b], ["one", "two"]; metadata="some metadata"))
        @test @inferred(NamedMetaLinearAxes((dimx = [:a, :b], dimy = ["one", "two"]); metadata="some metadata")) ==
              @inferred(NamedMetaLinearAxes(NamedMetaAxisArray{(:dimx, :dimy)}(ones(2,2), [:a, :b], ["one", "two"]; metadata="some metadata")))
    end



    include("src/CoreIndexing.jl")
    using .CoreIndexing
    @testset "Array" begin
        x = AxisArray([1 2 3; 4 5 6])
        CoreIndexing.to_indices(x, (1, 1)) == (1, 1)
        
    end
end

#=
@inline function to_indices(A, inds, I::Tuple{Ellipsis, Vararg{Any, N}}) where N
    # Align the remaining indices to the tail of the `inds`
    colons = fillcolons(inds, tail(I))
    to_indices(A, inds, (colons..., tail(I)...))
end
=#

#= preserve CartesianIndices{0} as they consume a dimension.
@propagate_inbounds function to_indices(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {Arg<:CartesianIndices{0}}
    return (first(args), to_indices(A, axs, tail(args)))
end
@propagate_inbounds function to_indices(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {N,Arg<:AbstractArray{CartesianIndex{N}}}
    
    @boundscheck if any(i -> Base.checkbounds_indices(Bool, axes_front, (i,)), first(args))
        throw(BoundsError(A, first(args)))  # TODO more accurate error message
    end
    return (to_index(axes_front, first(args)), to_indices(A, axes_tail, Base.tail(args))...)
end
#= TODO is this actually supported in the middle
@propagate_inbounds function to_indices(A, axs::Tuple, args::Tuple{Arg,Vararg{Any}}) where {N,Arg<:AbstractArray{Bool, N}}
    if argdims(Arg) > 1
        axes_front, axes_tail = IteratorsMD.split(axs, Val(N))
        @boundscheck if !Base.checkbounds_indices(Bool, axes_front, (first(args),))
            throw(BoundsError(A, first(args)))  # TODO more accurate error message
        end
        return (Base.LogicalIndex(first(args)), to_indices(A, axes_tail, tail(args))...)
    else
        return (to_index(first(axs), first(args)), to_indices(A, tail(axs), tail(args))...)
    end
end
=#

=#

