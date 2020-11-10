
struct AxisArrayChecks{T}
    AxisArrayChecks{T}() where {T} = new{T}()
    AxisArrayChecks() = AxisArrayChecks{Union{}}()
end

struct CheckedAxisLengths end
checked_axis_lengths(::AxisArrayChecks{T}) where {T} = AxisArrayChecks{Union{T,CheckedAxisLengths}}()
check_axis_length(ks, inds, ::AxisArrayChecks{T}) where {T >: CheckedAxisLengths} = nothing
function check_axis_length(ks, inds, ::AxisArrayChecks{T}) where {T}
    if length(ks) != length(inds)
        throw(DimensionMismatch(
            "keys and indices must have same length, got length(keys) = $(length(ks))" *
            " and length(indices) = $(length(inds)).")
        )
    end
    return nothing
end

struct CheckedUniqueKeys end
checked_unique_keys(::AxisArrayChecks{T}) where {T} = AxisArrayChecks{Union{T,CheckedUniqueKeys}}()
check_unique_keys(ks, ::AxisArrayChecks{T}) where {T >: CheckedUniqueKeys} = nothing
function check_unique_keys(ks, ::AxisArrayChecks{T}) where {T}
    if allunique(ks)
        return nothing
    else
        error("All keys must be unique")
    end
end
struct CheckedOffsets end
checked_offsets(::AxisArrayChecks{T}) where {T} = AxisArrayChecks{Union{T,CheckedOffsets}}()
check_offsets(ks, inds, ::AxisArrayChecks{T}) where {T >: CheckedOffsets} = nothing
function check_offsets(ks, inds, ::AxisArrayChecks{T}) where {T}
    if firstindex(inds) === firstindex(ks)
        return nothing
    else
        throw(ArgumentError("firstindex of $ks and $inds are not the same."))
    end
end

const NoChecks = AxisArrayChecks{Union{CheckedAxisLengths,CheckedUniqueKeys,CheckedOffsets}}()
