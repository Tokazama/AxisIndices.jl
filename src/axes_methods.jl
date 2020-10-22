
# TODO document
reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims::Colon) where {N} = ()
function reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims) where {N}
    ntuple(Val(N)) do i
        if i in dims
            StaticRanges.shrink_last(getfield(old_axes, i), getfield(new_axes, i))
        else
            unsafe_reconstruct(getfield(old_axes, i), getfield(new_axes, i))
        end
    end
end

#=
We need to assign new indices to axes of `A` but `reshape` may have changed the
size of any axis
=#
@inline function reshape_axes(axs::Tuple, inds::Tuple{Vararg{Any,N}}) where {N}
    return map((a, i) -> resize_last(a, i), axs, inds)
end

###
### offset axes
###
function StaticRanges.has_offset_axes(::Type{T}) where {T<:AbstractAxis}
    return !(known_first(T) === oneunit(valtype(T)))
end

#=

    permute_axes(x::AbstractArray, perms::Tuple) = permute_axes(axes(x), p)
    permute_axes(x::NTuple{N}, perms::NTuple{N}) -> NTuple{N}

Returns axes of `x` in the order of `p`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.permute_axes(rand(2, 4, 6), (1, 3, 2))
(Base.OneTo(2), Base.OneTo(6), Base.OneTo(4))

julia> AxisIndices.permute_axes((Axis(1:2), Axis(1:4), Axis(1:6)), (1, 3, 2))
(Axis(1:2 => Base.OneTo(2)), Axis(1:6 => Base.OneTo(6)), Axis(1:4 => Base.OneTo(4)))

```
=#
permute_axes(x::AbstractArray{T,N}, perms) where {T,N} = permute_axes(axes(x), perms)
function permute_axes(x::NTuple{N,Any}, perms::AbstractVector{<:Integer}) where {N}
    return Tuple(map(i -> getindex(x, i), perms))
end
permute_axes(x::NTuple{N,Any}, p::NTuple{N,<:Integer}) where {N} = map(i -> getfield(x, i), p)

#=
    permute_axes(x::AbstractVector)

Returns the permuted axes of `x` as axes of size 1 × length(x)

## Examples
```jldoctest
julia> using AxisIndices, StaticRanges

julia> length.(AxisIndices.permute_axes(rand(4))) == (1, 4)
true

julia> AxisIndices.permute_axes((Axis(1:4),))
(SimpleAxis(Base.OneTo(1)), Axis(1:4 => Base.OneTo(4)))

julia> AxisIndices.permute_axes((Axis(mrange(1, 4)),))
(SimpleAxis(OneToMRange(1)), Axis(UnitMRange(1:4) => OneToMRange(4)))

julia> AxisIndices.permute_axes((Axis(srange(1, 4)),))
(SimpleAxis(OneToSRange(1)), Axis(UnitSRange(1:4) => OneToSRange(4)))

```
=#
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


#=
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
=#
permute_axes(x::AbstractMatrix) = permute_axes(axes(x))
permute_axes(x::NTuple{2,Any}) = (last(x), first(x))

#=
    permute_axes(old_array, new_array) -> NTuple{2}

Permute axes of `old_array` and replace indices with those of `new_array`.
=#
function permute_axes(old_array::AbstractVector, new_array::AbstractMatrix)
    return (
        SimpleAxis(axes(new_array, 1)),
        unsafe_reconstruct(axes(old_array, 1), axes(new_array, 2))
    )
end

function permute_axes(old_array::AbstractMatrix, new_array::AbstractMatrix)
    return (
        unsafe_reconstruct(axes(old_array, 2), axes(new_array, 1)),
        unsafe_reconstruct(axes(old_array, 1), axes(new_array, 2))
    )
end

function permute_axes(old_array::AbstractMatrix, new_array::AbstractVector)
    return (unsafe_reconstruct(axes(old_array, 2), axes(new_array, 1)),)
end

function permute_axes(old_array::AbstractArray{T1,N}, new_array::AbstractArray{T2,N}, perms) where {T1,T2,N}
    ntuple(Val(N)) do i
        unsafe_reconstruct(axes(old_array, perms[i]), axes(new_array, i))
    end
end

