
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

