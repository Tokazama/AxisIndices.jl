
"""
    inv(M::AbstractAxisIndicesMatrix)

Computes the inverse of an `AbstractAxisIndicesMatrix`
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> M = AxisIndicesArray([2 5; 1 3], ["a", "b"], [:one, :two]);

julia> axes_keys(inv(M))
([:one, :two], ["a", "b"])

```
"""
function Base.inv(a::AbstractAxisIndices{T,2}) where {T}
    p = inv(parent(a))
    return unsafe_reconstruct(
        a,
        p,
        (assign_indices(axes(a, 2), axes(p, 1)), assign_indices(axes(a, 1), axes(p, 2)))
    )
end

