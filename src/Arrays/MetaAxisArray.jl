
# define our own metadata method
Interface.metadata(x::MetadataArray) = getfield(x, :metadata)

function _construct_meta(meta::AbstractDict{Symbol}; kwargs...)
    for (k, v) in kwargs
        meta[k] = v
    end
    return meta
end

_construct_meta(meta::Nothing; kwargs...) = _construct_meta(Dict{Symbol,Any}(); kwargs...)

function _construct_meta(meta::T; kwargs...) where {T}
    isempty(kwargs) || warning("Cannot assign key word arguments to metadata of type $T")
    return meta
end

"""
    MetaAxisArray()

An AxisArray with metadata.

## Examples
```jldoctest
julia> AxisIndices

julia> MetaAxisArray(ones(2, 2))
```
"""
const MetaAxisArray{T,N,Ax,M,P<:AbstractAxisArray{T,N,Ax}} = MetadataArray{T,N,M,P}

function MetaAxisArray(A::AbstractArray, axs::Tuple=axes(A); metadata=nothing, kwargs...)
    return MetadataArray(AxisArray(A, axs), _construct_meta(metadata; kwargs...))
end

function Base.show(io::IO, x::MetaAxisArray; kwargs...)
    return show(io, MIME"text/plain"(), x, kwargs...)
end

function Base.show(io::IO, m::MIME"text/plain", x::MetaAxisArray{T,N}; kwargs...) where {T,N}
    println(io, "$(typeof(x).name.name){$T,$N,$(parent_type(x))...}")
    return show_array(io, parent(x), axes(x); kwargs...)
end



"""
    NamedMetaAxisArray

An AxisArray with metadata and named dimensions.
"""
const NamedMetaAxisArray{L,T,N,Ax,M,P<:AbstractAxisArray{T,N,Ax}} = NamedDimsArray{L,T,N,MetadataArray{T,N,M,P}}

function NamedMetaAxisArray(A::AbstractArray{T,N}, axs::Tuple, metadata=nothing) where {T,N}
    return NamedMetaAxisArray{Interface.default_names(Val(N))}(A, axs, metadata)
end

function NamedMetaAxisArray(A::AbstractArray{T,N}, axs::NamedTuple{L}, metadata=nothing) where {L,T,N}
    return NamedMetaAxisArray{L}(A, values(axs), metadata)
end

function NamedMetaAxisArray{L}(A::AbstractArray{T,N}, axs::Tuple; metadata=nothing) where {L,T,N}
    return NamedDimsArray{L}(MetaAxisArray(A, axs, metadata))
end

function NamedMetaAxisArray(A::AbstractArray{T,N}; kwargs...) where {T,N}
    return NamedMetaAxisArray{Interface.default_names(Val(N))}(A, axs, meta)
end

function NamedMetaAxisArray(
    x::AbstractArray{T,N},
    args...;
    metadata=nothing,
    kwargs...
) where {T,N}

    if isempty(args)
        if isempty(kwargs)
            return NamedMetaAxisArray(x, metadata)
        else
            return NamedMetaAxisArray(x, values(kwargs), metadata)
        end
    elseif isempty(kwargs)
        return NamedMetaAxisArray(x, args, metadata)
    else
        error("Indices can only be specified by keywords or additional arguments after the parent array, not both.")
    end
end

function NamedMetaAxisArray{L}(
    x::AbstractArray{T,N},
    args...;
    metadata=nothing,
    kwargs...
) where {L,T,N}

    if metadata isa Nothing
        if isempty(args)
            if isempty(kwargs)
                return NamedMetaAxisArray{L}(x, metadata)
            else
                return NamedMetaAxisArray{L}(x, values(kwargs), metadata)
            end
        elseif isempty(kwargs)
            return NamedMetaAxisArray(x, args, metadata)
        else
            error("Indices can only be specified by keywords or additional arguments after the parent array, not both.")
        end
    end
end

