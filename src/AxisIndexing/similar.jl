
function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
) where {A<:AbstractAxis}

    return similar_type(A, ks_type, vs_type)
end

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
) where {A<:AbstractSimpleAxis}

    return similar_type(A, vs_type)
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two])
Axis([:one, :two] => 1:2)
```
"""
function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}
    return similar(axis, new_keys, set_length(values(axis), length(new_keys)), false)
end

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractUnitRange{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}
    return similar(axis, new_keys, set_length(values(axis), length(new_keys)), false)
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector, new_indices::AbstractUnitRange{Integer} [, check_length::Bool=true] ) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`
and indices `new_indices`. If `check_length` is `true` then the lengths of `new_keys`
and `new_indices` are checked to ensure they have the same length before construction.

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(2))
Axis([:one, :two] => 0x0000000000000001:0x0000000000000002)

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(3))
ERROR: keys and indices must have same length, got length(keys) = 2 and length(indices) = 3.
[...]
```
"""
function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    check_length && check_axis_length(new_keys, new_indices)
    return unsafe_reconstruct(axis, new_keys, new_indices)
end

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractUnitRange{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T<:Integer}

    check_length && check_axis_length(new_keys, new_indices)
    return unsafe_reconstruct(axis, new_keys, new_indices)
end
"""
    similar(axis::AbstractSimpleAxis, new_indices::AbstractUnitRange{Integer}) -> AbstractSimpleAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(SimpleAxis(1:10), 1:3)
SimpleAxis(1:3)
```
"""
function Base.similar(
    axis::AbstractSimpleAxis{V,Vs},
    new_keys::AbstractUnitRange{<:Integer}
) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return unsafe_reconstruct(axis, new_keys)
end

#=
We assume that if the user provide a subtype of AbstractAxis as the keys argument
that they intended to fully replace the corresponding axis with the new type
=#
function similarish(axis::AbstractSimpleAxis, new_keys, new_indices, check_length::Bool)
    return similar(axis, new_keys)
end

function similarish(axis::AbstractAxis, new_keys, new_indices, check_length::Bool)
    return similar(axis, new_keys, new_indices, check_length)
end
similarish(axis::AbstractSimpleAxis, new_keys::AbstractAxis, new_indices, check_length::Bool) = new_keys
similarish(axis::AbstractAxis, new_keys::AbstractAxis, new_indices, check_length::Bool) = new_keys
similarish(new_keys::AbstractAxis, new_indices, check_length::Bool) = new_keys
similarish(new_keys, new_indices, check_length::Bool) = to_axis(new_keys, new_indices, check_length)
similarish(new_keys) = to_axis(new_keys)

# similar_axes iterates over old axes and new indices with provided keys to try
# to reach an agreement
function similar_axes(old_axes::Tuple, new_keys::Tuple, new_indices::Tuple, check_length::Bool=true)
    return (similarish(first(old_axes), first(new_keys), first(new_indices), check_length),
            similar_axes(tail(old_axes), tail(new_keys), tail(new_indices), check_length)...)
end

function similar_axes(old_axes::Tuple{}, new_keys::Tuple, new_indices::Tuple, check_length::Bool=true)
    return (similarish(first(new_keys), first(new_indices), check_length),
            similar_axes((), tail(new_keys), tail(new_indices), check_length)...)
end

function similar_axes(old_axes::Tuple{}, new_keys::Tuple{}, new_indices::Tuple, check_length::Bool=true)
    return (similarish(first(new_indices)), similar_axes((), (), tail(new_indices), check_length)...)
end

similar_axes(::Tuple{}, ::Tuple{}, ::Tuple{}, check_length::Bool) = ()
similar_axes(::Tuple, ::Tuple{}, ::Tuple{}, check_length::Bool) = ()

