
Base.map(f, A::AbstractAxisIndices) = unsafe_reconstruct(A, map(f, parent(A)), axes(A))

for f in (:map, :map!)
    # Here f::F where {F} is needed to avoid ambiguities in Julia 1.0
    @eval begin
        function Base.$f(f::F, a::AbstractArray, b::AbstractAxisIndices, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                b,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AbstractAxisIndices, b::AbstractAxisIndices, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                b,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AbstractAxisIndices, b::AbstractArray, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                a,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end
    end
end

function Base.mapslices(f, a::AbstractAxisIndices; dims, kwargs...)
    return indicesarray_result(a, Base.mapslices(f, parent(a); dims=dims, kwargs...), dims)
end

function Base.mapreduce(f1, f2, a::AbstractAxisIndices; dims=:, kwargs...)
    return indicesarray_result(a, Base.mapreduce(f1, f2, parent(a); dims=dims, kwargs...), dims)
end

#=
if VERSION > v"1.1-"
    function Base.eachslice(a::AbstractAxisIndices; dims, kwargs...)
        slices = eachslice(parent(a); dims=dims, kwargs...)
        return Base.Generator(slices) do slice
            return AxisIndicesArray(slice, drop_axes(a, dims))
        end
    end
end

if VERSION < v"1.1-"
    @inline function Base.eachslice(A::AbstractArray; dims)
        length(dims) == 1 || throw(ArgumentError("only single dimensions are supported"))
        dim = first(dims)
        dim <= ndims(A) || throw(DimensionMismatch("A doesn't have $dim dimensions"))
        inds_before = ntuple(d->(:), dim-1)
        inds_after = ntuple(d->(:), ndims(A)-dim)
        return (view(A, inds_before..., i, inds_after...) for i in axes(A, dim))
    end
end
=#

