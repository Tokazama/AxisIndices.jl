

# TODO robust checking of indices should happen at this level
# FIXME this needs to check that all axs are AbstractAxis
function AxisArray{T,N,P,A}(p::P, axs::A) where {T,N,P,A}
    for i in OneTo(N)
        check_axis_length(axs[i], axes(p, i))
    end
    return _AxisArray(p, axs)
end

###
### AxisArray{T,N,P}
###
function AxisArray{T,N,P}(x::P, axs::Tuple) where {T,N,P<:AbstractArray{T,N}}
    axs = compose_axes(axs, x)
    return _AxisArray(x, axs)
end

AxisArray{T,N,P}(A::AxisArray{T,N,P}) where {T,N,P} = A

AxisArray{T,N,P}(A::AbstractArray, args...) where {T,N,P} = AxisArray{T,N,P}(A, args)

function AxisArray{T,N,P}(A::AxisArray; kwargs...) where {T,N,P}
    return AxisArray{T,N,P}(convert(P, parent(A)), axes(A); kwargs...)
end

function AxisArray{T,N,P}(x::AbstractArray, axs::Tuple) where {T,N,P}
    return AxisArray{T,N,P}(convert(P, x), axs)
end

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
function AxisArray{T,N}(A::AbstractArray, ks::Tuple) where {T,N}
    if eltype(A) <: T
        axs = compose_axes(ks, A)
        return _AxisArray(p, axs)
    else
        p = AbstractArray{T}(A)
        axs = compose_axes(ks, p)
        return _AxisArray(p, axs)
    end
end
function AxisArray{T,N}(x::AbstractArray{T,N}, axs::Tuple) where {T,N}
    axs = compose_axes(axs, x)
    return _AxisArray(x, axs)
end
function AxisArray{T,N}(A::AxisArray, ks::Tuple) where {T,N}
    if eltype(A) <: T
        axs = compose_axes(ks, A)
        return _AxisArray(p, axs)
    else
        p = AbstractArray{T}(parent(A))
        axs = compose_axes(ks, A)
        return _AxisArray(p, axs)
    end
end
function AxisArray{T,N}(init::ArrayInitializer, args...; kwargs...) where {T,N}
    return AxisArray{T,N}(init, args; kwargs...)
end
AxisArray{T,N}(x::AbstractArray, args...) where {T,N} = AxisArray{T,N}(x, args)
function AxisArray{T,N}(init::ArrayInitializer, ks::Tuple{Vararg{<:Any,N}}) where {T,N}
    axs = map(compose_axis, ks)
    p = init_array(T, init, axs)
    return _AxisArray(p, axs)
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
function AxisArray{T}(x::AbstractArray, axs::Tuple) where {T}
    return AxisArray{T,ndims(x)}(x, axs)
end
function AxisArray{T}(x::AbstractArray, axs::Vararg) where {T}
    return AxisArray{T,ndims(x)}(x, axs)
end
function AxisArray{T}(init::ArrayInitializer, axs::Tuple) where {T}
    return AxisArray{T,length(axs)}(init, axs)
end
function AxisArray{T}(init::ArrayInitializer, axs::Vararg) where {T}
    return AxisArray{T,length(axs)}(init, axs)
end

"""
    AxisArray(parent::AbstractArray, axes::Tuple)

Construct an `AxisArray` using `parent` and explicit subtypes of `AbstractAxis`.
If `check_length` is `true` then each dimension of parent's length is checked to match
the length of the corresponding axis (e.g., `size(parent 1) == length(axes[1])`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(2,2), (SimpleAxis(2), SimpleAxis(2)))
2×2 AxisArray(::Array{Float64,2}
  • axes:
     1 = 1:2
     2 = 1:2
)
     1    2
  1  1.0  1.0
  2  1.0  1.0

julia> AxisArray(ones(2,2), (["a", "b"], ["one", "two"]))
2×2 AxisArray(::Array{Float64,2}
  • axes:
     1 = ["a", "b"]
     2 = ["one", "two"]
)
       "one"   "two"
  "a"  1.0     1.0
  "b"  1.0     1.0

```
"""
function AxisArray(x::AbstractArray{T,N}, ks::Tuple) where {T,N}
    axs = compose_axes(ks, x)
    return _AxisArray(x, axs)
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

const AxisMatrix{T,P<:AbstractMatrix{T},Ax1,Ax2} = AxisArray{T,2,P,Tuple{Ax1,Ax2}}

"""
    AxisVector

A vector whose indices have keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisVector([1, 2], [:a, :b])
2-element AxisArray(::Vector{Int64}
  • axes:
     1 = [:a, :b]
)
      1
  :a  1
  :b  2  

```
"""
const AxisVector{T,P<:AbstractVector{T},Ax} = AxisArray{T,1,P,Tuple{Ax}}

