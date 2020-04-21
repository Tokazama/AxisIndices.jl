
function StaticRanges.axes_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A}
    return StaticRanges.axes_type(A)
end

StaticRanges.parent_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A} = A

named_axes(nda::NamedDimsArray{L}) where {L} = NamedTuple{L}(axes(nda))
function named_axes(a::AbstractArray{T,N}) where {T,N}
    return NamedTuple{default_names(Val(N))}(axes(a))
end

@generated function default_names(::Val{N}) where {N}
    :($(ntuple(i -> Symbol(:dim_, i), N)))
end

"""
    NamedIndicesArray

Type alias for `NamedDimsArray` whose parent array is a subtype of `AxisIndicesArray`.
"""
const NamedIndicesArray{L,T,N,P,AI} = NamedDimsArray{L,T,N,AxisIndicesArray{T,N,P,AI}}

"""
    NIArray((parent::AbstractArray; kwargs...) = NIArray(parent, kwargs)
    NIArray((parent::AbstractArray, axes::NamedTuple{L,AbstractAxes}))

An abbreviated alias and constructor for [`NamedIndicesArray`](@ref). If key word
arguments are provided then each key word becomes the name of a dimension and its
assigned value is sent to the corresponding axis when constructing the underlying
`AxisIndicesArray`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = NIArray(reshape(1:24, 2, 3, 4), x=["a", "b"], y =["one", "two", "three"], z=2:5);

julia> dimnames(A)
(:x, :y, :z)

julia> axes_keys(A)
(["a", "b"], ["one", "two", "three"], 2:5)

julia> B = A["a", :, :];

julia> dimnames(B)
(:y, :z)

julia> axes_keys(B)
(["one", "two", "three"], 2:5)

julia> C = B["one",:];

julia> dimnames(C)
(:z,)

julia> axes_keys(C)
(2:5,)

```
"""
const NIArray{L,T,N,P,AI} = NamedIndicesArray{L,T,N,P,AI}

NIArray(x::AbstractArray; kwargs...) = NIArray(x, kwargs.data)
function NIArray(x::AbstractArray, axs::NamedTuple{L}) where {L}
    return NamedDimsArray{L}(AxisIndicesArray(x, values(axs)))
end

#=
for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::NIArray, inds...)
            return $_f(a, to_indices(parent(a), inds))
        end

        @propagate_inbounds function Base.$f(a::NIArray, inds::Vararg{<:Integer})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function Base.$f(a::NIArray, inds::CartesianIndex)
            return Base.$f(parent(a), inds)
        end

        @propagate_inbounds function $_f(a::NIArray, inds::Tuple{Vararg{<:Integer}})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::NIArray{T,N}, inds::Tuple{Vararg{<:Any,M}}) where {T,N,M}
            data = Base.$f(parent(a), inds...)
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            return NamedDims.NamedDimsArray{L}(data)
        end
    end
end

@propagate_inbounds function Base.getindex(A::NIArray{T,N}, args::Integer...) where {T,N,M}
    inds = to_indices(A, args)
    p = AxisIndexing.unsafe_getindex(parent(A), args, inds)
    L = NamedDims.remaining_dimnames_from_indexing(dimnames(A), inds)
    return NamedDims.NamedDimsArray{L}(p)
end
=#

Base.show(io::IO, x::NIArray; kwargs...) = show(io, MIME"text/plain"(), x, kwargs...)
function Base.show(io::IO, m::MIME"text/plain", x::NIArray{L,T,N}; kwargs...) where {L,T,N}
    println(io, "$(typeof(x).name.name){$T,$N,$(parent_type(parent(x)))...}")
    return show_array(io, parent(parent(x)), axes(x), dimnames(x); kwargs...)
end
