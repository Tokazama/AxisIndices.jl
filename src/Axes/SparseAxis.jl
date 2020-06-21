
struct SparseIndices{K,V,Ks,Vs} <: AbstractOffsetAxis{K,V,Ks,Vs}
    keys::Ks
    indices::Vs
end