function AxisVector{T}(x::AbstractVector{T}, ks::AbstractVector) where {T}
    axis = Axis(ks, axes(x, 1))
    return AxisArray{T,1,typeof(x),Tuple{typeof(axis)}}(x, (axis,))
end

AxisVector(x::AbstractVector{T}, ks::AbstractVector) where {T} = AxisVector{T}(x, ks)

AxisVector(x::AbstractVector) = AxisArray(x)

AxisVector{T}() where {T} = _AxisArray(T[], (SimpleAxis(DynamicAxis(0)),))

function initialize_axis_array(data, axs)
    return unsafe_initialize(
        AxisArray{eltype(data),ndims(data),typeof(data),typeof(axs)},
        (data, axs)
    )
end
@inline function ArrayInterface.can_change_size(::Type{T}) where {D,Axs,T<:AxisArray{<:Any,<:Any,D,Axs}}
    if can_change_size(D)
        return _can_change_axes_size(Axs)
    else
        return false
    end
end
ArrayInterface.can_setindex(::Type{T}) where {T<:AxisArray} = can_setindex(parent_type(T))

@generated function _can_change_axes_size(::Type{T}) where {T<:Tuple}
    for i in T.parameters
        can_change_size(i) && return true
    end
    return false
end

Base.parentindices(x::AxisArray) = parentindices(parent(x))

Base.length(x::AxisArray) = prod(size(x))
@generated function ArrayInterface.known_length(::Type{T}) where {Axs,T<:AxisArray{<:Any,<:Any,<:Any,Axs}}
    out = 1
    for axis in Axs.parameters
        known_length(axis) === nothing && return nothing
        out = out * known_length(axis)
    end
    return out
end

Base.size(x::AxisArray) = map(static_length, axes(x))

@inline function Base.axes(x::AxisArray, i::Integer)
    if i < 1
        error("BoundsError: attempt to access $(typeof(x)) at dimension $i")
    else
        return unsafe_axes(axes(x), i)
    end
end

@inline unsafe_axes(axs::Tuple, ::StaticInt{I}) where {I} = unsafe_axes(axs, I)
@inline function unsafe_axes(axs::Tuple, i)
    if i > length(axs)
        return SimpleAxis(1)
    else
        return getfield(axs, i)
    end
end

Base.eachindex(A::AxisArray) = eachindex(IndexStyle(A), A)

Base.eachindex(::IndexCartesian, A::AxisArray{T,N}) where {T,N} = CartesianIndices(axes(A))
function Base.eachindex(S::IndexLinear, A::AxisArray{T,N}) where {T,N}
    if N === 1
        return axes(A, 1)
    else
        return compose_axis(eachindex(S, parent(A)))
    end
end


Base.eachindex(A::AxisArray{T,1}) where {T} = axes(A, 1)

function ArrayInterface.unsafe_reconstruct(A::AxisArray, data; axes=nothing, kwargs...)
    return _unsafe_reconstruct(A, data, axes)
end

# TODO function _unsafe_reconstruct(A, data, ::Nothing) end
_unsafe_reconstruct(A, data, axs) = _AxisArray(data, axs)


###
### getindex
###
# other methods in padded_axis.jl
# function ArrayInterface.unsafe_get_collection(A::AxisArray, inds)
    # return @inbounds(getindex(parent(A), inds...))
# end

function ArrayInterface.unsafe_set_element!(A::AxisArray, value, inds)
    return @inbounds(setindex!(parent(A), value, inds...))
end

_filter_pad(inds::Tuple{I,Vararg}) where {I<:Function} = first(inds)
@inline _filter_pad(inds::Tuple{<:Integer,Vararg}) = _filter_pad(tail(inds))

###
### SubArray
###
#=
@propagate_inbounds function Base.getindex(A::SubArray{T,N,<:AxisArray{T,N}}, args...) where {T,N}
    return ArrayInterface.getindex(A, args...)
end
@propagate_inbounds function Base.getindex(A::SubArray{T,N,<:AxisArray{T,N}}, args::Vararg{Int,N}) where {T,N}
    return ArrayInterface.getindex(A, args...)
end

function ArrayInterface.unsafe_set_element!(A::AxisArray, value, inds)
    return @inbounds(setindex!(parent(A), value, apply_offsets(A, inds)...))
end

=#
@inline function ArrayInterface.to_axes(A::AxisArray, inds::Tuple)
    if ndims(A) === 1
        return (to_axis(axes(A, 1), first(inds)),)
    elseif ArrayInterface.is_linear_indexing(A, inds)
        return (to_axis(eachindex(IndexLinear(), A), first(inds)),)
    else
        return to_axes(A, axes(A), inds)
    end
