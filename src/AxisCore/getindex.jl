
#=
We have to define several index types (AbstractUnitRange, Integer, and i...) in
order to avoid ambiguities.
=#
@propagate_inbounds function Base.getindex(
    axis::AbstractAxis{K,V,Ks,Vs},
    arg::AbstractUnitRange{<:Integer}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    index = to_index(axis, arg)
    return unsafe_reconstruct(axis, to_keys(axis, arg, index), index)
end

@propagate_inbounds function Base.getindex(
    axis::AbstractSimpleAxis{V,Vs},
    args::AbstractUnitRange{<:Integer}
) where {V<:Integer,Vs<:AbstractUnitRange{V}}

    return unsafe_reconstruct(axis, to_index(axis, args))
end

@propagate_inbounds function Base.getindex(
    a::AbstractAxis{K,V,Ks,Vs},
    i::Integer
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}

    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(
    a::AbstractSimpleAxis{V,Vs},
    i::Integer

) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(a::AbstractAxis{K,V,Ks,Vs}, i::StepRange{<:Integer})  where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}
    return to_index(a, i)
end

@propagate_inbounds function Base.getindex(axis::AbstractAxis{K,V,Ks,Vs}, arg) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V}}
    s = AxisIndicesStyle(axis, arg)
    index = to_index(s, axis, arg)
    if is_element(s)
        return index
    else
        return _axis_getindex(s, axis, arg, index)
    end
end

@propagate_inbounds function Base.getindex(axis::AbstractSimpleAxis{V,Vs}, arg) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    s = AxisIndicesStyle(axis, arg)
    index = to_index(s, axis, arg)
    if is_element(s)
        return index
    else
        return _axis_getindex(s, axis, arg, index)
    end
end

function _axis_getindex(s, axis::AbstractAxis, arg, index::AbstractUnitRange)
    return unsafe_reconstruct(axis, to_keys(s, axis, arg, index), index)
end
_axis_getindex(s, axis::AbstractAxis, arg, index) = index

function _axis_getindex(s, axis::AbstractSimpleAxis, arg, index::AbstractUnitRange)
    return unsafe_reconstruct(axis, index)
end
_axis_getindex(s, axis::AbstractSimpleAxis, arg, index) = index

for (unsafe_f, f) in ((:unsafe_getindex, :getindex), (:unsafe_view, :view), (:unsafe_dotview, :dotview))
    @eval begin
        function $unsafe_f(
            A::AbstractArray{T,N},
            args::Tuple,
            inds::Tuple{Vararg{<:Integer}},
        ) where {T,N}

            return @inbounds(Base.$f(parent(A), inds...))
        end

        function $unsafe_f(
            A::AbstractArray{T,N},
            args::Tuple,
            inds::Tuple{Vararg{Any,M}},
        ) where {T,N,M}

            return @inbounds(Base.$f(parent(A), inds...))
        end

        @propagate_inbounds function $unsafe_f(
            A::AbstractArray{T,N},
            args::Tuple,
            inds::Tuple{Vararg{Any,N}},
        ) where {T,N}

            p = Base.$f(parent(A), inds...)
            return unsafe_reconstruct(A, p, to_axes(axes(A), args, inds, axes(p)))
        end

        @propagate_inbounds function Base.$f(A::AbstractAxisIndices, args...)
            return $unsafe_f(A, args, to_indices(A, args))
        end
    end
end

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices, value, inds...)
    return setindex!(parent(a), value, to_indices(a, inds)...)
end

