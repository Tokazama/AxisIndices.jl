# TODO Mutating methods on CenteredAxis need to be specialize to ensure the center
# is maintained

"""
    CenteredAxis(indices)

Note: the element type of a `CenteredAxis` cannot be unsigned because any instance with
a length greater than 1 will begin at a negative value.
"""
struct CenteredAxis{K,I,Ks<:AbstractUnitRange{K},Inds<:AbstractUnitRange{I}} <: AbstractAxis{K,I,Ks,Inds}
    indices::Inds

    CenteredAxis{K,I,Ks,Inds}(inds::Inds) where {K,I,Ks,Inds} = new{K,I,Ks,Inds}(inds)

    CenteredAxis{K,I,Ks,Inds}(inds) where {K,I,Ks,Inds} = CenteredAxis{I,Ks,Inds}(Inds(inds))

    # CenteredAxis{K,I,Ks}
    CenteredAxis{K,I,Ks}(inds::Inds) where {K,I,Ks,Inds} = CenteredAxis{K,I,Ks,Inds}(inds)

    # CenteredAxis{K,I}
    function CenteredAxis{K,I}(inds::AbstractUnitRange{I}) where {K,I}
        if is_static(inds)
            return CenteredAxis{K,I,UnitSRange{K,centered_start(K, inds),centered_stop(K, inds)}}(inds)
        else
            return CenteredAxis{K,I,UnitRange{K}}(inds)
        end
    end

    function CenteredAxis{K,I}(inds::AbstractUnitRange) where {K,I}
        return CenteredAxis{K,I}(AbstractUnitRange{I}(inds))
    end

    # CenteredAxis{K}
    CenteredAxis{K}(inds::AbstractUnitRange{I}) where {K,I} = CenteredAxis{K,I}(inds)

    # CenteredAxis
    CenteredAxis(inds::AbstractUnitRange{I}) where {I} = CenteredAxis{I}(inds)
end

Interface.is_indices_axis(::Type{<:CenteredAxis}) = true

Base.values(axis::CenteredAxis)= getfield(axis, :indices)

### centered_start
centered_start(axis::CenteredAxis{K}) where {K} = centered_start(K, indices(axis))
centered_start(::Type{T}, x::AbstractUnitRange) where {T} = _centered_start_from_len(T, length(x))
_centered_start_from_len(::Type{T}, len) where {T} = T(-div(len, 2))

### centered_stop
centered_stop(axis::CenteredAxis{K}) where {K} = centered_stop(K, values(axis))
@inline function centered_stop(::Type{T}, x::AbstractUnitRange) where {T}
    len = length(x)
    return _centered_stop_from_len_and_start(_centered_start_from_len(T, len), len)
end
_centered_stop_from_len_and_start(start::T, len) where {T} = T(start + len - 1)


@inline function Base.keys(axis::CenteredAxis{K,I,Ks}) where {K,I,Ks}
    if is_static(Ks)
        return Ks()
    else
        len = length(axis)
        start = _centered_start_from_len(K, len)
        return Ks(start, _centered_stop_from_len_and_start(start, len))
    end
end

Base.checkindex(Bool, axis::CenteredAxis, i::Integer) = i in keys(axis)

offset(axis::CenteredAxis) = -div(length(axis) + 1, 2) - (first(getfield(axis, :values)) - 1)

function StaticRanges.similar_type(::A, vs_type::Type=indices_type(A)) where {A<:CenteredAxis}
    return similar_type(A, vs_type)
end

Styles.AxisIndicesStyle(::Type{A}, ::Type{T}) where {A<:CenteredAxis,T} = KeyedStyle(T)

function _centered_axis_similar_type(::Type{Ks}, ::Type{Inds}) where {Ks,Inds}
    if Ks <: OneToUnion
        error("CenteredAxis cannot have keys that start at one, got keys of type $Ks")
    else
        return CenteredAxis{eltype(Ks),eltype(Inds),Ks,Inds}
    end
end

function _centered_axis_similar_type(::Type{OneToSRange{T,L}}) where {T,L}
    start = _centered_start_from_len(K, L)
    return CenteredAxis{T,T,UnitSRange{K,start,_centered_stop_from_len_and_start(start, L)},OneToSRange{T,L}}
end

function _centered_axis_similar_type(::Type{UnitSRange{T,B,L}}) where {T,B,L}
    len = L - B + 1
    start = _centered_start_from_len(K, len)
    return CenteredAxis{T,T,UnitSRange{K,start,_centered_stop_from_len_and_start(start, len)},UnitSRange{T,B,L}}
end

function _centered_axis_similar_type(::Type{Inds}) where {Inds}
    I = eltype(Inds)
    return CenteredAxis{I,I,UnitRange{I},Inds}
end

function StaticRanges.similar_type(
    ::Type{<:CenteredAxis},
    ::Type{Ks},
    ::Type{Inds},
) where {Ks,Inds}

    return _centered_axis_similar_type(Ks, Inds)
end

function StaticRanges.similar_type(
    ::Type{<:CenteredAxis},
    ::Type{Ks},
) where {Ks}

    return _centered_axis_similar_type(Ks)
end

