
###
### offset axes
###
function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:AbstractUnitRange}
    return true
end

function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:OneToUnion}
    return false
end

# StaticRanges.has_offset_axes is taken care of by any array type that defines `axes_type`

for f in (:is_static, :is_fixed, :is_dynamic)
    @eval begin
        function StaticRanges.$f(::Type{A}) where {A<:AbstractAxis}
            if is_indices_axis(A)
                return StaticRanges.$f(indices_type(A))
            else
                return StaticRanges.$f(indices_type(A)) & StaticRanges.$f(keys_type(A))
            end
        end
    end
end

for f in (:as_static, :as_fixed, :as_dynamic)
    @eval begin
        function StaticRanges.$f(x::A) where {A<:AbstractAxis}
            if is_indices_axis(A)
                return unsafe_reconstruct(x, StaticRanges.$f(values(x)))
            else
                return unsafe_reconstruct(x, StaticRanges.$f(keys(x)), StaticRanges.$f(values(x)))
            end
        end
    end
end
