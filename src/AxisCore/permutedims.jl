
"""

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
"""
permute_axes(x::AbstractArray{T,N}, perms) where {T,N} = permute_axes(axes(x), perms)
function permute_axes(x::NTuple{N,Any}, perms::AbstractVector{<:Integer}) where {N}
    return Tuple(map(i -> getindex(x, i), perms))
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

#=
    permute_axes(old_array, new_array) -> NTuple{2}

Permute axes of `old_array` and replace indices with those of `new_array`.
=#
function permute_axes(old_array::AbstractVector, new_array::AbstractMatrix)
    return (
        SimpleAxis(axes(new_array, 1)),
        assign_indices(axes(old_array, 1), axes(new_array, 2))
    )
end

function permute_axes(old_array::AbstractMatrix, new_array::AbstractMatrix)
    (assign_indices(axes(old_array, 2), axes(new_array, 1)),
     assign_indices(axes(old_array, 1), axes(new_array, 2)))
end

function permute_axes(old_array::AbstractMatrix, new_array::AbstractVector)
    (assign_indices(axes(old_array, 2), axes(new_array, 1)),)
end

function permute_axes(old_array::AbstractArray{T1,N}, new_array::AbstractArray{T2,N}, perms) where {T1,T2,N}
end

function Base.permutedims(A::AbstractAxisIndices{T,N}, perms) where {T,N}
    p = permutedims(parent(A), perms)
    axs = ntuple(Val(N)) do i
        assign_indices(axes(A, perms[i]), axes(p, i))
    end
    return unsafe_reconstruct(A, p, axs)
end

const CoVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}

@inline function Base.selectdim(A::AbstractAxisIndices{T,N}, d::Integer, i) where {T,N}
    axs = ntuple(N) do dim_i
        if dim_i == d
            i
        else
            (:)
        end
    end
    return view(A, axs...)
end

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv))
    @eval begin
        function $f(A::AbstractAxisIndices)
            p = $f(parent(A))
            return unsafe_reconstruct(A, p, permute_axes(A, p))
        end
    end
    # Vector
    #=
    @eval begin
        function $f(A::AbstractAxisIndices{T,1}) where {T}
            p = $f(parent(A))
            return unsafe_reconstruct(A, p, permute_axes(A, p))
        end

        function $f(A::AbstractAxisIndices{T,2}) where {T}
            return permute_reconstruct(A, $f(parent(A)), (2, 1))
        end
    end

    # Vector Double Transpose
    if f != :(Base.permutedims)
        # TODO fix CoVector
        @eval begin
            function $f(a::AbstractAxisIndices{T,2,A}) where {T,A<:CoVector}
                p = $f(parent(a))
                return unsafe_reconstruct(a, p, permute_axes(a, p))
            end
        end
    end
    =#
end

# reshape
# For now we only implement the version that drops dimension names
# TODO
#Base.reshape(ia::AbstractAxisIndices, d::Vararg{Union{Colon, Int}}) = reshape(parent(ia), d)
## return axes even when they are permuted
function Base.axes(a::PermutedDimsArray{T,N,permin,permout,<:AbstractAxisIndices}) where {T,N,permin,permout}
    return permute_axes(parent(a), permin)
end

