
"""
    MetadataArray(parent::AbstractArray, metadata)

Custom `AbstractArray` object to store an `AbstractArray` `parent` as well as some `metadata`.

# Examples

```jldoctest metadataarray
julia> using AxisIndices

julia> v = ["John", "John", "Jane", "Louise"];

julia> s = MetadataArray(v, Dict("John" => "Treatment", "Louise" => "Placebo", "Jane" => "Placebo"))
4-element MetadataArray{String,1,Dict{String,String},Array{String,1}}:
 "John"
 "John"
 "Jane"
 "Louise"

julia> metadata(s)
Dict{String,String} with 3 entries:
  "John"   => "Treatment"
  "Jane"   => "Placebo"
  "Louise" => "Placebo"
```
"""
struct MetadataArray{T, N, M, A<:AbstractArray} <: AbstractArray{T, N}
    parent::A
    metadata::M
end

Base.parent(A::MetadataArray) = getfield(A, :parent)

function MetadataArray(v::AbstractArray{T, N}, m::M = ()) where {T, N, M}
    return MetadataArray{T, N, M, typeof(v)}(v, m)
end

"""
    MetadataVector{T, M, S<:AbstractArray}

Shorthand for `MetadataArray{T, 1, M, S}`.
"""
const MetadataVector{T, M, S<:AbstractArray} = MetadataArray{T, 1, M, S}

MetadataVector(v::AbstractVector, n = ()) = MetadataArray(v, n)

Base.size(s::MetadataArray) = Base.size(parent(s))

Base.axes(s::MetadataArray) = Base.axes(parent(s))

Base.IndexStyle(T::Type{<:MetadataArray}) = IndexStyle(parent_type(T))

@propagate_inbounds function Base.getindex(A::MetadataArray, args::Int...)
    return getindex(parent(A), args...)
end

Base.@propagate_inbounds function Base.setindex!(A::MetadataArray, val, args::Int...)
    return setindex!(A, val, args...)
end

ArrayInterface.parent_type(::Type{MetadataArray{T, M, N, A}}) where {T,M,N,A} = A

function Base.similar(A::MetadataArray, ::Type{S}, dims::Dims) where S
    return MetadataArray(similar(parent(A), S, dims), metadata(A))
end

function Base.reshape(s::MetadataArray, d::Dims)
    return MetadataArray(reshape(parent(s), d), metadata(s))
end

