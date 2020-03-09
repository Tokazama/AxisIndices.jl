# These are base module methods that simply need to swap/drop axes positions

"""
    permute_axes(x::AbstractArray, p::Tuple) = permute_axes(axes(x), p)
    permute_axes(x::NTuple{N}, p::NTuple{N}) -> NTuple{N}

Returns axes of `x` in the order of `p`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.permute_axes(rand(2, 4, 6), (1, 3, 2))
(Base.OneTo(2), Base.OneTo(6), Base.OneTo(4))

julia> AxisIndices.permute_axes((Axis(1:2), Axis(1:4), Axis(1:6)), (1, 3, 2))
(Axis(1:2 => Base.OneTo(2)), Axis(1:6 => Base.OneTo(6)), Axis(1:4 => Base.OneTo(4)))
```
"""
permute_axes(x::AbstractArray{T,N}, p) where {T,N} = permute_axes(axes(x), p)
function permute_axes(x::NTuple{N,Any}, p::AbstractVector{<:Integer}) where {N}
    return Tuple(map(i -> getindex(x, i), p))
end
permute_axes(x::NTuple{N,Any}, p::NTuple{N,<:Integer}) where {N} = map(i -> getfield(x, i), p)

"""
    permute_axes(x::AbstractVector)

Returns the permuted axes of `x` as axes of size 1 × length(x)

## Examples
```jldoctest
julia> using AxisIndices

julia> length.(AxisIndices.permute_axes(rand(4))) == (1, 4)
true

julia> AxisIndices.permute_axes((Axis(1:4),))
(SimpleAxis(Base.OneTo(1)), Axis(1:4 => Base.OneTo(4)))

julia> AxisIndices.permute_axes((Axis(mrange(1, 4)),))
(SimpleAxis(OneToMRange(1)), Axis(UnitMRange(1:4) => OneToMRange(4)))

julia> AxisIndices.permute_axes((Axis(srange(1, 4)),))
(SimpleAxis(OneToSRange(1)), Axis(UnitSRange(1:4) => OneToSRange(4)))
```
"""
permute_axes(x::AbstractVector) = permute_axes(axes(x))
function permute_axes(x::Tuple{Ax}) where {Ax<:AbstractUnitRange}
    if is_static(Ax)
        return (SimpleAxis(OneToSRange(1)), first(x))
    elseif is_fixed(Ax)
        return (SimpleAxis(Base.OneTo(1)), first(x))
    else  # is_dynamic(Ax)
        return (SimpleAxis(OneToMRange(1)), first(x))
    end
end

"""
    permute_axes(m::AbstractMatrix) -> NTuple{2}

Permute the axes of the matrix `m`, by flipping the elements across the diagonal
of the matrix. Differs from LinearAlgebra's transpose in that the operation is
not recursive.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.permute_axes(rand(4, 2))
(Base.OneTo(2), Base.OneTo(4))

julia> AxisIndices.permute_axes((Axis(1:4), Axis(1:2)))
(Axis(1:2 => Base.OneTo(2)), Axis(1:4 => Base.OneTo(4)))
```
"""
permute_axes(x::AbstractMatrix) = permute_axes(axes(x))
permute_axes(x::NTuple{2,Any}) = (last(x), first(x))

function Base.permutedims(a::AbstractAxisIndices, perm)
    return reconstruct(a, permutedims(parent(a), perm), permute_axes(a, perm))
end

#Base.selectdim(a::AbstractAxisIndices, d::Integer, i) = selectdim(a, d, i)

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv))
    # Vector
    @eval function $f(a::AbstractAxisIndices{T,1}) where {T}
        return reconstruct(a, $f(parent(a)), permute_axes(a))
    end

    # Vector Double Transpose
    if f != :(Base.permutedims)
        # TODO fix CoVector
        @eval function $f(a::AbstractAxisIndices{T,2,A}) where {T,A<:CoVector}
            return reconstruct(a, $f(parent(a)), (axes(a, 2),))
        end
    end

    # Matrix
    @eval function $f(a::AbstractAxisIndices{T,2}) where {T}
        return reconstruct(a, $f(parent(a)), permute_axes(a))
    end
end

"""
    covcor_axes(x, dim) -> NTuple{2}

Returns appropriate axes for a `cov` or `var` method on array `x`.

## Examples
```jldoctest covcor_axes_examples
julia> using AxisIndices

julia> AxisIndices.covcor_axes(rand(2,4), 1)
(Base.OneTo(4), Base.OneTo(4))

julia> AxisIndices.covcor_axes((Axis(1:4), Axis(1:6)), 2)
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> AxisIndices.covcor_axes((Axis(1:4), Axis(1:4)), 1)
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))
```

Each axis is resized to equal to the smallest sized dimension if given a dimensional
argument greater than 2.
```jldoctest covcor_axes_examples
julia> AxisIndices.covcor_axes((Axis(2:4), Axis(3:4)), 3)
(Axis(3:4 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))
```
"""
covcor_axes(x::AbstractMatrix, dim::Int) = covcor_axes(axes(x), dim)
function covcor_axes(x::NTuple{2,Any}, dim::Int)
    if dim === 1
        return (last(x), last(x))
    elseif dim === 2
        return (first(x), first(x))
    else
        ax = diagonal_axes(x)
        return (ax, ax)
    end
end

for fun in (:cor, :cov)
    @eval function Statistics.$fun(a::AbstractAxisIndices{T,2}; dims=1, kwargs...) where {T}
        return reconstruct(
            a,
            Statistics.$fun(parent(a); dims=dims, kwargs...),
            covcor_axes(a, dims)
        )
    end
end

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
drop_axes(x::AbstractArray, dims) = drop_axes(axes(x), dims)
drop_axes(x::Tuple{Vararg{<:Any}}, dims::Int) = drop_axes(x, (dims,))
function drop_axes(x::Tuple{Vararg{<:Any,D}}, dims::NTuple{N,Int}) where {D,N}
    for i in 1:N
        1 <= dims[i] <= D || throw(ArgumentError("dropped dims must be in range 1:ndims(A)"))
        for j = 1:i-1
            dims[j] == dims[i] && throw(ArgumentError("dropped dims must be unique"))
        end
    end
    d = ()
    for (i,axis_i) in zip(1:D,x)
        if !in(i, dims)
            d = tuple(d..., axis_i)
        end
    end
    return d
end

function Base.dropdims(a::AxisIndicesArray; dims)
    return reconstruct(a, dropdims(parent(a); dims=dims), drop_axes(a, dims))
end

# reshape
# For now we only implement the version that drops dimension names
# TODO
#Base.reshape(ia::AbstractAxisIndices, d::Vararg{Union{Colon, Int}}) = reshape(parent(ia), d)



