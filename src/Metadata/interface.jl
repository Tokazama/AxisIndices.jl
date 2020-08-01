
function _construct_meta(meta::AbstractDict{Symbol}; kwargs...)
    for (k, v) in kwargs
        meta[k] = v
    end
    return meta
end

_construct_meta(meta::Nothing; kwargs...) = _construct_meta(Dict{Symbol,Any}(); kwargs...)

function _construct_meta(meta::T; kwargs...) where {T}
    isempty(kwargs) || error("Cannot assign key word arguments to metadata of type $T")
    return meta
end

"""
    metadata(x)

Returns metadata for `x`.
"""
metadata(x) = nothing
metadata(x::SubArray) = metadata(parent(x))
metadata(x::Base.ReshapedArray) = metadata(parent(x))
# define our own metadata method
metadata(A::NamedDimsArray) = metadata(parent(A))
metadata(A::AbstractAxisArray) = metadata(parent(A))
metadata(axis::AbstractAxis) = metadata(indices(axis))
metadata(A::MetadataArray) = getfield(A, :metadata)

"""
    metaproperty(x, meta_key)

Return the metadata of `x` paired to `meta_key`.
"""
@inline metaproperty(x, meta_key::Symbol) = _metaproperty(metadata(x), meta_key)
_metaproperty(x::AbstractDict{Symbol}, meta_key::Symbol) = getindex(x, meta_key)
_metaproperty(x, meta_key::Symbol) = getproperty(x, meta_key)

"""
    metadata!(x, meta_key, val)

Set the metadata of `x` paired to `meta_key`.
"""
@inline metaproperty!(x, meta_key::Symbol, val) = _metaproperty!(metadata(x), meta_key, val)
_metaproperty!(x::AbstractDict{Symbol}, meta_key::Symbol, val) = setindex!(x, val, meta_key)
_metaproperty!(x, meta_key::Symbol, val) = setproperty!(x, meta_key, val)

"""
    has_metaproperty(x, meta_key) -> Bool

Returns true if `x` has a property in its metadata structure paired to `meta_key`.
"""
@inline has_metaproperty(x, meta_key::Symbol) = _has_metaproperty(metadata(x), meta_key)
_has_metaproperty(x::AbstractDict{Symbol}, meta_key::Symbol) = haskey(x, meta_key)
_has_metaproperty(x, meta_key::Symbol) = hasproperty(x, meta_key)

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
    axis_metaproperty(x, i, meta_key)

Return the metadata of `x` paired to `meta_key` at axis `i`.
"""
axis_metaproperty(x, i, meta_key::Symbol) = _metaproperty(axis_meta(x, i), meta_key)

"""
    axis_metaproperty!(x, meta_key, val)

Set the metadata of `x` paired to `meta_key` at axis `i`.
"""
axis_metaproperty!(x, i, meta_key::Symbol, val) = _metaproperty!(axis_meta(x, i), meta_key, val)

"""
    has_axis_metaproperty(x, dim, meta_key)

Returns true if `x` has a property in its metadata structure paired to `meta_key` stored
at the axis corresponding to `dim`.
"""
has_axis_metaproperty(x, i, meta_key::Symbol) = _has_metaproperty(axis_meta(x, i), meta_key)

"""
    has_metadata(x) -> Bool

Returns true if `x` contains additional fields besides those for `keys` or `indices`
"""
has_metadata(::T) where {T} = has_metadata(T)
has_metadata(::Type{T}) where {T} = false
has_metadata(::Type{<:AbstractAxis{K,I,Ks,Inds}}) where {K,I,Ks,Inds} = has_metadata(Inds)
has_metadata(::Type{<:MetadataArray}) = true
function has_metadata(::Type{A}) where {A<:AbstractArray}
    if parent_type(A) <: A
        return false
    else
        return has_metadata(parent_type(A))
    end
end

"""
    metadata_type(x)

Returns the type of the metadata of `x`.
"""
metadata_type(::T) where {T} = metadata_type(T)
metadata_type(::Type{T}) where {T} = nothing
metadata_type(::Type{<:MetadataArray{T,N,M,S}}) where {T,N,M,S} = M
function metadata_type(::Type{A}) where {A<:AbstractArray}
    if parent_type(A) <: A
        return nothing
    else
        return metadata_type(parent_type(A))
    end
end
metadata_type(::Type{<:AbstractAxis{K,I,Ks,Inds}}) where {K,I,Ks,Inds} = metadata_type(Inds)

# This allows dictionaries's keys to be treated like property names
@inline metanames(x) = _metanames(metadata(x))
_metanames(m::AbstractDict) = keys(m)
_metanames(x) = propertynames(x)

# TODO document combine_metadata
function combine_metadata(x::AbstractUnitRange, y::AbstractUnitRange)
    return combine_metadata(metadata(x), metadata(y))
end
combine_metadata(::Nothing, ::Nothing) = nothing
combine_metadata(::Nothing, y) = y
combine_metadata(x, ::Nothing) = x
combine_metadata(x, y) = merge(x, y)

