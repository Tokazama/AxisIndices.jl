
"""
    is_indices_axis(x) -> Bool

If `true` then `x` is an axis type where the only field parameterizing the axis
is a field for the values.
"""
is_indices_axis(x) = is_indices_axis(typeof(x))
is_indices_axis(::Type{T}) where {T<:AbstractUnitRange{<:Integer}} = true
is_indices_axis(::Type{T}) where {T} = false

"""
    metadata(x)

Returns metadata for `x`.
"""
metadata(x::AbstractUnitRange) = nothing

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
    rowaxis(x) -> axis

Returns the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowaxis(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis(["a", "b"] => Base.OneTo(2))

```
"""
rowaxis(x) = axes(x, 1)

"""
    rowkeys(x) -> axis

Returns the keys corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowkeys(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{String,1}:
 "a"
 "b"

```
"""
rowkeys(x) = keys(axes(x, 1))

"""
    rowtype(x)

Returns the type of the axis corresponding to the first dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> rowtype(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{String,Int64,Array{String,1},Base.OneTo{Int64}}
```
"""
rowtype(::T) where {T} = rowtype(T)
rowtype(::Type{T}) where {T} = axes_type(T, 1)

"""
    colaxis(x) -> axis

Returns the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> colaxis(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis([:one, :two] => Base.OneTo(2))

```
"""
colaxis(x) = axes(x, 2)

"""
    coltype(x)

Returns the type of the axis corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> coltype(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
Axis{Symbol,Int64,Array{Symbol,1},Base.OneTo{Int64}}
```
"""
coltype(::T) where {T} = coltype(T)
coltype(::Type{T}) where {T} = axes_type(T, 2)

"""
    colkeys(x) -> axis

Returns the keys corresponding to the second dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> colkeys(AxisArray(ones(2,2), ["a", "b"], [:one, :two]))
2-element Array{Symbol,1}:
 :one
 :two

```
"""
colkeys(x) = keys(axes(x, 2))

"""
    first_key(x)

Returns the first key of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> first_key(Axis(2:10))
2
```
"""
first_key(x) = first(keys(x))

"""
    last_key(x)

Returns the last key of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> last_key(Axis(2:10))
10
```
"""
last_key(x) = last(keys(x))

"""
    step_key(x)

Returns the step size of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.step_key(Axis(1:2:10))
2

julia> AxisIndices.step_key(rand(2))
1

julia> AxisIndices.step_key([1])  # LinearIndices are treate like unit ranges
1
```
"""
@inline step_key(x::AbstractVector) = _step_keys(keys(x))
_step_keys(ks) = step(ks)
_step_keys(ks::LinearIndices) = 1

"""
    unsafe_reconstruct(axis, keys, indices)

Reconstructs an `AbstractAxis` of the same type as `axis` but with keys of type `Ks` and values of type `Vs`.
This method is considered unsafe because it bypasses checks  to ensure that `keys` and `values` have the same length and the all `keys` are unique.
"""
function unsafe_reconstruct(axis, ks, vs)
    if is_indices_axis(axis)
        return similar_type(axis, typeof(vs))(vs)
    else
        return similar_type(axis, typeof(ks), typeof(vs))(ks, vs)
    end
end

"""
    unsafe_reconstruct(axis, indices)

Reconstructs an `AbstractSimpleAxis` of the same type as `axis` but values of type `Vs`.
"""
function unsafe_reconstruct(axis, vs)
    if is_indices_axis(axis)
        return similar_type(axis, typeof(vs))(vs)
    else
        return unsafe_reconstruct(axis, vs, vs)
    end
end

"""
    axes_keys(x) -> Tuple

Returns the keys corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisArray(ones(2,2), (2:3, 3:4)))
(2:3, 3:4)

julia> axes_keys(Axis(1:2))
(1:2,)
```
"""
axes_keys(x) = map(keys, axes(x))
axes_keys(x::AbstractUnitRange) = (keys(x),)

"""
    axes_keys(x, i)

Returns the axis keys corresponding of ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axes_keys(AxisArray(ones(2,2), (2:3, 3:4)), 1)
2:3
```
"""
axes_keys(x, i) = axes_keys(x)[i]  # FIXME this needs to be changed to support named dimensions

"""
    keys_type(x, i)

Retrieves axis keys of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> keys_type(AxisArray([1], ["a"]), 1)
Array{String,1}
```
"""
keys_type(::T, i) where {T} = keys_type(T, i)
keys_type(::Type{T}, i) where {T} = keys_type(axes_type(T, i))

"""
    indices_type(x, i)

Retrieves axis values of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices_type([1], 1)
Base.OneTo{Int64}

julia> indices_type(typeof([1]), 1)
Base.OneTo{Int64}
```
"""
indices_type(::T, i) where {T} = indices_type(T, i)
indices_type(::Type{T}, i) where {T} = indices_type(axes_type(T, i))

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

"""
    indices(x::AbstractUnitRange)

Returns the indices `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x::AbstractUnitRange) = values(x)
indices(x::CartesianIndex) = getfield(x, :I)

"""
    indices(x, i)

Returns the indices corresponding to the `i` axis

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisArray(ones(2,2), (2:3, 3:4)), 1)
Base.OneTo(2)
```
"""
indices(x, i) = values(axes(x, i))

"""
    indices(x) -> Tuple

Returns the indices corresponding to all axes of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> indices(AxisArray(ones(2,2), (2:3, 3:4)))
(Base.OneTo(2), Base.OneTo(2))

julia> indices(Axis(["a"], 1:1))
1:1

julia> indices(CartesianIndex(1,1))
(1, 1)

```
"""
indices(x) = map(values, axes(x))

# TODO this should be indices_type
"""
    indices_type(x)

Retrieves the type of the values of `x`. This should be functionally equivalent
to `typeof(values(x))`.

## Examples
```jldoctest
julia> using AxisIndices

julia>  indices_type(Axis(1:2))
Base.OneTo{Int64}

julia> indices_type(typeof(Axis(1:2)))
Base.OneTo{Int64}

julia> indices_type(typeof(1:2))
UnitRange{Int64}
```
"""
indices_type(::T) where {T} = indices_type(T)
# if it's not a subtype of AbstractAxis assume it is the collection of values
indices_type(::Type{T}) where {T} = T  


# FIXME this explanation is confusing.
"""
    axis_eltype(x)

Returns the type corresponds to the type of the ith element returned when slicing
along that dimension.
"""
axis_eltype(axis, i) = Any

# TODO document
axis_eltypes(axis) = Tuple{[axis_eltype(axis, i) for i in axis]...}
@inline axis_eltypes(axis, vs::AbstractVector) = Tuple{map(i -> axis_eltype(axis, i), vs)...}

"""
    drop_axes(x, dims)

Returns all axes of `x` except for those identified by `dims`. Elements of `dims`
must be unique integers or symbols corresponding to the dimensions or names of
dimensions of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> axs = (Axis(1:5), Axis(1:10));

julia> AxisIndices.drop_axes(axs, 1)
(Axis(1:10 => Base.OneTo(10)),)

julia> AxisIndices.drop_axes(axs, 2)
(Axis(1:5 => Base.OneTo(5)),)

julia> AxisIndices.drop_axes(rand(2, 4), 2)
(Base.OneTo(2),)
```
"""
drop_axes(x::AbstractArray, d::Int) = drop_axes(x, (d,))
drop_axes(x::AbstractArray, d::Tuple) = drop_axes(x, dims(dimnames(x), d))
drop_axes(x::AbstractArray, d::Tuple{Vararg{Int}}) = drop_axes(axes(x), d)
drop_axes(x::Tuple{Vararg{<:Any}}, d::Int) = drop_axes(x, (d,))
drop_axes(x::Tuple{Vararg{<:Any}}, d::Tuple) = _drop_axes(x, d)
_drop_axes(x, y) = select_axes(x, dropinds(x, y))

dropinds(x, y) = _dropinds(x, y)
Base.@pure @inline function _dropinds(x::Tuple{Vararg{Any,N}}, dims::NTuple{M,Int}) where {N,M}
    out = ()
    for i in 1:N
        cnd = true
        for j in dims
            if i === j
                cnd = false
                break
            end
        end
        if cnd
            out = (out..., i)
        end
    end
    return out::NTuple{N - M, Int}
end

# TODO document select_axes
select_axes(x::AbstractArray, d::Tuple) = select_axes(x, dims(dimnames(x), d))
select_axes(x::AbstractArray, d::Tuple{Vararg{Int}}) = map(i -> axes(x, i), d)
select_axes(x::Tuple, d::Tuple) = map(i -> getfield(x, i), d)

#=
    print_axis_compactly(io, axis)

Determines how `axis` is printed when above a printed array
=#
print_axis_compactly(io, x) = print(io, x)
print_axis_compactly(io, x::AbstractUnitRange) = print(io, "$(first(x)):$(last(x))")
function print_axis_compactly(io, x::AbstractRange)
    print(io, "$(first(x)):$(step(x)):$(last(x))")
end

function print_axis(io, axis)
    if haskey(io, :compact)
        print_axis_compactly(io, keys(axis))
    else
        if is_indices_axis(axis)
            print(io, "$(typeof(axis).name)($(keys(axis)))")
        else
            print(io, "$(typeof(axis).name)($(keys(axis)) => $(indices(axis)))")
        end
    end
end

