
_to_axis_or_simple(staticness, ::Tuple{}, ::Tuple{}, ::Bool) = ()
_to_axis_or_simple(staticness, ::Tuple, ::Tuple{}, ::Bool) = ()
@inline function _to_axis_or_simple(staticness, ::Tuple{}, inds::Tuple,  ::Bool)
    return map(i -> SimpleAxis(as_staticness(staticness, i)), inds)
end
@inline function _to_axis_or_simple(staticness, ks::Tuple, inds::Tuple,  check_length::Bool)
    return (
        to_axis(as_staticness(staticness, first(ks)), as_staticness(staticness, first(inds)), check_length),
        _to_axis_or_simple(staticness, maybe_tail(ks), maybe_tail(inds), check_length)...
    )
end


"""
    AxisArray{T,N,P,AI}

An array struct that wraps any parent array and assigns it an `AbstractAxis` for
each dimension. The first argument is the parent array and the second argument is
a tuple of subtypes to `AbstractAxis` or keys that will be converted to subtypes
of `AbstractAxis` with the provided keys.
"""
struct AxisArray{T,N,P<:AbstractArray{T,N},AI<:AbstractAxes{N}} <: AbstractAxisArray{T,N,P,AI}
    "The parent array."
    parent::P
    "The axes for each dimension of the parent array."
    axes::AI

    function AxisArray{T,N,P,A}(p::P, axs::A) where {T,N,P,A}
       return new{T,N,P,A}(p, axs)
    end
end

StaticRanges.parent_type(::Type{<:AxisArray{T,N,P,Ax}}) where {T,N,P,Ax} = P

Base.parent(x::AxisArray) = getfield(x, :parent)

Base.axes(x::AxisArray) = getfield(x, :axes)

Metadata.metadata(x::AxisArray) = metadata(parent(x))

function StaticRanges.similar_type(
    ::AxisArray{T,N,P,AI},
    parent_type::Type=P,
    axes_type::Type=AI
) where {T,N,P,AI}

    return AxisArray{eltype(parent_type), ndims(parent_type), parent_type, axes_type}
end

"""
    AxisArray(parent::AbstractArray, axes::Tuple{Vararg{AbstractAxis}}[, check_length=true])

Construct an `AxisArray` using `parent` and explicit subtypes of `AbstractAxis`.
If `check_length` is `true` then each dimension of parent's length is checked to match
the length of the corresponding axis (e.g., `size(parent 1) == length(axes[1])`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(2,2), (SimpleAxis(2), SimpleAxis(2)))
2×2 AxisArray{Float64,2}
 • dim_1 - 1:2
 • dim_2 - 1:2
        1     2
  1   1.0   1.0
  2   1.0   1.0

```
"""
function AxisArray(
    x::AbstractArray{T,N},
    axs::AbstractAxes{N},
    check_length::Bool=true
) where {T,N}

    if check_length
        for i in 1:N
            check_axis_length(getfield(axs, i), axes(x, i))
        end
    end
    return AxisArray{T,N,typeof(x),typeof(axs)}(x, axs)
end

"""
    AxisArray(parent::AbstractArray, keys::Tuple[, values=axes(parent), check_length=true])

Given an the some array `parent` and a tuple of vectors `keys` corresponding to
each dimension of `parent` constructs an `AxisArray`. Each element of `keys`
is paired with an element of `values` to compose a subtype of `AbstractAxis`.
`values` map the `keys` to the indices of `parent`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(2,2), (["a", "b"], ["one", "two"]))
2×2 AxisArray{Float64,2}
 • dim_1 - ["a", "b"]
 • dim_2 - ["one", "two"]
      one   two
  a   1.0   1.0
  b   1.0   1.0

```
"""
function AxisArray(
    x::AbstractArray{T,N},
    axis_keys::Tuple{Vararg{Any,N2}},
    axis_values::Tuple=axes(x),
    check_length::Bool=true
) where {T,N,N2}
    axs = _to_axis_or_simple(Staticness(x), axis_keys, axis_values, check_length)
    return AxisArray{T,N,typeof(x),typeof(axs)}(x, axs)
