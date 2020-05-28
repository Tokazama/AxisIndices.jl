
"""
    metadata(x)

Returns metadata for `x`.
"""
metadata(x) = nothing
metadata(x::SubArray) = metadata(parent(x))
metadata(x::Base.ReshapedArray) = metadata(parent(x))


"""
    axis_meta(x)

Returns metadata (i.e. not keys or indices) associated with each axis of the array `x`.
"""
axis_meta(x::AbstractArray) = map(metadata, axes(x))

"""
    axis_meta(x, i)

Returns metadata (i.e. not keys or indices) associated with the ith axis of the array `x`.
"""
axis_meta(x::AbstractArray, i) = metadata(axes(x, i))

"""
    axis_meta(x)

Returns metadata associated with the axis `x`.
"""
axis_meta(x) = nothing


"""
    has_metadata(x) -> Bool

Returns true if `x` contains additional fields besides those for `keys` or `indices`
"""
has_metadata(::T) where {T} = has_metadata(T)
has_metadata(::Type{T}) where {T} = false

"""
    metadata_type(x)

Returns the type of the metadata of `x`.
"""
metadata_type(::T) where {T} = metadata_type(T)
metadata_type(::Type{T}) where {T} = nothing

# TODO document combine_metadata
combine_metadata(::Nothing, ::Nothing) = nothing
combine_metadata(::Nothing, y) = y
combine_metadata(x, ::Nothing) = x
combine_metadata(x, y) = merge(x, y)

