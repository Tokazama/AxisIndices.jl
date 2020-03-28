
Base.eachindex(a::AbstractAxis) = values(a)

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

# TODO specialize on types
Base.collect(a::AbstractAxis) = collect(values(a))

function Base.map(f, x::AbstractAxis...)
    return maybe_unsafe_reconstruct(broadcast_axis(x), map(values.(x)...))
end

reverse_keys(a::AbstractAxis) = unsafe_reconstruct(a, reverse(keys(a)), values(a))

reverse_keys(a::AbstractSimpleAxis) = Axis(reverse(keys(a)), values(a))

#=
We have to define several index types (AbstractUnitRange, Integer, and i...) in
order to avoid ambiguities.
=#
@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    inds::AbstractUnitRange{<:Integer}
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, inds)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::Integer
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::StepRange{<:Integer}
)  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    inds::Function
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, inds)
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i...
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    if length(i) > 1
        error(BoundsError(a, i...))
    else
        return to_index(a, first(i))
    end
end

@propagate_inbounds function unsafe_getindex(A, inds) where {T,N}
    return unsafe_getindex(combine(inds), A, inds)
end

@propagate_inbounds function unsafe_getindex(::ToElement, A::AbstractArray{T,N}, inds::Tuple{Vararg{<:Integer}}) where {T,N}
    return Base.getindex(parent(A), inds...)
end

@propagate_inbounds function unsafe_getindex(::ToCollection, A::AbstractArray{T,N}, inds::Tuple{Vararg{Any,M}}) where {T,N,M}
    return Base.getindex(parent(A), inds...)
end

@propagate_inbounds function unsafe_getindex(::ToCollection, A::AbstractArray{T,N}, inds::Tuple{Vararg{Any,N}}) where {T,N}
    return unsafe_reconstruct(A, Base.getindex(parent(A), inds...), reindex(axes(A), inds))
end

### view
@propagate_inbounds function unsafe_view(
    A::AbstractArray{T,N},
    inds::Tuple{Vararg{<:Integer}}
) where {T,N}

    return Base.view(parent(A), inds...)
end

@propagate_inbounds function unsafe_view(
    A::AbstractArray{T,N},
    inds::Tuple{Vararg{Any,M}}
) where {T,N,M}

    return Base.view(parent(A), inds...)
end

@propagate_inbounds function unsafe_view(
    A::AbstractArray{T,N},
    inds::Tuple{Vararg{Any,N}}
) where {T,N}

    return unsafe_reconstruct(A, Base.view(parent(A), inds...), reindex(axes(A), inds))
end

### dotview
@propagate_inbounds function unsafe_dotview(
    A::AbstractArray{T,N},
    inds::Tuple{Vararg{<:Integer}}
) where {T,N}

    return Base.dotview(parent(A), inds...)
end

@propagate_inbounds function unsafe_dotview(
    A::AbstractArray{T,N},
    inds::Tuple{Vararg{Any,M}}
) where {T,N,M}

    return Base.dotview(parent(A), inds...)
end

@propagate_inbounds function unsafe_dotview(
    A::AbstractArray{T,N},
    inds::Tuple{Vararg{Any,N}}
) where {T,N}

    return unsafe_reconstruct(A, Base.dotview(parent(A), inds...), reindex(axes(A), inds))
end

