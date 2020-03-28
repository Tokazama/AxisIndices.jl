
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

#= there are 
function Base.filter(f, a::AbstractAxisIndices{T,1}) where {T}
    inds = findall(f, parent(a))
    return unsafe_reconstruct(
        a,
        @inbounds(getindex(pa), inds),
        (@inbounds(reindex(axes(a, 1), inds)),)
    )
end
Base.filter(f, a::AbstractAxisIndices{T,N}) where {L,T,N} = filter(f, parent(a))
=#
