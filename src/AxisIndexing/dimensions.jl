
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
@inline drop_axes(x::AbstractArray, dims) = drop_axes(axes(x), dims)
@inline drop_axes(x::Tuple{Vararg{<:Any}}, dims::Int) = drop_axes(x, (dims,))
@inline drop_axes(x::Tuple{Vararg{<:Any}}, dims::Tuple) = _drop_axes(x, dims)
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

select_axes(x::Tuple, dims::NTuple{N,Int}) where {N} = map(i -> getfield(x, i), dims)

"""
    matmul_axes(a, b) -> Tuple

Returns the appropriate axes for the return of `a * b` where `a` and `b` are a
vector or matrix.

## Examples
```jldoctest
julia> using AxisIndices

julia> axs2, axs1 = (Axis(1:2), Axis(1:4)), (Axis(1:6),);

julia> AxisIndices.matmul_axes(axs2, axs2)
(Axis(1:2 => Base.OneTo(2)), Axis(1:4 => Base.OneTo(4)))

julia> AxisIndices.matmul_axes(axs1, axs2)
(Axis(1:6 => Base.OneTo(6)), Axis(1:4 => Base.OneTo(4)))

julia> AxisIndices.matmul_axes(axs2, axs1)
(Axis(1:2 => Base.OneTo(2)),)

julia> AxisIndices.matmul_axes(axs1, axs1)
()

julia> AxisIndices.matmul_axes(rand(2, 4), rand(4, 2))
(SimpleAxis(Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

julia> AxisIndices.matmul_axes(CartesianAxes((2,4)), CartesianAxes((4, 2))) == AxisIndices.matmul_axes(rand(2, 4), rand(4, 2))
true
```
"""
matmul_axes(a::AbstractArray,  b::AbstractArray ) = matmul_axes(axes(a), axes(b))
matmul_axes(a::Tuple{Any},     b::Tuple{Any,Any}) = (to_axis(first(a)), to_axis(last(b)))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any,Any}) = (to_axis(first(a)), to_axis(last(b)))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any}    ) = (to_axis(first(a)),)
matmul_axes(a::Tuple{Any},     b::Tuple{Any}    ) = ()

"""
    cat_axis(x, y) -> cat_axis(CombineStyle(x, y), x, y)
    cat_axis(::CombineStyle, x, y) -> collection

Returns the concatenated axes `x` and `y`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.cat_axis(Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
Axis(UnitMRange(1:20) => UnitMRange(1:20))

julia> AxisIndices.cat_axis(SimpleAxis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
SimpleAxis(UnitMRange(1:20))
```
"""
cat_axis(x, y) = cat_axis(CombineStyle(x, y), x, y)

function cat_axis(cs::CombineResize, x::X, y::Y) where {X,Y}
    return set_length(promote_axis_collections(x, y), length(x) + length(y))
end

function cat_axis(cs::CombineStack, x::X, y::Y) where {X,Y}
    for x_i in x
        if x_i in y
            error("Element $x_i appears in both collections in call to cat_axis!(collection1, collection2). All elements must be unique.")
        end
    end
    return vcat(x, y)
end

function cat_axis(::CombineAxis, x::X, y::Y) where {X,Y}
    ks = cat_axis(keys(x), keys(y))
    vs = cat_axis(values(x), values(y))
    return similar_type(promote_type(X, Y), typeof(ks), typeof(vs))(ks, vs)
end

function cat_axis(::CombineSimpleAxis, x::X, y::Y) where {X,Y}
    vs = cat_axis(values(x), values(y))
    return similar_type(similar_type(X, Y), typeof(vs))(vs)
end


