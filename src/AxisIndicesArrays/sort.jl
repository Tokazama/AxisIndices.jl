
for f in (:sort, :sort!)
    @eval function Base.$f(a::AbstractAxisIndices; dims, kwargs...)
        return AxisIndicesArray(Base.$f(parent(a); dims=dims, kwargs...), axes(a))
    end

    # Vector case
    @eval function Base.$f(a::AbstractAxisIndices{T,1}; kwargs...) where {T}
        return unsafe_reconstruct(a, Base.$f(parent(a); kwargs...), axes(a))
    end
end

################################################
# map, collect

function Base.filter(f, A::AbstractAxisIndices{T,1,P,Tuple{<:AbstractAxis{K,V,Ks,Vs}}}) where {T,P,K,V,Ks,Vs}
    inds = findall(f, parent(A))
    p = getindex(parent(A), inds)
    return unsafe_reconstruct(A, p, (to_axis(axes(A, 1), getindex(axes_keys(A, 1)::Ks, inds), axes(p, 1)),))
end

#= there are 
Base.filter(f, a::AbstractAxisIndices{T,N}) where {L,T,N} = filter(f, parent(a))
=#
