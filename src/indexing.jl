

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices, value, inds...)
    return setindex!(parent(a), value, to_indices(a, axes(a), inds)...)
end

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::AbstractAxisIndices, inds...)
            return $_f(a, to_indices(a, axes(a), inds))
        end

        @propagate_inbounds function $_f(a::AbstractAxisIndices, inds::Tuple{Vararg{<:Integer}})
            return Base.$f(parent(a), inds...)
        end

        #@propagate_inbounds function $_f(a::AbstractAxisIndices, ci::CartesianIndex)
        #    return Base.$f(parent(a), ci)
        #end

        @propagate_inbounds function $_f(a::AbstractAxisIndices{T,N}, inds::Tuple{Vararg{<:Any,M}}) where {T,N,M}
            return Base.$f(parent(a), inds...)
        end
        @propagate_inbounds function $_f(a::AbstractAxisIndices{T,N}, inds::Tuple{Vararg{<:Any,N}}) where {T,N}
            p = Base.$f(parent(a), inds...)
            axs = reindex(axes(a), inds)
            return similar_type(a, typeof(p), typeof(axs))(p, axs)
        end
    end
end