end

"""
    AxisArray(parent::AbstractArray, args...) -> AxisArray(parent, tuple(args))

Passes `args` to a tuple for constructing an `AxisArray`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = AxisArray(reshape(1:9, 3,3), 2:4, 3.0:5.0);

julia> A[1, 1]
1

julia> A[==(2), ==(3.0)]
1

julia> A[1:2, 1:2] == [1 4; 2 5]
true

julia> A[<(4), <(5.0)] == [1 4; 2 5]
true
```
"""
AxisArray(x::AbstractArray, args...) = AxisArray(x, args)

###
### Vectors: is uniquely dynamic and its size is mutable
###
function AxisArray(x::Vector)
    return AxisArray(x, (SimpleAxis(as_dynamic(axes(x, 1))),), false)
end

function AxisArray(x::Vector{T}, axis_keys::AbstractAxis, check_length::Bool=true) where {T}
    return AxisArray(x, (axis_keys,), check_length)
end

function AxisArray(x::Vector{T}, axis_keys::AbstractVector, check_length::Bool=true) where {T}
    return AxisArray(x, (axis_keys,), (as_dynamic(axes(x, 1)),), check_length)
end

function AxisArray(x::Vector{T}, axis_keys::Tuple, check_length::Bool=true) where {T}
    return AxisArray(x, (first(axis_keys),), (as_dynamic(axes(x, 1)),), check_length)
end

function AxisArray(x::Vector{T}, axis_keys::Tuple{}, check_length::Bool=true) where {T}
    return AxisArray(x)
end

function AxisArray(x::Vector{T}, axs::AbstractAxes{1}, check_length::Bool=true) where {T}
    check_length && check_axis_length(first(axs), axes(x, 1))
    return AxisArray{T,1,Vector{T},typeof(axs)}(x, axs)
end

function AxisArray(x::AbstractArray{T,0}, axs::Tuple{}=(), check_length::Bool=false) where {T}
    return AxisArray{T,0,typeof(x),Tuple{}}(x, ())
end

### AxisArray{T}

"""
    AxisArray{T}(undef, keys::NTuple{N,AbstractVector})

Construct an uninitialized `N`-dimensional array containing elements of type `T` were
the size of each dimension is determined by the length of the corresponding collection
in `keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> size(AxisArray{Int}(undef, (["a", "b"], [:one, :two])))
(2, 2)
```
"""
function AxisArray{T}(x::AbstractArray, axs::Tuple, check_length::Bool=true) where {T}
    return AxisArray{T,ndims(x)}(x, axs, check_length)
end

function AxisArray{T}(init::ArrayInitializer, axs::Tuple) where {T}
    return AxisArray{T,length(axs)}(init, axs)
end

AxisArray{T}(x::AbstractArray, axs::Vararg) where {T} = AxisArray{T,ndims(x)}(x, axs)

function AxisArray{T}(init::ArrayInitializer, axs::Vararg) where {T}
    return AxisArray{T,length(axs)}(init, axs)
end

## AxisArray{T,N}

# TODO fix/clean up these docs
"""
    AxisArray{T,N}(undef, dims::NTuple{N,Integer})
    AxisArray{T,N}(undef, keys::NTuple{N,AbstractVector})

Construct an uninitialized `N`-dimensional array containing elements of type `T` were
the size of each dimension is equal to the corresponding integer in `dims`.

Construct an uninitialized `N`-dimensional array containing elements of type `T` were
the size of each dimension is determined by the length of the corresponding collection
in `keys.


## Examples
```jldoctest
julia> using AxisIndices

julia> size(AxisArray{Int,2}(undef, (2,2)))
(2, 2)

julia> size(AxisArray{Int,2}(undef, (["a", "b"], [:one, :two])))
(2, 2)

"""
function AxisArray{T,N}(A::AbstractArray{T2,N}, axis_keys::Tuple, check_length::Bool=true) where {T,T2,N}
    return AxisArray{T,N}(copyto!(Array{T}(undef, size(A)), A), axis_keys, check_length)
