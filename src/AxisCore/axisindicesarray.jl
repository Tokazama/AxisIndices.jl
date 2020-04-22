
"""
    AxisIndicesArray{T,N,P,AI}

An array struct that wraps any parent array and assigns it an `AbstractAxis` for
each dimension. The first argument is the parent array and the second argument is
a tuple of subtypes to `AbstractAxis` or keys that will be converted to subtypes
of `AbstractAxis` with the provided keys.
"""
struct AxisIndicesArray{T,N,P<:AbstractArray{T,N},AI<:AbstractAxes{N}} <: AbstractAxisIndices{T,N,P,AI}
    "The parent array."
    parent::P
    "The axes for each dimension of the parent array."
    axes::AI

    function AxisIndicesArray{T,N,P,A}(p::P, axs::A) where {T,N,P,A}
       return new{T,N,P,A}(p, axs)
    end
end

Base.parent(x::AxisIndicesArray) = getfield(x, :parent)

Base.axes(x::AxisIndicesArray) = getfield(x, :axes)

function StaticRanges.similar_type(
    ::AxisIndicesArray{T,N,P,AI},
    parent_type::Type=P,
    axes_type::Type=AI
) where {T,N,P,AI}

    return AxisIndicesArray{eltype(parent_type), ndims(parent_type), parent_type, axes_type}
end

"""
    AxisIndicesArray(parent::AbstractArray, axes::Tuple{Vararg{AbstractAxis}}[, check_length=true])

Construct an `AxisIndicesArray` using `parent` and explicit subtypes of `AbstractAxis`.
If `check_length` is `true` then each dimension of parent's length is checked to match
the length of the corresponding axis (e.g., `size(parent 1) == length(axes[1])`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndicesArray(ones(2,2), (SimpleAxis(2), SimpleAxis(2)))
AxisIndicesArray{Float64,2,Array{Float64,2}...}
 • dim_1 - SimpleAxis(Base.OneTo(2))
 • dim_2 - SimpleAxis(Base.OneTo(2))
        1     2
  1   1.0   1.0
  2   1.0   1.0


```
"""
function AxisIndicesArray(
    x::AbstractArray{T,N},
    axs::AbstractAxes{N},
    check_length::Bool=true
) where {T,N}

    if check_length
        for i in 1:N
            check_axis_length(getfield(axs, i), axes(x, i))
        end
    end
    return AxisIndicesArray{T,N,typeof(x),typeof(axs)}(x, axs)
end

"""
    AxisIndicesArray(parent::AbstractArray, keys::Tuple[, values=axes(parent), check_length=true])

Given an the some array `parent` and a tuple of vectors `keys` corresponding to
each dimension of `parent` constructs an `AxisIndicesArray`. Each element of `keys`
is paired with an element of `values` to compose a subtype of `AbstractAxis`.
`values` map the `keys` to the indices of `parent`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndicesArray(ones(2,2), (["a", "b"], ["one", "two"]))
AxisIndicesArray{Float64,2,Array{Float64,2}...}
 • dim_1 - Axis(["a", "b"] => Base.OneTo(2))
 • dim_2 - Axis(["one", "two"] => Base.OneTo(2))
      one   two
  a   1.0   1.0
  b   1.0   1.0


```
"""
function AxisIndicesArray(
    x::AbstractArray{T,N},
    axis_keys::Tuple,
    axis_values::Tuple=axes(x),
    check_length::Bool=true
) where {T,N}

    axs = similar_axes((), axis_keys, axis_values, check_length)
    return AxisIndicesArray{T,N,typeof(x),typeof(axs)}(x, axs)
end

"""
    AxisIndicesArray(parent::AbstractArray, args...) -> AxisIndicesArray(parent, tuple(args))

Passes `args` to a tuple for constructing an `AxisIndicesArray`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = AxisIndicesArray(reshape(1:9, 3,3), 2:4, 3.0:5.0);

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
AxisIndicesArray(x::AbstractArray, args...) = AxisIndicesArray(x, args)

# Vector is uniquely dynamic and its size is mutable
function AxisIndicesArray(x::Vector)
    return AxisIndicesArray(x, (SimpleAxis(as_dynamic(axes(x, 1))),), false)
end

function AxisIndicesArray(x::Vector{T}, axis_keys::AbstractAxis, check_length::Bool=true) where {T}
    return AxisIndicesArray(x, (axis_keys,), check_length)
end

function AxisIndicesArray(x::Vector{T}, axis_keys::AbstractVector, check_length::Bool=true) where {T}
    return AxisIndicesArray(x, (axis_keys,), (as_dynamic(axes(x, 1)),), check_length)
end

function AxisIndicesArray(x::Vector{T}, axis_keys::Tuple, check_length::Bool=true) where {T}
    return AxisIndicesArray(x, (first(axis_keys),), (as_dynamic(axes(x, 1)),), check_length)
end


function AxisIndicesArray(x::Vector{T}, axs::AbstractAxes{1}, check_length::Bool=true) where {T}
    if check_length
        check_axis_length(first(axs), axes(x, 1))
    end
    return AxisIndicesArray{T,1,Vector{T},typeof(axs)}(x, axs)
end

