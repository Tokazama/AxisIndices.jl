
Base.map(f, A::AbstractAxisIndices) = unsafe_reconstruct(A, map(f, parent(A)), axes(A))

for f in (:map, :map!)
    # Here f::F where {F} is needed to avoid ambiguities in Julia 1.0
    @eval begin
        function Base.$f(f::F, a::AbstractArray, b::AbstractAxisIndices, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                b,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AbstractAxisIndices, b::AbstractAxisIndices, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                b,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AbstractAxisIndices, b::AbstractArray, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                a,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end
    end
end

function Base.mapslices(f, a::AbstractAxisIndices; dims, kwargs...)
    return indicesarray_result(a, Base.mapslices(f, parent(a); dims=dims, kwargs...), dims)
end

function Base.mapreduce(f1, f2, a::AbstractAxisIndices; dims=:, kwargs...)
    return indicesarray_result(a, Base.mapreduce(f1, f2, parent(a); dims=dims, kwargs...), dims)
end


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

#=
function Base.filter(f, A::AbstractAxisIndices{T,1,P,Tuple{<:AbstractAxis{K,V,Ks,Vs}}}) where {T,P,K,V,Ks,Vs}
    inds = findall(f, parent(A))
    p = getindex(parent(A), inds)
    return unsafe_reconstruct(A, p, (to_axis(axes(A, 1), getindex(axes_keys(A, 1)::Ks, inds), axes(p, 1)),))
end

=#
