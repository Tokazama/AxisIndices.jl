
function Base.permutedims(A::AbstractAxisArray{T,N}, perms) where {T,N}
    p = permutedims(parent(A), perms)
    axs = ntuple(Val(N)) do i
        assign_indices(axes(A, perms[i]), axes(p, i))
    end
    return unsafe_reconstruct(A, p, axs)
end


@inline function Base.selectdim(A::AbstractAxisArray{T,N}, d::Integer, i) where {T,N}
    axs = ntuple(N) do dim_i
        if dim_i == d
            i
        else
            (:)
        end
    end
    return view(A, axs...)
end

# reshape
# For now we only implement the version that drops dimension names
# TODO
#Base.reshape(ia::AbstractAxisMatrix, d::Vararg{Union{Colon, Int}}) = reshape(parent(ia), d)
## return axes even when they are permuted
function Base.axes(a::PermutedDimsArray{T,N,permin,permout,<:AbstractAxisArray}) where {T,N,permin,permout}
    return permute_axes(parent(a), permin)
end

"""
    diag(M::AbstractAxisMatrix, k::Integer=0; dim::Val=Val(1))

The `k`th diagonal of an `AbstractAxisMatrixMatrix`, `M`. The keyword argument
`dim` specifies which which dimension's axis to preserve, with the default being
the first dimension. This can be change by specifying `dim=Val(2)` instead.

```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> A = AxisArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"], [:one, :two, :three]);

julia> axes_keys(diag(A))
(["a", "b", "c"],)

julia> axes_keys(diag(A, 1; dim=Val(2)))
([:one, :two],)

```
"""
function LinearAlgebra.diag(M::AbstractAxisArray, k::Integer=0; dim::Val{D}=Val(1)) where {D}
    p = diag(parent(M), k)
    return unsafe_reconstruct(M, p, (resize_last(axes(M, D), axes(p, 1)),))
end

"""
    inv(M::AbstractAxisMatrix)

Computes the inverse of an `AbstractAxisMatrixMatrix`
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> M = AxisArray([2 5; 1 3], ["a", "b"], [:one, :two]);

julia> axes_keys(inv(M))
([:one, :two], ["a", "b"])

```
"""
function Base.inv(A::AbstractAxisArray)
    p = inv(parent(A))
    axs = (assign_indices(axes(A, 2), axes(p, 1)), assign_indices(axes(A, 1), axes(A, 2)))
    return unsafe_reconstruct(A, p, axs)
end

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv))
    @eval begin
        function $f(A::AbstractAxisArray)
            p = $f(parent(A))
            return unsafe_reconstruct(A, p, permute_axes(A, p))
        end
    end
end