end

Base.IndexStyle(::Type{T}) where {T<:AxisArray} = _index_style(IndexStyle(parent_type(T)), T)
_index_style(::IndexLinear, ::Type{T}) where {T} = is_cartesian_style((has_cartesian_axis(T, Static.nstatic(Val(ndims(T))))))
_index_style(::IndexCartesian, ::Type{T}) where {T} = IndexCartesian()

is_cartesian_style(::True) = IndexCartesian()
is_cartesian_style(::False) = IndexLinear()


is_cartesian_axis(::Type{T}) where {T} = has_pads(T)
has_cartesian_axis(::Type{T}, d::Tuple{}) where {T} = static(false)
function has_cartesian_axis(::Type{T}, d::Tuple{StaticInt{N},Vararg{Any}}) where {T,N}
    return has_cartesian_axis(is_cartesian_axis(axes_types(T, static(N))), T, tail(d))
end
has_cartesian_axis(::True, ::Type{T}, d::Tuple) where {T} = static(true)
has_cartesian_axis(::True, ::Type{T}, d::Tuple{}) where {T} = static(true)
has_cartesian_axis(::False, ::Type{T}, d::Tuple) where {T} = has_cartesian_axis(T, d)
has_cartesian_axis(::False, ::Type{T}, d::Tuple{}) where {T} = static(false)

# TODO this needs to implement the base elements of stridelayout.jl
ArrayInterface.strides(x::AxisArray) = ArrayInterface.strides(parent(x))

ArrayInterface.offsets(x::AxisArray) = map(offset1, axes(x))

###############
### similar ###
###############
_new_axis_length(x::Integer) = x
_new_axis_length(x::AbstractUnitRange) = length(x)

const DimAxes = Union{AbstractVector,Integer}

# see this https://github.com/JuliaLang/julia/blob/33573eca1107531b3b33e8d20c08ef6db81c9f41/base/abstractarray.jl#L737 comment
# for why we do this type piracy
function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{AbstractUnitRange}) where {T}
    p = similar(a, T, (length(first(dims)),))
    return initialize_axis_array(p, (similar_axis(axes(p, 1), first(dims)),))
end
function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{DimAxes, Vararg{DimAxes,N}}) where {T,N}
    p = similar(a, T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Union{Integer, Base.OneTo}}) where {T}
    p = similar(parent(a), T, (length(first(dims)),))
    return initialize_axis_array(p,  (similar_axis(axes(p, 1), first(dims)),))
end
function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{AbstractUnitRange}) where {T}
    p = similar(parent(a), T, (length(first(dims)),))
    return initialize_axis_array(p,  (similar_axis(axes(p, 1), first(dims)),))
end

function Base.similar(
    a::AxisArray,
    ::Type{T},
    dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo},N}}
) where {T,N}
    p = similar(parent(a), T, map(_new_axis_length, dims))
    return _AxisArray(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{DimAxes, Vararg{DimAxes,N}}) where {T,N}
    p = similar(parent(a), T, map(_new_axis_length, dims))
    return _AxisArray(p, map(similar_axis, axes(p), dims))
end

function Base.similar(::Type{T}, dims::Tuple{DimAxes, Vararg{DimAxes}}) where {T<:AbstractArray}
    p = similar(T, map(_new_axis_length, dims))
    return initialize_axis_array(p, map(similar_axis, axes(p), dims))
end

function Base.similar(::Type{T}, dims::Tuple{DimAxes}) where {T<:AbstractArray}
    p = similar(T, map(_new_axis_length, dims))
    return _AxisArray(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Vararg{Int64, N}}) where {T,N}
    p = similar(parent(a), T, map(_new_axis_length, dims))
    return _AxisArray(p, map(similar_axis, axes(p), dims))
end

function Base.similar(a::AxisArray, ::Type{T}) where {T}
    return _AxisArray(similar(parent(a), T, size(a)), axes(a))
end

#=
function Base.similar(
    ::Type{T},
    dims::Tuple{Union{Integer, AbstractUnitRange}, Vararg{Union{Integer, AbstractUnitRange}}}
) where {T<:AxisArray}

    p = similar(parent_type(T), map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
function Base.similar(
    ::Type{T},
    dims::Tuple{Union{Integer, AbstractUnitRange}}
) where {T<:AxisArray}

    p = similar(parent_type(T), map(_new_axis_length, dims))
    axs = map(similar_axis, axes(p), dims)
    return _unsafe_axis_array(p, axs)
end
=#

