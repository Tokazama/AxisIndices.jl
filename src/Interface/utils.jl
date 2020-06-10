
# TODO this should probably have some sort of documentation
function to_axis end

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

# Val wraps the number of axes to retain
naxes(A::AbstractArray, v::Val) = naxes(axes(A), v)
naxes(axs::Tuple, v::Val{N}) where {N} = _naxes(axs, N)
@inline function _naxes(axs::Tuple, i::Int)
    if i === 0
        return ()
    else
        return (first(axs), _naxes(maybe_tail(axs), i - 1)...)
    end
end

@inline function _naxes(axs::Tuple{}, i::Int)
    if i === 0
        return ()
    else
        return (to_axis(1), _naxes((), i - 1)...)
    end
end

as_staticness(::StaticRanges.Static, x) = as_static(x)
as_staticness(::StaticRanges.Fixed, x) = as_fixed(x)
as_staticness(::StaticRanges.Dynamic, x) = as_dynamic(x)

