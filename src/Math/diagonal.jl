
"""
    diag(M::AbstractAxisIndicesMatrix, k::Integer=0; dim::Val=Val(1))

The `k`th diagonal of an `AbstractAxisIndicesMatrix`, `M`. The keyword argument
`dim` specifies which which dimension's axis to preserve, with the default being
the first dimension. This can be change by specifying `dim=Val(2)` instead.

```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> A = AxisIndicesArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"], [:one, :two, :three]);

julia> axes_keys(diag(A))
(["a", "b", "c"],)

julia> axes_keys(diag(A, 1; dim=Val(2)))
([:one, :two],)

```
"""
function LinearAlgebra.diag(M::AbstractAxisIndices{T,2}, k::Integer=0; dim::Val{D}=Val(1)) where {T,D}
    p = diag(parent(M), k)
    return unsafe_reconstruct(M, p, (resize_last(axes(M, D), axes(p, 1)),))
end

