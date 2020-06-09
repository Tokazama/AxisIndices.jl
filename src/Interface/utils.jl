
function check_axis_length(ks, inds)
    if length(ks) != length(inds)
        throw(DimensionMismatch(
            "keys and indices must have same length, got length(keys) = $(length(ks))" *
            " and length(indices) = $(length(inds)).")
        )
    end
    return nothing
end

function check_axis_unique(ks, inds)
    allunique(ks) || error("All keys must be unique.")
    allunique(inds) || error("All indices must be unique.")
    return nothing
end

maybe_tail(::Tuple{}) = ()
maybe_tail(x::Tuple) = tail(x)

naxes(A, v::Val{N}) where {N} = ntuple(i -> axes(A, i), v)


as_staticness(::StaticRanges.Static, x) = as_static(x)
as_staticness(::StaticRanges.Fixed, x) = as_fixed(x)
as_staticness(::StaticRanges.Dynamic, x) = as_dynamic(x)