end

function AxisArray{T,N}(init::ArrayInitializer, args...) where {T,N}
    return AxisArray{T,N}(init, args)
end

AxisArray{T,N}(x::AbstractArray, args...) where {T,N} = AxisArray{T,N}(x, args)

function AxisArray{T,N}(init::ArrayInitializer, axs::Tuple{Vararg{Any,N}}) where {T,N}
    return AxisArray{T,N}(init, map(to_axis, axs))
end

function AxisArray{T,N}(init::ArrayInitializer, axs::AbstractAxes{N}) where {T,N}
    p = init_array(StaticRanges._combine(typeof(axs)), T, init, axs)
    return AxisArray{T,N,typeof(p),typeof(axs)}(p, axs)
end

function AxisArray{T,N}(x::AbstractArray{T,N}, axs::Tuple, check_length::Bool=true) where {T,N}
    return AxisArray{T,N,typeof(x)}(x, axs, check_length)
end

###
### AxisArray{T,N,P}
###
AxisArray{T,N,P}(A::AbstractArray, args...) where {T,N,P} = AxisArray{T,N,P}(A, args)

function AxisArray{T,N,P}(
    x::AbstractArray,
    axs::Tuple,
    check_length::Bool=true
) where {T,N,P}

    return AxisArray{T,N,P}(convert(P, x), axs, check_length)
end

function AxisArray{T,N,P}(x::P, axs::Tuple, check_length::Bool=true) where {T,N,P<:AbstractArray{T,N}}
    axs = to_axes((), axs, axes(x), check_length, Staticness(x))
    return AxisArray{T,N,P,typeof(axs)}(x, axs)
end

###
### init_array
###

_length(x::Integer) = x
_length(x) = length(x)

function init_array(::Static, ::Type{T}, init::ArrayInitializer, sz::NTuple{N,Any}) where {T,N}
    return MArray{Tuple{map(_length, sz)...},T,N}(undef)
end

function init_array(::Fixed, ::Type{T}, init::ArrayInitializer, sz::NTuple{N,Any}) where {T,N}
    return Array{T,N}(undef, map(_length, sz))
end

# TODO
# Currently, the only dynamic array we support is Vector, eventually it would be
# nice if we could support >1 dimensions being dynamic
function init_array(::Dynamic, ::Type{T}, init::ArrayInitializer, sz::NTuple{N,Any}) where {T,N}
    return Array{T,N}(undef, map(_length, sz))
end

Base.dataids(A::AxisArray) = Base.dataids(parent(A))

function Base.zeros(::Type{T}, axs::Tuple{Vararg{<:AbstractAxis}}) where {T}
    p = zeros(T, map(length, axs))
    return AxisArray(p, axs, axes(p), false)
end

function Base.falses(axs::Tuple{Vararg{<:AbstractAxis}}) where {T}
    p = falses(map(length, axs))
    return AxisArray(p, axs, axes(p), false)
end

function Base.fill(x, axs::Tuple{Vararg{<:AbstractAxis}})
    p = fill(x, map(length, axs))
    return AxisArray(p, axs, axes(p), false)
end

function Base.reshape(A::AbstractArray, shp::Tuple{<:AbstractAxis,Vararg{<:AbstractAxis}})
    p = reshape(parent(A), map(length, shp))
    axs = reshape_axes(naxes(shp, Val(length(shp))), axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs)
end

AxisArray{T,N,P}(A::AxisArray{T,N,P}) where {T,N,P} = A

function AxisArray{T,N,P}(A::AxisArray) where {T,N,P}
    return AxisArray{T,N,P}(convert(P, parent(A)), axes(A))
end
