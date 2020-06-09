
"""
    unsafe_reconstruct(axis, keys, indices)

Reconstructs an `AbstractAxis` of the same type as `axis` but with keys of type
`Ks` and indices of type `Vs`. This method is considered unsafe because it bypasses
checks  to ensure that `keys` and `values` have the same length and the all `keys`
are unique.
"""
function unsafe_reconstruct(axis::AbstractUnitRange, ks, vs)
    if is_indices_axis(axis)
        return similar_type(axis, typeof(vs))(vs)
    else
        return similar_type(axis, typeof(ks), typeof(vs))(ks, vs)
    end
end

"""
    unsafe_reconstruct(axis, indices)

Reconstructs an `AbstractSimpleAxis` of the same type as `axis` but values of type `Vs`.
"""
function unsafe_reconstruct(axis::AbstractUnitRange, vs)
    if is_indices_axis(axis)
        return similar_type(axis, typeof(vs))(vs)
    else
        return unsafe_reconstruct(axis, vs, vs)
    end
end

"""
    unsafe_reconstruct(A::AbstractArray, new_parent, new_axes)

Reconstructs an `AbstractArray` of the same type as `A` but with the parent array
`parent` and axes `axes`. This method depends on an underlying call to `similar_types`.
It is considered unsafe because it bypasses safety checks to ensure the keys of
each axis are unique and match the length of each dimension of `parent`. Therefore,
this is not intended for interactive use and should only be used when it is clear
all arguments are composed correctly.
"""
function unsafe_reconstruct(A::AbstractArray, new_parent::AbstractArray, new_axes::Tuple)
    return similar_type(A, typeof(new_parent), typeof(new_axes))(new_parent, new_axes)
end


# TODO document append_keys!
#= append_keys!(x, y) =#
append_keys!(x::AbstractRange, y) = set_length!(x, length(x) + length(y))
function append_keys!(x, y)
    if eltype(x) <: eltype(y)
        for x_i in x
            if x_i in y
                error("Element $x_i appears in both collections in call to append_axis!(collection1, collection2). All elements must be unique.")
            end
        end
        return append!(x, y)
    else
        return append_axis!(x, promote_axis_collections(y, x))
    end
end

# TODO document append_axis!
#= append_axis!(x, y) =#
@inline function append_axis!(x, y)
    if !is_indices_axis(x) && !is_indices_axis(y)
        append_keys!(keys(x), keys(y))
        set_length!(values(x), length(x) + length(y))
    else
        set_length!(x, length(x) + length(y))
    end
    return x
end


