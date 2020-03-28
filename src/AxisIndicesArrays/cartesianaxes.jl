
"""
    CartesianAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> cartaxes = CartesianAxes((Axis(2.0:5.0), Axis(1:4)));

julia> cartinds = CartesianIndices((1:4, 1:4));

julia> cartaxes[2, 2]
CartesianIndex(2, 2)

julia> cartinds[2, 2]
CartesianIndex(2, 2)
```
"""
const CartesianAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = CartesianIndices{N,R}


CartesianAxes(ks::Tuple{Vararg{<:Any,N}}) where {N} = CartesianIndices(as_axis.(ks))
CartesianAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = CartesianIndices(ks)

Base.axes(A::CartesianAxes) = getfield(A, :indices)

function Base.getindex(A::CartesianAxes, inds::Vararg{Int})
    Base.@_propagate_inbounds_meta
    return CartesianIndex(map(getindex, axes(A), inds))
end

function Base.getindex(A::CartesianAxes, inds...)
    Base.@_propagate_inbounds_meta
    return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end
#= FIXME handle this
ERROR: MethodError: getindex(::CartesianIndices{0,Tuple{}}) is ambiguous. Candidates:
  getindex(iter::CartesianIndices{N,#s662} where #s662<:Tuple{Vararg{Base.OneTo,N}}, I::Vararg{Int64,N}) where N in B
ase.IteratorsMD at multidimensional.jl:315
  getindex(A::CartesianIndices{N,R} where R<:Tuple{Vararg{AbstractAxis,N}} where N, inds::Int64...) in AxisIndices.Ax
isIndicesArrays at /Users/zchristensen/Box/Zachs_Lab_Notebook/AxisIndices.jl/src/AxisIndicesArrays/cartesianaxes.jl:3
1
Possible fix, define
  getindex(::CartesianIndices{0,R} where R<:Tuple{})
=#
