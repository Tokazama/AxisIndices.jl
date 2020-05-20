
"""
    IdentityAxis{V,Vs}

Instead of being reconstructed with the original offset when indexing, a `IdentityAxis`
propagates the indices it was indexed with (e.g., IdentityAxis(1:10)[3:4] == IdentityAxis(3:4))
"""
struct IdentityAxis{V,Vs} <: AbstractOffsetAxis{V,Vs}
    values::Vs
end


function IdentityAxis(ks::AbstractUnitRange, vs::AbstractUnitRange)
    return IdentityAxis{eltype(vs),typeof(vs)}(ks, vs)
end
function IdentityAxis{V,Vs}(ks::AbstractUnitRange, vs::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return IdentityAxis{V,Vs}(compute_offset(vs, ks), vs)
end


