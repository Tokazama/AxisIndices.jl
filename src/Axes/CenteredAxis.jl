# TODO Mutating methods on CenteredAxis need to be specialize to ensure the center
# is maintained

"""
    CenteredAxis(indices)

"""
struct CenteredAxis{I,Ks,Inds} <: AbstractAxis{I,I,Ks,Inds}
    indices::Inds

    CenteredAxis{I,Ks,Inds}(inds::Inds) where {I,Ks,Inds} = new{I,Ks,Inds}(inds)

    CenteredAxis{I,Ks,Inds}(inds) where {I,Ks,Inds} = CenteredAxis{I,Ks,Inds}(Inds(inds))

    CenteredAxis{I,Ks}(inds::Inds) where {I,Ks,Inds} = CenteredAxis{I,Ks,Inds}(inds)

    function CenteredAxis{I}(inds::AbstractUnitRange{I}) where {I}
        if is_static(inds)
            return CenteredAxis{I,UnitSRange{I,centered_start(I, inds),centered_stop(I, inds)}}(inds)
        else
            return CenteredAxis{I,UnitRange{I}}(inds)
        end
    end

    CenteredAxis{I}(inds::AbstractUnitRange) where {I} = CenteredAxis{I}(AbstractUnitRange{I}(inds))

    CenteredAxis(inds::AbstractUnitRange{I}) where {I} = CenteredAxis{I}(inds)
end

Interface.is_indices_axis(::Type{<:CenteredAxis}) = true

Base.values(axis::CenteredAxis)= getfield(axis, :indices)

### centered_start
centered_start(axis::CenteredAxis{I}) where {I} = centered_start(I, indices(axis))
centered_start(::Type{T}, x::AbstractUnitRange) where {T} = _centered_start_from_len(T, length(x))
_centered_start_from_len(::Type{T}, len) where {T} = T(-div(len, 2))

### centered_stop
centered_stop(axis::CenteredAxis{I}) where {I} = centered_stop(I, values(axis))
@inline function centered_stop(::Type{T}, x::AbstractUnitRange) where {T}
    return _centered_stop_from_len_and_start(_centered_start_from_len(T, len), len)
end
_centered_stop_from_len_and_start(start::T, len) where {T} = T(start + len)


@inline function Base.keys(axis::CenteredAxis{I}) where {I}
    if is_static(Inds)
        return keys_type(axis)()
    else
        len = length(axis)
        start = _centered_start_from_len(V, len)
        return keys_type(axis)(start, _centered_stop_from_len_and_start(start, len))
    end
end

Base.checkindex(Bool, axis::CenteredAxis, i::Integer) = i in keys(axis)

offset(axis::CenteredAxis) = -div(length(axis) + 1, 2) - (first(getfield(axis, :values)) - 1)

function StaticRanges.similar_type(::A, vs_type::Type=indices_type(A)) where {A<:CenteredAxis}
    return similar_type(A, vs_type)
end

Styles.AxisIndicesStyle(::Type{A}, ::Type{T}) where {A<:CenteredAxis,T} = KeyedStyle(T)

