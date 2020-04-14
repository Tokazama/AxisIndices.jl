
struct IndexedAxis{K,V,Ks,Vs} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs

    function IndexedAxis{K,V,Ks,Vs}(ks::Ks, vs::Vs, check_unique::Bool=true, check_length::Bool=true) where {K,V,Ks,Vs}
        if check_unique
            allunique(ks) || error("All keys must be unique.")
            allunique(vs) || error("All values must be unique.")
        end

        if check_length
            length(ks) == length(vs) || error("Length of keys and values must be equal, got length(keys) = $(length(ks)) and length(values) = $(length(vs)).")
        end

        eltype(Ks) <: K || error("keytype of keys and keytype do no match, got $(eltype(Ks)) and $K")
        eltype(Vs) <: V || error("valtype of values and valtype do no match, got $(eltype(Vs)) and $V")
        return new{K,V,Ks,Vs}(ks, vs)
    end
end

function IndexedAxis(ks, vs, check_unique::Bool=true, check_length::Bool=true)
    return IndexedAxis{eltype(ks),eltype(vs),typeof(ks),typeof(vs)}(ks, vs, check_unique, check_length)
end

function IndexedAxis(ks, check_unique::Bool=true, check_length::Bool=false)
    if is_static(ks)
        return IndexedAxis(ks, OneToSRange(length(ks)))
    elseif is_fixed(ks)
        return IndexedAxis(ks, OneTo(length(ks)))
    else  # is_dynamic
        return IndexedAxis(ks, OneToMRange(length(ks)))
    end
end

IndexedAxis(x::Pair) = IndexedAxis(x.first, x.second)

IndexedAxis(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs} = IndexedAxis{K,V,Ks,Vs}(keys(a), values(a))

IndexedAxis{K,V,Ks,Vs}(a::AbstractAxis) where {K,V,Ks,Vs} = IndexedAxis{K,V,Ks,Vs}(Ks(keys(a)), Vs(values(a)))

function IndexedAxis{K,V,Ks,Vs}(x::AbstractUnitRange{<:Integer}) where {K,V,Ks,Vs}
    if x isa Ks
        if x isa Vs
            return IndexedAxis{K,V,Ks,Vs}(x, x)
        else
            return  IndexedAxis{K,V,Ks,Vs}(x, Vs(x))
        end
    else
        if x isa Vs
            return IndexedAxis{K,V,Ks,Vs}(Ks(x), x)
        else
            return  IndexedAxis{K,V,Ks,Vs}(Ks(x), Vs(x))
        end
    end
end

Base.values(a::IndexedAxis) = getfield(a, :values)

Base.keys(a::IndexedAxis) = getfield(a, :keys)

function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
   ) where {A<:IndexedAxis}
    return Axis{eltype(ks_type),eltype(vs_type),ks_type,vs_type}
end

function unsafe_reconstruct(a::IndexedAxis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs, false, false)
end

