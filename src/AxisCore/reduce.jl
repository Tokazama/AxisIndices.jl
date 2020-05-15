
"""
    reduce_axis(axis[, new_indics]) -> AbstractAxis

Reduces axis `a` to single value. Allows custom index types to have custom
behavior throughout reduction methods (e.g., sum, prod, etc.)
See also: [`reduce_axes`](@ref)

## Example
```jldoctest
julia> using AxisIndices

julia> AxisIndices.reduce_axis(Axis(1:4))
Axis(1:1 => Base.OneTo(1))

julia> AxisIndices.reduce_axis(1:4)
1:1
```
"""
# `new_indices` is already reduced b/c it's derived from the new parent array
function reduce_axis(axis::AbstractAxis, new_indices::AbstractUnitRange=values(axis))
    return similar(axis, set_length(keys(axis), 1), new_indices, false)
end

function reduce_axis(axis::AbstractSimpleAxis, new_indices::AbstractUnitRange=values(axis))
    return similar(axis, new_indices)
end

reduce_axis(x) = set_length(x, 1)

reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims::Colon) where {N} = ()
function reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims) where {N}
    ntuple(Val(N)) do i
        if i in dims
            reduce_axis(getfield(old_axes, i), getfield(new_axes, i))
        else
            assign_indices(getfield(old_axes, i), getfield(new_axes, i))
        end
    end
end

function reconstruct_reduction(old_array, new_array, dims)
    return unsafe_reconstruct(
        old_array,
        new_array,
        reduce_axes(axes(old_array), axes(new_array), dims)
    )
end
reconstruct_reduction(old_array, new_array, dims::Colon) = new_array

function Base.mapslices(f, a::AbstractAxisIndices; dims, kwargs...)
    return reconstruct_reduction(a, Base.mapslices(f, parent(a); dims=dims, kwargs...), dims)
end

function Base.mapreduce(f1, f2, a::AbstractAxisIndices; dims=:, kwargs...)
    return reconstruct_reduction(a, Base.mapreduce(f1, f2, parent(a); dims=dims, kwargs...), dims)
end

function Base.extrema(A::AbstractAxisIndices; dims=:, kwargs...)
    return reconstruct_reduction(A, Base.extrema(parent(A); dims=dims, kwargs...), dims)
end

if VERSION > v"1.2"
    function Base.hase_fast_linear_indexing(x::AbstractAxisIndices)
        return Base.hase_fast_linear_indexing(parent(x))
    end
end

#= TODO test on multiple versions that this passes to `mapreducedim`
for f in (:sum, :prod, :maximum, :minimum, :extrema)
    @eval begin
        function Base.$f(A::AbstractAxisIndices; dims=:, kwargs...)
            return reconstruct_reduction(A, Base.$f(parent(A); dims=dims, kwargs...), dims)
        end
    end
end

=#
