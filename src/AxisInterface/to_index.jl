
###
### to_index
###
@propagate_inbounds function Base.to_index(x::AbstractAxis, i::KeyIndexType)
    return _maybe_throw_boundserror(x, findfirst(==(i), keys(x)))
end

@propagate_inbounds function Base.to_index(x::AbstractAxis, f::Base.Fix2{<:Union{typeof(isequal),typeof(==)}})
    return _maybe_throw_boundserror(x, find_first(f, keys(x)))
end

@propagate_inbounds Base.to_index(x::AbstractAxis, f::Function) = find_all(f, keys(x))

@propagate_inbounds Base.to_index(x::AbstractAxis, i::CartesianIndex{1}) = first(i.I)


@propagate_inbounds function _maybe_throw_boundserror(x, i)::Integer
    @boundscheck if i isa Nothing
        throw(BoundsError(x, i))
    end
    return i
end

@propagate_inbounds function _maybe_throw_boundserror(x, inds::AbstractVector)
    @boundscheck if !(eltype(inds) <: Integer)
        throw(BoundsError(x, i))
    end
    return inds
end

@propagate_inbounds function Base.to_index(x::AbstractAxis, inds::AbstractVector{T}) where {T<:Integer}
    return to_index(inds)
end

@propagate_inbounds function Base.to_index(x::AbstractAxis, inds::AbstractVector{T}) where {T<:KeyIndexType}
    return _maybe_throw_boundserror(x, find_all(in(inds), keys(x)))
end

###
### to_indices
###
function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{Any, Vararg{Any}})
    Base.@_inline_meta
    return (to_index(first(inds), first(I)), to_indices(A, maybetail(inds), tail(I))...)
end

function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{Colon, Vararg{Any}})
    Base.@_inline_meta
    return (values(first(inds)), to_indices(A, maybetail(inds), tail(I))...)
end

function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{CartesianIndex, Vararg{Any}})
    Base.@_inline_meta
    return to_indices(A, inds, (I[1].I..., tail(I)...))
end

function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    Base.@_inline_meta
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, first(I)), to_indices(A, indstail, tail(I))...)
end
# And boolean arrays behave similarly; they also skip their number of dimensions
@inline function Base.to_indices(A, inds::Tuple{<:AbstractAxis, Vararg{Any}}, I::Tuple{AbstractArray{Bool, N}, Vararg{Any}}) where N
    _, indstail = Base.IteratorsMD.split(inds, Val(N))
    return (to_index(A, I[1]), to_indices(A, indstail, tail(I))...)
end

maybetail(::Tuple{}) = ()
maybetail(t::Tuple) = tail(t)

