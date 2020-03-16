
struct LabeledRange{K,V,Ks<:AbstractDict{K},Vs} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs
end

const HAxis{K,V,Ks,Vs} = HierarchicalAxis{K,V,Ks,Vs}


Base.keys(a::HAxis) = getfield(a, :keys)

Base.values(a::HAxis) = getfield(a, :values)

