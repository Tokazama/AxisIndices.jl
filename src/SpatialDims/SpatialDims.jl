module SpatialDims

using NamedDims
using StaticRanges
using AxisIndices.AxisCore
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
    pixel_spacing,
    spatial_directions,
    sdims

# yes, I'm abusing @pure
Base.@pure function is_spatial(x::Symbol)
    return !is_time(x) && !is_color(x) && !is_observation(x)
end

"""
    spatial_order(x) -> Tuple{Vararg{Symbol}}

Returns the `dimnames` of `x` that correspond to spatial dimensions.
"""
spatial_order(x::X) where {X} = _spatial_order(Val(dimnames(X)))
@generated function _spatial_order(::Val{L}) where {L}
    keep_names = []
    for n in L
        if is_spatial(n)
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

Returns a tuple of each axis corresponding to a spatial dimensions.
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
image. Defaults to the same as `indices`, but using `NamedDimsArray` you can
mark some axes as being non-spatial.
"""
@inline spatial_indices(x) = map(values, spatial_axes(x))

"""
    spatial_keys(x)
"""
@inline spatial_keys(x) = map(keys, spatial_axes(x))

# FIXME account for keys with no steps
"""
    pixel_spacing(x)

Return a tuple representing the separation between adjacent pixels along each axis
of the image. Derived from the step size of each element of `spatial_keys`.
"""
@inline pixel_spacing(x) = _pixel_spacing(spatial_keys(x))
@inline function _pixel_spacing(ks::NTuple{N,Any}) where {N}
    map(ks) do ks_i
        if StaticRanges.has_step(ks_i)
            return step(ks_i)
        else
            return 0
        end
    end
end

"""
    spatial_offset(x)

The offset of each dimension (i.e., where each spatial axis starts).
"""
spatial_offset(x) = map(first, spatial_keys(x))

"""
    space_directions(x) -> (axis1, axis2, ...)

Return a tuple-of-tuples, each `axis[i]` representing the displacement
vector between adjacent pixels along spatial axis `i` of the image
array, relative to some external coordinate system ("physical
coordinates").

By default this is computed from `pixel_spacing`, but you can set this
manually using ImagesMeta.
"""
function spatial_directions(x::AbstractArray{T,N}) where {T,N}
    ntuple(Val(N)) do i
        ntuple(Val(N)) do d
            if d === i
                if is_spatial(dimnames(x, i))
                    ks = axes_keys(x, i)
                    if StaticRanges.has_step(ks)
                        return step(ks)
                    else
                        return 1  # TODO If keys are not range does it make sense to return this?
                    end
                else
                    return 0
                end
            else
                return 0
            end
        end
    end
end

function _spatial_directions(ps::NTuple{N,Any}) where N
    return ntuple(i->ntuple(d->d==i ? ps[d] : zero(ps[d]),
                            Val(N)), Val(N))
end

"""
    sdims(x)

Return the number of spatial dimensions in the image. Defaults to the same as
`ndims`, but with `NamedDimsArray` you can specify that some dimensions
correspond to other quantities (e.g., time) and thus not included by `sdims`.
"""
@inline function sdims(x)
    cnt = 0
    for name in dimnames(x)
        if is_spatial(name)
            cnt += 1
        end
    end
    return cnt
end

end
