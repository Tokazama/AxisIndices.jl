
to_axis(axis::AbstractAxis) = axis

function to_axis(axis::AbstractAxis, inds::AbstractUnitRange{<:Integer})
    return assign_indices(axis, inds)
end

to_axis(axis::AbstractUnitRange{<:Integer}) = SimpleAxis(axis)
to_axis(ks::AbstractVector) = Axis(ks)
to_axis(ks::AbstractVector, vs::AbstractUnitRange{<:Integer}) = Axis(ks, vs)
to_axis(len::Integer) = SimpleAxis(len)

