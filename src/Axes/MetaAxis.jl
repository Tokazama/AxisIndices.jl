# TODO MetaAxis documentation
"""
    MetaAxis

An axis type that allows storage of arbitraty metadata.
"""
struct MetaAxis{K,I,Ks,Inds,P<:AbstractAxis{K,I,Ks,Inds},M} <: AbstractAxis{K,I,Ks,Inds}
    parent::P
    metadata::M

    function MetaAxis{K,I,Ks,Inds,P,M}(axis::P, meta::M) where {K,I,Ks,Inds,P<:AbstractAxis{K,I,Ks,Inds},M}
        return new{K,I,Ks,Inds,P,M}(axis, meta)
    end

    function MetaAxis(axis::AbstractAxis{K,I,Ks,Inds}, meta::M) where {K,I,Ks,Inds,M}
        return MetaAxis{K,I,Ks,Inds,typeof(axis),M}(axis, meta)
    end
    MetaAxis(axis::AbstractAxis) = MetaAxis(axis, Dict{Symbol,Any}())

    MetaAxis(ks::AbstractVector) = MetaAxis(to_axis(ks))
    MetaAxis(ks::AbstractVector, inds::AbstractUnitRange) = MetaAxis(to_axis(ks, inds))

    MetaAxis(ks::AbstractVector, meta) = MetaAxis(to_axis(ks), meta)
    MetaAxis(ks::AbstractVector, inds::AbstractUnitRange, meta) = MetaAxis(to_axis(ks, inds), meta)
end

Base.parent(axis::MetaAxis) = getfield(axis, :parent)

Base.values(axis::MetaAxis) = values(parent(axis))

Base.keys(axis::MetaAxis) = keys(parent(axis))

Interface.metadata(axis::MetaAxis) = getfield(axis, :metadata)

Interface.has_metadata(::Type{<:MetaAxis}) = true

Interface.metadata_type(::Type{MetaAxis{K,I,Ks,Inds,P,M}}) where {K,I,Ks,Inds,P,M} = M

StaticRanges.parent_type(::Type{MetaAxis{K,I,Ks,Inds,P,M}}) where {K,I,Ks,Inds,P,M} = P

Interface.is_indices_axis(::Type{A}) where {A<:MetaAxis} = is_indices_axis(parent_type(A))

function Interface.unsafe_reconstruct(axis::MetaAxis, ks, vs)
    return MetaAxis(Interface.unsafe_reconstruct(parent(axis), ks, vs), metadata(axis))
end

function Interface.unsafe_reconstruct(axis::MetaAxis, ks)
    return MetaAxis(Interface.unsafe_reconstruct(parent(axis), ks), metadata(axis))
end
