
Base.keytype(::Type{<:AbstractAxis{K}}) where {K} = K

Base.haskey(a::AbstractAxis{K}, key::K) where {K} = key in keys(a)

reverse_keys(a::AbstractAxis) = unsafe_reconstruct(a, reverse(keys(a)), values(a))

reverse_keys(a::AbstractSimpleAxis) = Axis(reverse(keys(a)), values(a))

"""
    keys_type(x)

Retrieves the type of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys_type(Axis(1:2))
UnitRange{Int64}

julia> keys_type(typeof(Axis(1:2)))
UnitRange{Int64}

julia> keys_type(UnitRange{Int})
Base.OneTo{Int64}
```
"""
keys_type(::T) where {T} = keys_type(T)
keys_type(::Type{T}) where {T} = OneTo{Int}  # default for things is usually LinearIndices{1}
keys_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Ks

"""
    axes_keys(x)

Returns the keys corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)))
(2:3, 3:4)

julia> axes_keys(Axis(1:2))
(1:2,)
```
"""
axes_keys(x) = map(keys, axes(x))
axes_keys(x::AbstractAxis) = (keys(x),)

"""
    axes_keys(x, i)

Returns the axis keys corresponding of ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisIndicesArray(ones(2,2), (2:3, 3:4)), 1)
2:3
```
"""
axes_keys(x, i) = axes_keys(x)[i]

"""
    keys_type(x, i)

Retrieves axis keys of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys_type(AxisIndicesArray([1], ["a"]), 1)
Array{String,1}
```
"""
keys_type(::T, i) where {T} = keys_type(T, i)
keys_type(::Type{T}, i) where {T} = keys_type(axes_type(T, i))

