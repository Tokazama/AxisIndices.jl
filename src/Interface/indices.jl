
"""
    is_indices_axis(x) -> Bool

If `true` then `x` is an axis type where the only field parameterizing the axis
is a field for the values.
"""
is_indices_axis(x) = is_indices_axis(typeof(x))
is_indices_axis(::Type{T}) where {T<:AbstractUnitRange{<:Integer}} = true
is_indices_axis(::Type{T}) where {T} = false

#= assign_indices(axis, indices)

Reconstructs `axis` but with `indices` replacing the indices/values.
There shouldn't be any change in size of the indices.
=#
function assign_indices(axis, inds)
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, keys(axis), inds)
    end
end

