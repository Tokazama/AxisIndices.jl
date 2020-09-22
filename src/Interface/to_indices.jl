# The entry point into to_indices is `to_indices(A::AbstractArray, args::Tuple)
#
#function Base.to_indices(A::AbstractAxisArray, args::Tuple{Vararg{Union{Integer, CartesianIndex}}})
#    return to_indices(A, axes(A), I)
#end

# for things like CartesianIndex/Indices and arrays >2 dims
is_multidim_arg(::Type{T}) where {T} = false
is_multidim_arg(::Type{CartesianIndex{N}}) where {N} = true
is_multidim_arg(::Type{<:AbstractArray{T,N}}) where {T,N} = true
is_multidim_arg(::Type{<:AbstractArray{T,1}}) where {T} = false
is_multidim_arg(::Type{<:AbstractArray{CartesianIndex{N},1}}) where {N} = true
is_multidim_arg(::Type{Ellipsis}) = true

@propagate_inbounds function to_indices(A, args::Tuple{Arg,Vararg}) where {Arg}
    return Interface.to_indices(A, axes(A), args)
end

@propagate_inbounds function to_indices(A, args::Tuple{Arg}) where {Arg}
    Base.@_inline_meta
    if is_multidim_arg(Arg)
        return Interface.to_indices(A, axes(A), args)
    else
        return (to_index(eachindex(IndexLinear(), A), first(args)),)
    end
end


@propagate_inbounds to_indices(A, args::Tuple{}) = (to_index(eachindex(IndexLinear(), A)),)

###
### multidim to_indices
### 
@propagate_inbounds function to_indices(A, axs::Tuple, args::Tuple{Arg,Vararg}) where {Arg}
    Base.@_inline_meta
    if is_multidim_arg(Arg)
        return _multi_to_indices(A, axs, first(args), tail(args))
    else
        return (to_index(first(axs), first(args)), Interface.to_indices(A, maybe_tail(axs), tail(args))...)

    end
end

@propagate_inbounds function _multi_to_indices(A, axs::Tuple, arg::Ellipsis, args::Tuple)
    return Interface.to_indices(A, axs, (EllipsisNotation.fillcolons(axs, args)..., args...))
end

@propagate_inbounds function _multi_to_indices(
    A,
    axs::Tuple,
    arg::CartesianIndices{N},
    args::Tuple) where {N}

    if N === 0
        return (arg, Interface.to_indices(A, inds, args)...)
    else
        return Interface.to_indices(A, axs, (arg.indices..., args...))
    end
end

@propagate_inbounds function _multi_to_indices(A, axs::Tuple, arg::CartesianIndex, args::Tuple)
    return Interface.to_indices(A, axs, (arg.I..., args...))
end

@propagate_inbounds function _multi_to_indices(
    A,
    axs::Tuple,
    arg::AbstractArray{CartesianIndex{N}},
    args::Tuple
) where {N}
    #(first(I), to_indices(A, inds, tail(I))...)

    axs_front, axstail = Base.IteratorsMD.split(axs, Val(N))
    @boundscheck Base.checkbounds_indices(Bool, axs_front, (arg,)) || throw(BoundsError(axs_front, arg))
    return (arg, Interface.to_indices(A, axstail, args)...)
end

@propagate_inbounds function _multi_to_indices(
    A,
    axs::Tuple,
    arg::AbstractArray{Bool, N},
    args::Tuple
) where {N}

    Base.@_inline_meta
    axs_front, axstail = Base.IteratorsMD.split(axs, Val(N))
    @boundscheck !Base.checkbounds_indices(Bool, axs_front, (arg,)) || throw(BoundsError(axs_front, arg))
    return (arg, Interface.to_indices(A, axstail, args)...)
    #_, axes_tail = Base.IteratorsMD.split(axs, Val(N))
    #return (to_index(first(axs), arg), Interface.to_indices(A, axes_tail, args)...)
end


# As an optimization, we allow trailing Array{Bool} and BitArray to be linear over trailing dimensions
@inline function to_indices(A, axs::Tuple, args::Tuple{Union{Array{Bool,N}, BitArray{N}}}) where {N}
    return (_maybe_linear_logical_index(IndexStyle(A), A, first(args)),)
end
_maybe_linear_logical_index(::IndexStyle, A, i) = to_index(A, i)
_maybe_linear_logical_index(::IndexLinear, A, i) = Base.LogicalIndex{Int}(i)

#=
@propagate_inbounds function to_indices(A, axs::Tuple, args::Tuple)
    arg = first(args)
    N = argdims(arg)
    if N > 1
        if arg isa CartesianIndex
            return to_indices(A, axs, (arg.I..., tail(args)...))
        elseif arg isa CartesianIndices
            return to_indices(A, axs, (arg.indices..., tail(args)...))
        else
            axs_front, axstail = Base.IteratorsMD.split(axs, Val(N))
            @boundscheck if !Base.checkbounds_indices(Bool, axs_front, (arg,))
                throw(BoundsError(axs_front, arg))
            end
            return (arg, Interface.to_indices(A, axstail, args)...)
        end
    else
        return (to_index(first(axs), arg), Interface.to_indices(A, tail(axs), tail(args))...)
    end
end
=#

# These are extra indices that just need to be ensured are in bounds
@propagate_inbounds function to_indices(A, ::Tuple{}, args::Tuple{Arg,Vararg}) where {Arg}
    Base.@_inline_meta
    if is_multidim_arg(Arg)
        return _multi_to_indices(A, (), first(args), tail(args))
    else
        return (
            to_index(axes(A, ndims(A) + 1), first(args)),
            Interface.to_indices(A, (), tail(args))...
        )
    end
end

@propagate_inbounds function to_indices(A, axs::Tuple, ::Tuple{})
    @boundscheck if length(first(axs)) == 1
        throw(BoundsError(first(axs), ()))
    end
    return Interface.to_indices(A, tail(axs), args)
end


to_indices(A, axs::Tuple{}, args::Tuple{}) = ()

