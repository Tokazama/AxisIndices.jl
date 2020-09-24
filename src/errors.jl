
# check_indices_lengths
function check_indices_lengths(::Type{Bool}, data, inds::Tuple)
    return check_indices_lengths(Bool, axes(data), inds)
end
function check_indices_lengths(::Type{Bool}, inds1::Tuple, inds2::Tuple)
    for i in OneTo(length(inds1))
        length(getfield(inds1, i)) == length(getfield(inds2, i)) || return false
    end
    return true
end
function check_indices_lengths(data, inds)
    if check_indices_lengths(Bool, data, inds)
        return nothing
    else
        return "Length of indices of parent data and provided indices do not match."
    end
end

# check_indices_offsets
function check_indices_offsets(::Type{Bool}, data, inds::Tuple)
    return check_indices_offsets(Bool, axes(data), inds)
end
function check_indices_offsets(::Type{Bool}, inds1::Tuple, inds2::Tuple)
    for i in OneTo(length(inds1))
        offsets(getfield(inds1, i), 1) == offsets(getfield(inds2, i), 1) || return false
    end
    return true
end
function check_indices_offsets(A, inds)
    if check_indices_offsets(Bool, A, inds)
        return nothing
    else
        return "Offsets of indices of parent data and provided indices do not match."
    end
end

# check_linear_length - if `data` doesn't have same number of dimensions as the
# number of provided indices the indices can still be compatible if
# `IndexStyle(data) <: IndexLinear` and map to the same length.
function check_linear_length(::Type{Bool}, data, inds::Tuple)
    if IndexStyle(data) isa IndexLinear
        return prod(size(data)) == prod(map(length, inds))
    else
        return false
    end
end
function check_linear_length(data, inds)
    if check_linear_length(Bool, data, inds)
        return nothing
    else
        return "Number of dimensions for data do not match number of indices and indices cannot map linearly to data."
    end
end

function check_indices(data, inds)
    if ndims(data) === length(inds)
        return _check_indices(check_indices_lengths(data, inds), data, inds)
    else
        return check_linear_length(data, inds)
    end
end
_check_indices(::Nothing, data, inds) = check_indices_offsets(data, inds)
_check_indices(msg::String, data, inds) = msg

# a lot of the time we need to reconstruct an axis as part of some array reconstruction,
# in order to ensure the underlying indices are equivalent (we know the size doesn't change).
# Sometimes this can be avoided if the indices are the same and we know the original axis
# can't change. If the original axis is immutable and has same values but `inds` has a
# static size we want to inherit that, so we still reconstruct.
same_known_lengths(axis, inds) = known_length(inds) === known_length(axis)
same_known_firsts(axis, inds) = known_first(axis) === known_first(inds)
function should_replace_for_static(axis, inds)
    if known_length(inds) === nothing
        return false
    else
        return same_known_firsts(axis, inds) === same_known_lengths(axis, inds)
    end
end

"""
    ArrayChecks{T}

Where `T` is a `NamedTuple` and a static paramater, `ArrayChecks` preserves information
about what checks should be performed when constructing arrays.
"""
struct ArrayChecks{T}
    ArrayChecks(; kwargs...) = ArrayChecks(values(kwargs))
    ArrayChecks(checks::NamedTuple{<:Any,<:Tuple{Vararg{Bool}}}) = new{checks}()
end

@inline Base.getproperty(check::ArrayChecks{T}, k::Symbol) where {T} = get(T, k, true)

