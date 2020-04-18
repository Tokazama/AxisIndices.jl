module SpatialDims

using NamedDims
using AxisIndices.Names
using AxisIndices.ObservationDims
using AxisIndices.TimeDims
using AxisIndices.ColorDims

export
    spatial_order,
    spatialdims,
    spatial_axes,
    spatial_offset,
    spatial_keys,
    spatial_indices,
    spatial_size,
    spatial_units,
    pixel_spacing

"""
    spatial_order(x) -> Tuple{Vararg{Symbol}}
"""
spatial_order(x::X) where {X} = _spatial_order(Val(dimnames(X)))
@generated function _spatial_order(::Val{L}) where {L}
    keep_names = []
    for n in L
        if !(is_time(n) | is_color(n) | is_observation(n))
            push!(keep_names, n)
        end
    end
    out = (keep_names...,)
    quote
        return $out
    end
end

"""
    spatialdims(x) -> Tuple{Vararg{Int}}

Return a tuple listing the spatial dimensions of `img`.
Note that a better strategy may be to use ImagesAxes and take slices along the time axis.
"""
@inline spatialdims(x) = dim(dimnames(x), spatial_order(x))

"""
    spatial_axes(x) -> Tuple
"""
@inline spatial_axes(x) = _spatial_axes(named_axes(x), spatial_order(x))
function _spatial_axes(na::NamedTuple, spo::Tuple{Vararg{Symbol}})
    return map(spo_i -> getfield(na, spo_i), spo)
end

"""
    spatial_size(x) -> Tuple{Vararg{Int}}

Return a tuple listing the sizes of the spatial dimensions of the image.
"""
@inline spatial_size(x) = map(length, spatial_axes(x))

"""
    spatial_indices(x)

Return a tuple with the indices of the spatial dimensions of the
image. Defaults to the same as `indices`, but using ImagesAxes you can
mark some axes as being non-spatial.
"""
@inline spatial_indices(x) = map(values, spatial_axes(x))

"""
    spatial_keys(x)
"""
@inline spatial_keys(x) = map(keys, spatial_axes(x))

"""
    pixel_spacing(x)
"""
@inline pixel_spacing(x) = map(step, spatial_keys(x))

spatial_eltype(x) = map(eltype, spatial_axes(x))

"""
    spatial_offset(x)

The offset of each dimension (i.e., where each spatial axis starts).
"""
spatial_offset(x) = map(first, spatial_keys(x))

end
