
permute_axes(x::AbstractArray{T,N}, perms) where {T,N} = permute_axes(axes(x), perms)
function permute_axes(x::NTuple{N,Any}, perms::AbstractVector{<:Integer}) where {N}
    return Tuple(map(i -> getindex(x, i), perms))
end
permute_axes(x::NTuple{N,Any}, p::NTuple{N,<:Integer}) where {N} = map(i -> getfield(x, i), p)

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

permute_axes(x::AbstractMatrix) = permute_axes(axes(x))
permute_axes(x::NTuple{2,Any}) = (last(x), first(x))

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

function Base.permutedims(A::AxisArray{T,N}, perms) where {T,N}
    p = permutedims(parent(A), perms)
    axs = ntuple(Val(N)) do i
        assign_indices(axes(A, perms[i]), axes(p, i))
    end
    return AxisArray(p, axs)
end

function Base.permutedims(A::AxisArray)
    p = permutedims(parent(A))
    return AxisArray(p, permute_axes(A, p))
end

"""
    permuteddimsview(A, perm)

returns a "view" of `A` with its dimensions permuted as specified by
`perm`. This is like `permutedims`, except that it produces a view
rather than a copy of `A`; consequently, any manipulations you make to
the output will be mirrored in `A`. Compared to the copy, the view is
much faster to create, but generally slower to use.
"""
permuteddimsview(A, perm) = PermutedDimsArray(A, perm)
function permuteddimsview(A::AxisArray, perm)
    p = PermutedDimsArray(parent(A), perm)
    return AxisArray(p, permute_axes(A, p, perm))
end