"""
    vcat_axes(x, y) -> Tuple

Returns the appropriate axes for `vcat(x, y)`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.vcat_axes((Axis(1:2), Axis(1:4)), (Axis(1:2), Axis(1:4)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> a, b = [1 2 3 4 5], [6 7 8 9 10; 11 12 13 14 15];

julia> AxisIndices.vcat_axes(a, b) == axes(vcat(a, b))
true

julia> c, d = LinearAxes((1:1, 1:5,)), LinearAxes((1:2, 1:5));

julia> length.(AxisIndices.vcat_axes(c, d)) == length.(AxisIndices.vcat_axes(a, b))
true
```
"""
vcat_axes(x::AbstractArray, y::AbstractArray) = vcat_axes(axes(x), axes(y))
function vcat_axes(x::Tuple{Any,Vararg}, y::Tuple{Any,Vararg})
    return (cat_axis(first(x), first(y)), Broadcast.broadcast_shape(tail(x), tail(y))...)
end

"""
    hcat_axes(x, y) -> Tuple

Returns the appropriate axes for `hcat(x, y)`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.hcat_axes((Axis(1:4), Axis(1:2)), (Axis(1:4), Axis(1:2)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> a, b = [1; 2; 3; 4; 5], [6 7; 8 9; 10 11; 12 13; 14 15];

julia> AxisIndices.hcat_axes(a, b) == axes(hcat(a, b))
true

julia> c, d = CartesianAxes((Axis(1:5),)), CartesianAxes((Axis(1:5), Axis(1:2)));

julia> length.(AxisIndices.hcat_axes(c, d)) == length.(AxisIndices.hcat_axes(a, b))
true
```
"""
@inline hcat_axes(x::AbstractArray, y::AbstractArray) = hcat_axes(axes(x), axes(y))
@inline function hcat_axes(x::Tuple, y::Tuple)
    return (broadcast_axis(first(x), first(y)), _hcat_axes(tail(x), tail(y))...)
end
_hcat_axes(x::Tuple{}, y::Tuple) = (to_axis(grow_last(first(y), 1)), tail(y)...)
_hcat_axes(x::Tuple, y::Tuple{}) = (to_axis(grow_last(first(x), 1)), tail(x)...)
_hcat_axes(x::Tuple{}, y::Tuple{}) = (SimpleAxis(OneTo(2)),)
function _hcat_axes(x::Tuple, y::Tuple)
    return (cat_axis(first(x), first(y)), broadcast_axes(tail(x), tail(y))...)
end

"""
    diagonal_axes(x::Tuple{<:AbstractAxis,<:AbstractAxis}) -> collection

Determines the appropriate axis for the resulting vector from a call to
`diag(::AxisIndicesMatrix)`. The default behavior is to place the smallest axis
at the beginning of a call to `combine` (e.g., `broadcast_axis(small_axis, big_axis)`).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.diagonal_axes((Axis(string.(2:5)), SimpleAxis(1:2)))
Axis(["1", "2"] => UnitMRange(1:2))

julia> AxisIndices.diagonal_axes((SimpleAxis(1:3), Axis(string.(2:5))))
Axis(["1", "2", "3"] => UnitMRange(1:3))
```
"""
function diagonal_axes(x::NTuple{2,Any})
    m, n = length(first(x)), length(last(x))
    if m > n
        return broadcast_axis(last(x), first(x))
    else
        return broadcast_axis(first(x), last(x))
    end
end

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
    # FIXME this could be a better error message but it's consistent with base
    if length(p) != N
        throw(ArgumentError("no valid permutation of dimensions"))
    end
    return ntuple(i -> getfield(x, getindex(p, i)), Val(N))
end
function permute_axes(x::NTuple{N,Any}, p::NTuple{N,<:Integer}) where {N}
    return map(i -> getfield(x, i), p)
end

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


rotl90_axes(x::AbstractArray) = rotl90_axes(axes(x))
rotl90_axes(x::Tuple) = (reverse_keys(getfield(x, 2)), getfield(x, 1))

rotr90_axes(x::AbstractArray) = rotr90_axes(axes(x))
rotr90_axes(x::Tuple) = (getfield(x, 2), reverse_keys(getfield(x, 1)))

rot180_axes(x::AbstractArray) = rot180_axes(axes(x))
rot180_axes(x::Tuple) = (reverse_keys(getfield(x, 1)), reverse_keys(getfield(x, 2)))