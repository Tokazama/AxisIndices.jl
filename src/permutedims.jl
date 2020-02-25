
"""
    permute_axes(x::AbstractArray, p::Tuple) = permute_axes(axes(x), p)
    permute_axes(x::NTuple{N}, p::NTuple{N}) -> NTuple{N}

Returns axes of `x` in the order of `p`.

## Examples
```jldoctest
julia> using AxisIndices

julia> permute_axes(rand(2, 4, 6), (1, 3, 2))
(Base.OneTo(2), Base.OneTo(6), Base.OneTo(4))

julia> permute_axes((Axis(1:2), Axis(1:4), Axis(1:6)), (1, 3, 2))
(Axis(1:2 => Base.OneTo(2)), Axis(1:6 => Base.OneTo(6)), Axis(1:4 => Base.OneTo(4)))
```
"""
permute_axes(x::AbstractArray{T,N}, p) where {T,N} = permute_axes(axes(x), p)
permute_axes(x::NTuple{N,Any}, p::AbstractVector{<:Integer}) where {N} = Tuple(map(i -> getindex(x, i), p))
permute_axes(x::NTuple{N,Any}, p::NTuple{N,<:Integer}) where {N} = map(i -> getfield(x, i), p)

"""
    permute_axes(x::AbstractVector)

Returns the permuted axes of `x` as axes of size 1 × length(x)

## Examples
```jldoctest
julia> using AxisIndices

julia> length.(permute_axes(rand(4))) == (1, 4)
true

julia> permute_axes((Axis(1:4),))
(SimpleAxis(Base.OneTo(1)), Axis(1:4 => Base.OneTo(4)))

julia> permute_axes((Axis(mrange(1, 4)),))
(SimpleAxis(OneToMRange(1)), Axis(UnitMRange(1:4) => OneToMRange(4)))

julia> permute_axes((Axis(srange(1, 4)),))
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

julia> permute_axes(rand(4, 2))
(Base.OneTo(2), Base.OneTo(4))

julia> permute_axes((Axis(1:4), Axis(1:2)))
(Axis(1:2 => Base.OneTo(2)), Axis(1:4 => Base.OneTo(4)))
```
"""
permute_axes(x::AbstractMatrix) = permute_axes(axes(x))
permute_axes(x::NTuple{2,Any}) = (last(x), first(x))

function Base.permutedims(a::AxisIndicesArray, perm)
    return AxisIndicesArray(permutedims(parent(a), perm), permute_axes(a, perm))
end

#Base.selectdim(a::AxisIndicesArray, d::Integer, i) = selectdim(a, d, i)

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv))
    # Vector
    @eval function $f(v::AxisIndicesVector)
        return AxisIndicesArray($f(parent(v)), permute_axes(v))
    end

    # Vector Double Transpose
    if f != :(Base.permutedims)
        # TODO fix CoVector
        @eval function $f(a::AxisIndicesMatrix{T,A}) where {L,T,A<:CoVector}
            return AxisIndicesArray($f(parent(a)), (axes(a, 2),))
        end
    end

    # Matrix
    @eval function $f(a::AxisIndicesMatrix)
        return AxisIndicesArray($f(parent(a)), permute_axes(a))
    end
end


# reshape
# For now we only implement the version that drops dimension names
# TODO
#Base.reshape(ia::AxisIndicesArray, d::Vararg{Union{Colon, Int}}) = reshape(parent(ia), d)

