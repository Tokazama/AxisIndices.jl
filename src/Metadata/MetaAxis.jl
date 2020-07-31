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

    function MetaAxis(arg1::A1) where {A1}
        if A1 <: AbstractAxis
            return MetaAxis(arg1, Dict{Symbol,Any}())
        else
            return MetaAxis(Axes.to_axis(arg1))
        end
    end

    function MetaAxis(arg1::A1, arg2::A2) where {A1,A2}
        if A1 <: AbstractAxis  # arg2 is metadata b/c already have axis
            return MetaAxis{keytype(A1),valtype(A1),keys_type(A1),indices_type(A1),A1,A2}(arg1, arg2)
        else
            if A2 <: AbstractUnitRange
                return MetaAxis(Axes.to_axis(arg1, arg2))
            else
                return MetaAxis(Axes.to_axis(arg1), arg2)
            end
        end
    end

    MetaAxis(arg1, arg2, meta) = MetaAxis(Axes.to_axis(arg1, arg2), meta)
end

Base.parent(axis::MetaAxis) = getfield(axis, :parent)

Base.values(axis::MetaAxis) = values(parent(axis))

Base.keys(axis::MetaAxis) = keys(parent(axis))

metadata(axis::MetaAxis) = getfield(axis, :metadata)

has_metadata(::Type{<:MetaAxis}) = true

metadata_type(::Type{MetaAxis{K,I,Ks,Inds,P,M}}) where {K,I,Ks,Inds,P,M} = M

ArrayInterface.parent_type(::Type{MetaAxis{K,I,Ks,Inds,P,M}}) where {K,I,Ks,Inds,P,M} = P

Interface.is_indices_axis(::Type{A}) where {A<:MetaAxis} = is_indices_axis(parent_type(A))

function Interface.unsafe_reconstruct(axis::MetaAxis, ks, vs)
    return MetaAxis(Interface.unsafe_reconstruct(parent(axis), ks, vs), metadata(axis))
end

function Interface.unsafe_reconstruct(axis::MetaAxis, ks)
    return MetaAxis(Interface.unsafe_reconstruct(parent(axis), ks), metadata(axis))
end

Base.getproperty(axis::MetaAxis, k::Symbol) = metaproperty(axis, k)

Base.setproperty!(axis::MetaAxis, k::Symbol, val) = metaproperty!(axis, k, val)
