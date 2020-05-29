# TODO MetaAxis documentation
"""
    MetaAxis

An axis type that allows storage of arbitraty metadata.
"""
struct MetaAxis{K,V,Ks,Vs,P<:AbstractAxis{K,V,Ks,Vs},M} <: AbstractAxis{K,V,Ks,Vs}
    parent::P
    metadata::M

    function MetaAxis(
        ks::AbstractVector,
        inds::AbstractUnitRange{<:Integer}=OneTo(length(ks)),
        meta=nothing
    )

        return MetaAxis(to_axis(ks, vs), meta)
    end

end

Base.parent(axis::MetaAxis) = getfield(axis, :parent)

Base.values(axis::MetaAxis) = values(parent(axis))

Base.keys(axis::MetaAxis) = keys(parent(axis))

Interface.metadata(axis::MetaAxis) = getfield(axis, :metadata)

Interface.has_metadata(::Type{<:MetaAxis}) = true

Interface.metadata_type(::Type{MetaAxis{K,I,Ks,Inds,P,M}}) where {K,I,Ks,Inds,P,M} = M

StaticRanges.parent_type(::Type{MetaAxis{K,I,Ks,Inds,P,M}}) where {K,I,Ks,Inds,P,M} = P

Interface.is_indices_axis(::Type{A}) where {A<:MetaAxis} = is_indices_axis(parent_type(A))

MetaAxis(axis::AbstractAxis, meta=nothing) = MetaAxis(axis, meta)

function Interface.unsafe_reconstruct(axis::MetaAxis, ks, vs)
    return MetaAxis(Interface.unsafe_reconstruct(parent(axis), ks, vs), metadata(axis))
end

function Interface.unsafe_reconstruct(axis::MetaAxis, ks)
    return MetaAxis(Interface.unsafe_reconstruct(parent(axis), ks), metadata(axis))
end

