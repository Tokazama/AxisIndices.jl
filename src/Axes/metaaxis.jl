
struct MetaAxis{K,V,Ks,Vs,P<:AbstractAxis{K,V,Ks,Vs},M} <: AbstractAxis{K,V,Ks,Vs}
    parent::P
    meta::M
end

Base.parent(axis::MetaAxis) = getfield(axis, :parent)

Base.values(axis::MetaAxis) = values(parent(axis))

Base.keys(axis::MetaAxis) = keys(parent(axis))

"""
    has_metadata(x) -> Bool

Returns true if `x` contains additional fields besides those for `keys` or `indices`
"""
has_metadata(::T) where {T} = has_metadata(T)
has_metadata(::Type{T}) where {T} = false
has_metadata(::Type{<:MetaAxis}) = true

"""
    metadata_type(x)

Returns the type of the metadata of `x`.
"""
metadata_type(::T) where {T} = metadata_type(T)
metadata_type(::Type{T}) where {T} = nothing
metadata_type(::Type{MetaAxis{K,V,Ks,Vs,P,M}}) where {K,V,Ks,Vs,P,M} = M

StaticRanges.parent_type(::Type{MetaAxis{K,V,Ks,Vs,P,M}}) where {K,V,Ks,Vs,P,M} = A

Interface.is_indices_axis(::Type{A}) where {A<:MetaAxis} = is_indices_axis(parent_type(A))
is_keys_axis(::Type{A}) where {A<:MetaAxis} = is_indices_axis(parent_type(A))


MetaAxis(axis::AbstractAxis, meta=nothing) = MetaAxis(axis, meta)

function MetaAxis(ks::AbstractVector, vs::AbstractUnitRange{<:Integer}=OneTo(length(ks)), meta=nothing)
    return MetaAxis(to_axis(ks, vs), meta)
end

function Interface.unsafe_reconstruct(a::MetaAxis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs, false, false)
end

