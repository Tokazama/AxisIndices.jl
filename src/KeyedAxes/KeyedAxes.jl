
module KeyedAxes

using AxisIndices
using AxisIndices.AxisCore
using StaticRanges

struct KeyedAxis{K,V,Ks,Vs} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs

    function KeyedAxis{K,V,Ks,Vs}(ks::Ks, vs::Vs, check_unique::Bool=true, check_length::Bool=true) where {K,V,Ks,Vs}
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

function KeyedAxis(ks, vs, check_unique::Bool=true, check_length::Bool=true)
    return KeyedAxis{eltype(ks),eltype(vs),typeof(ks),typeof(vs)}(ks, vs, check_unique, check_length)
end

function KeyedAxis(ks, check_unique::Bool=true, check_length::Bool=false)
    if is_static(ks)
        return KeyedAxis(ks, OneToSRange(length(ks)))
    elseif is_fixed(ks)
        return KeyedAxis(ks, OneTo(length(ks)))
    else  # is_dynamic
        return KeyedAxis(ks, OneToMRange(length(ks)))
    end
end

KeyedAxis(x::Pair) = KeyedAxis(x.first, x.second)

KeyedAxis(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs} = KeyedAxis{K,V,Ks,Vs}(keys(a), values(a))

KeyedAxis{K,V,Ks,Vs}(a::AbstractAxis) where {K,V,Ks,Vs} = KeyedAxis{K,V,Ks,Vs}(Ks(keys(a)), Vs(values(a)))

function KeyedAxis{K,V,Ks,Vs}(x::AbstractUnitRange{<:Integer}) where {K,V,Ks,Vs}
    if x isa Ks
        if x isa Vs
            return KeyedAxis{K,V,Ks,Vs}(x, x)
        else
            return  KeyedAxis{K,V,Ks,Vs}(x, Vs(x))
        end
    else
        if x isa Vs
            return KeyedAxis{K,V,Ks,Vs}(Ks(x), x)
        else
            return  KeyedAxis{K,V,Ks,Vs}(Ks(x), Vs(x))
        end
    end
end

Base.values(a::KeyedAxis) = getfield(a, :values)

Base.keys(a::KeyedAxis) = getfield(a, :keys)

function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
   ) where {A<:KeyedAxis}
    return Axis{eltype(ks_type),eltype(vs_type),ks_type,vs_type}
end

function unsafe_reconstruct(a::KeyedAxis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs, false, false)
end

@inline function AxisIndices.AxisIndicesStyle(::Type{<:KeyedAxis}, ::Type{T}) where {T}
    force_keys(AxisIndices.AxisIndicesStyles.AxisIndicesStyle(T))
end

force_keys(S::AxisIndicesStyle) = S
force_keys(S::IndicesCollection) = KeysCollection()
force_keys(S::IndexElement) = KeyElement()

end
