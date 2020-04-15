
"""
    LinearAxes

Alias for LinearIndices where indices are subtypes of `AbstractAxis`.

## Examples
```jldoctest
julia> using AxisIndices

julia> linaxes = LinearAxes((Axis(2.0:5.0), Axis(1:4)));

julia> lininds = LinearIndices((1:4, 1:4));

julia> linaxes[2, 2]
6

julia> lininds[2, 2]
6
```
"""
const LinearAxes{N,R<:Tuple{Vararg{<:AbstractAxis,N}}} = LinearIndices{N,R}

function LinearAxes(ks::Tuple{Vararg{<:Integer,N}}) where {N}
    return LinearIndices(map(SimpleAxis, ks))
end
function LinearAxes(ks::Tuple{Vararg{<:Any,N}}) where {N}
    return LinearIndices(AxisCore.similar_axes((), ks, (), false))
end
LinearAxes(ks::Tuple{Vararg{<:AbstractAxis,N}}) where {N} = LinearIndices(ks)

Base.axes(A::LinearAxes) = getfield(A, :indices)

@boundscheck function Base.getindex(iter::LinearAxes, i::Int)
    @boundscheck checkbounds(iter, i)
    return i
end

@propagate_inbounds function Base.getindex(A::LinearAxes, inds...)
    return Base._getindex(IndexStyle(A), A, to_indices(A, Tuple(inds))...)
end

