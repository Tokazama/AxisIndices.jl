
function check_axis_length(ks, inds)
    if length(ks) != length(inds)
        throw(DimensionMismatch(
            "keys and indices must have same length, got length(keys) = $(length(ks))" *
            " and length(indices) = $(length(inds)).")
        )
    end
    return nothing
end

function check_unique_keys(ks)
    if allunique(ks)
        return nothing
    else
        error("All keys must be unique")
    end
end
function check_offsets(ks, inds)
    if firstindex(inds) === firstindex(ks)
        return nothing
    else
        throw(ArgumentError("firstindex of $ks and $inds are not the same."))
    end
end

