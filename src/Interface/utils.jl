
function check_axis_length(ks, vs)
    if length(ks) != length(vs)
        throw(DimensionMismatch("keys and indices must have same length, got length(keys) = $(length(ks)) and length(indices) = $(length(vs))."))
    end
    return nothing
end

maybe_tail(::Tuple{}) = ()
maybe_tail(x::Tuple) = tail(x)

naxes(A, v::Val{N}) where {N} = ntuple(i -> axes(A, i), v)

