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

function to_indices(A::AbstractArray{T,N}, args::Tuple{Arg,Vararg{Any,M}}) where {T,N,Arg,M}
    return Interface.to_indices(A, axes(A), args)
end

@propagate_inbounds function to_indices(A::AbstractArray{T,N}, args::Tuple{Arg}) where {T,N,Arg}
    Base.@_inline_meta
    if is_multidim_arg(Arg)
        return Interface.to_indices(A, axes(A), args)
    else
        return (to_index(eachindex(IndexLinear(), A), first(args)),)
    end
end


@propagate_inbounds function to_indices(A::AbstractArray{T,N}, args::Tuple{}) where {T,N}
    return (to_index(eachindex(IndexLinear(), A)),)
end

###
### multidim to_indices
### 
@propagate_inbounds function to_indices(
    A::AbstractArray{T,N},
    axs::Tuple,
    args::Tuple{Arg,Vararg{Any,M}}
) where {T,N,Arg,M}
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

#=
@inline function to_indices(A, inds, I::Tuple{Ellipsis, Vararg{Any, N}}) where N
    # Align the remaining indices to the tail of the `inds`
    colons = fillcolons(inds, tail(I))
    to_indices(A, inds, (colons..., tail(I)...))
end
=#

@propagate_inbounds function _multi_to_indices(
    A,
    axs::Tuple,
    arg::CartesianIndices{N},
    args::Tuple
) where {N}

    if N === 0
        return (arg, Interface.to_indices(A, inds, args)...)
    else
        return Interface.to_indices(A, axs, (arg.indices..., args...))
    end
end

@propagate_inbounds function _multi_to_indices(
    A,
    axs::Tuple,
    arg::CartesianIndex,
    args::Tuple
)

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

@propagate_inbounds function to_indices(A::AbstractArray{T,N}, axs::Tuple, args::Tuple{}) where {T,N}
    @boundscheck if length(first(axs)) == 1
        throw(BoundsError(first(axs), ()))
    end
    return to_indices(A, tail(axs), args)
end

# These are extra indices that just need to be ensured are in bounds
@propagate_inbounds function to_indices(
    A::AbstractArray{T,N},
    axs::Tuple{},
    args::Tuple{Arg,Vararg{Any,M}}
) where {T,N,Arg,M}

    Base.@_inline_meta
    if is_multidim_arg(Arg)
        return _multi_to_indices(A, axs, first(args), tail(args))
    else
        return (to_index(axes(A, N+1), first(args)), Interface.to_indices(A, (), tail(args))...)
    end
end
to_indices(A::AbstractArray{T,N}, axs::Tuple{}, args::Tuple{}) where {T,N} = ()

# As an optimization, we allow trailing Array{Bool} and BitArray to be linear over trailing dimensions
@inline function to_indices(A, axs, args::Tuple{Union{Array{Bool,N}, BitArray{N}}}) where {N}
    return (_maybe_linear_logical_index(IndexStyle(A), A, first(I)),)
end
_maybe_linear_logical_index(::IndexStyle, A, i) = to_index(A, i)
_maybe_linear_logical_index(::IndexLinear, A, i) = Base.LogicalIndex{Int}(i)

