
"""
    MetaAxisArray

An AxisArray with metadata.

## Examples
```jldoctest
julia> using AxisIndices

julia> MetaAxisArray([1 2; 3 4], (["a", "b"], [:one, :two]), metadata = "some metadata")
2×2 MetaAxisArray{Int64,2}
 • dim_1 - ["a", "b"]
 • dim_2 - [:one, :two]
metadata: String
 • some metadata
      one   two
  a     1     2
  b     3     4


```
"""
const MetaAxisArray{T,N,M,P<:AbstractAxisArray{T,N}} = MetadataArray{T,N,M,P}

function MetaAxisArray(A::AxisArray; metadata=nothing, kwargs...)
    return MetadataArray(A, _construct_meta(metadata; kwargs...))
end

function MetaAxisArray(A::AbstractArray; metadata=nothing, kwargs...)
    return MetaAxisArray(AxisArray(A); metadata=metadata, kwargs...)
end

function MetaAxisArray(A::AbstractArray, args::AbstractVector...; metadata=nothing, kwargs...)
    return MetaAxisArray(AxisArray(A, args); metadata=metadata, kwargs...)
end

function MetaAxisArray(A::AbstractArray, axs::Tuple; metadata=nothing, kwargs...)
    return MetaAxisArray(AxisArray(A, axs); metadata=metadata, kwargs...)
end

function MetaAxisArray{T}(init::ArrayInitializer, args::AbstractVector...; metadata=nothing, kwargs...) where {T}
    return MetaAxisArray(AxisArray{T}(init, args); metadata=metadata, kwargs...)
end

function MetaAxisArray{T}(init::ArrayInitializer, axs::Tuple; metadata=nothing, kwargs...) where {T}
    return MetaAxisArray(AxisArray{T}(init, axs); metadata=metadata, kwargs...)
end

function MetaAxisArray{T,N}(init::ArrayInitializer, args::AbstractVector...; metadata=nothing, kwargs...) where {T,N}
    return MetaAxisArray(AxisArray{T,N}(init, args); metadata=metadata, kwargs...)
end

function MetaAxisArray{T,N}(init::ArrayInitializer, axs::Tuple; metadata=nothing, kwargs...) where {T,N}
    return MetaAxisArray(AxisArray{T,N}(init, axs); metadata=metadata, kwargs...)
end

Base.parent(A::MetaAxisArray) = getfield(A, :parent)
