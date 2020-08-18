# TODO unique(::AbstractAxisArray; dims)

"""
    AbstractAxisArray

`AbstractAxisArray` is a subtype of `AbstractArray` that offers integration with the `AbstractAxis` interface.
The only methods that absolutely needs to be defined for a subtype of `AbstractAxisArray` are `axes`, `parent`, `similar_type`, and `similar`.
Most users should find the provided [`AxisArray`](@ref) subtype is sufficient for the majority of use cases.
Although custom behavior may be accomplished through a new subtype of `AbstractAxisArray`, customizing the behavior of many methods described herein can be accomplished through a unique subtype of `AbstractAxis`.

This implementation is meant to be basic, well documented, and have sane defaults that can be overridden as necessary.
In other words, default methods for manipulating arrays that return an `AxisArray` should not cause unexpected downstream behavior for users;
and developers should be able to freely customize the behavior of `AbstractAxisArray` subtypes with minimal effort. 
"""
abstract type AbstractAxisArray{T,N,P,AI} <: AbstractArray{T,N} end

const AbstractAxisMatrix{T,P<:AbstractMatrix{T},A1,A2} = AbstractAxisArray{T,2,P,Tuple{A1,A2}}

const AbstractAxisVector{T,P<:AbstractVector{T},A1} = AbstractAxisArray{T,1,P,Tuple{A1}}

const AbstractAxisVecOrMat{T} = Union{<:AbstractAxisMatrix{T},<:AbstractAxisVector{T}}

Base.IndexStyle(::Type{<:AbstractAxisArray{T,N,A,AI}}) where {T,N,A,AI} = IndexStyle(A)

Base.parentindices(x::AbstractAxisArray) = axes(parent(x))

Base.length(x::AbstractAxisArray) = prod(size(x))

Base.size(x::AbstractAxisArray) = map(length, axes(x))

StaticRanges.axes_type(::Type{<:AbstractAxisArray{T,N,P,AI}}) where {T,N,P,AI} = AI
StaticRanges.axes_type(::Type{<:AbstractAxisArray{T,N,P,AI}}, i::Int) where {T,N,P,AI} = AI.parameters[i]

function Base.axes(x::AbstractAxisArray{T,N}, i::Integer) where {T,N}
    if i > N
        return SimpleAxis(1)
    else
        return getfield(axes(x), i)
    end
end

# this only works if the axes are the same size
function Interface.unsafe_reconstruct(A::AbstractAxisArray{T1,N}, p::AbstractArray{T2,N}) where {T1,T2,N}
    return unsafe_reconstruct(A, p, map(assign_indices,  axes(A), axes(p)))
end

###
### similar
###
@inline function Base.similar(A::AbstractAxisArray{T}, dims::NTuple{N,Int}) where {T,N}
    return similar(A, T, dims)
end

@inline function Base.similar(A::AbstractAxisArray{T}, ks::Tuple{Vararg{<:AbstractVector,N}}) where {T,N}
    return similar(A, T, ks)
end

@inline function Base.similar(A::AbstractAxisArray, ::Type{T}, ks::Tuple{Vararg{<:AbstractVector,N}}) where {T,N}
    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false))
end

# Necessary to avoid ambiguities with OffsetArrays
@inline function Base.similar(A::AbstractAxisArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    p = similar(parent(A), T, dims)
    return unsafe_reconstruct(A, p, to_axes(axes(A), (), axes(p), false))
end

function Base.similar(A::AbstractAxisArray, ::Type{T}) where {T}
    p = similar(parent(A), T)
    return unsafe_reconstruct(A, p, map(assign_indices, axes(A), axes(p)))
end

function Base.similar(
    A::AbstractAxisArray,
    ::Type{T},
    ks::Tuple{Union{Base.IdentityUnitRange, OneTo, UnitRange},Vararg{Union{Base.IdentityUnitRange, OneTo, UnitRange},N}}
) where {T, N}

    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false))
end

function Base.similar(A::AbstractAxisArray, ::Type{T}, ks::Tuple{OneTo,Vararg{OneTo,N}}) where {T, N}
    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false))
end

function Base.similar(::Type{T}, ks::AbstractAxes{N}) where {T<:AbstractArray, N}
    p = similar(T, map(length, ks))
    axs = to_axes((), ks, axes(p), false)
    return AxisArray{eltype(T),N,typeof(p),typeof(axs)}(p, axs)
end

# FIXME
# When I use Val(N) on the tuple the it spits out many lines of extra code.
# But without it it loses inferrence
function Base.reinterpret(::Type{Tnew}, A::AbstractAxisArray{Told,N}) where {Tnew,Told,N}
    p = reinterpret(Tnew, parent(A))
    axs = ntuple(N) do i
        resize_last(axes(A, i), size(p, i))
    end
    return unsafe_reconstruct(A, p, axs)
end

function Base.reverse(x::AbstractAxisArray{T,N}; dims::Integer) where {T,N}
    p = reverse(parent(x), dims=dims)
    axs = ntuple(Val(N)) do i
        if i in dims
            reverse_keys(axes(x, i), axes(p, i))
        else
            assign_indices(axes(x, i), axes(p, i))
        end
    end
    return unsafe_reconstruct(x, p, axs)
end

Base.has_offset_axes(A::AbstractAxisArray) = Base.has_offset_axes(parent(A))

function Base.dropdims(a::AbstractAxisArray; dims)
    return unsafe_reconstruct(a, dropdims(parent(a); dims=dims), drop_axes(a, dims))
end

###
### Indexing
###
for (unsafe_f, f) in ((:unsafe_getindex, :getindex), (:unsafe_view, :view), (:unsafe_dotview, :dotview))
    @eval begin
        @propagate_inbounds function Base.$f(A::AbstractAxisArray, args...)
            return Axes.$unsafe_f(A, args, Interface.to_indices(A, args))
        end
    end
end

Base.getindex(A::AbstractAxisArray, ::Ellipsis) = A

@propagate_inbounds function Base.setindex!(a::AbstractAxisArray, value, inds...)
    return setindex!(parent(a), value, Interface.to_indices(a, inds)...)
end


###
### Math
###
for f in (:sum!, :prod!, :maximum!, :minimum!)
    for (A,B) in ((AbstractAxisArray, AbstractArray),
                  (AbstractAxisArray, NamedDimsArray),
                  (AbstractArray,       AbstractAxisArray),
                  (NamedDimsArray,       AbstractAxisArray),
                  (AbstractAxisArray, AbstractAxisArray))
        @eval begin
            function Base.$f(a::$A, b::$B)
                Base.$f(parent(a), parent(b))
                return a
            end
        end
    end
end

for f in (:cumsum, :cumprod)
    @eval function Base.$f(a::AbstractAxisArray; dims, kwargs...)
        return unsafe_reconstruct(a, Base.$f(parent(a); dims=dims, kwargs...))
    end

    # Vector case
    @eval function Base.$f(a::AbstractAxisArray{T,1}; kwargs...) where {T}
        return unsafe_reconstruct(a, Base.$f(parent(a); kwargs...))
    end
end

Base.isapprox(a::AbstractAxisArray, b::AbstractAxisArray; kw...) = isapprox(parent(a), parent(b); kw...)
Base.isapprox(a::AbstractAxisArray, b::AbstractArray; kw...) = isapprox(parent(a), b; kw...)
Base.isapprox(a::AbstractArray, b::AbstractAxisArray; kw...) = isapprox(a, parent(b); kw...)

Base.:(==)(a::AbstractAxisArray, b::AbstractAxisArray) = ==(parent(a), parent(b))
Base.:(==)(a::AbstractAxisArray, b::AbstractArray) = ==(parent(a), b)
Base.:(==)(a::AbstractArray, b::AbstractAxisArray) = ==(a, parent(b))
Base.:(==)(a::AbstractAxisArray, b::AbstractAxis) = ==(parent(a), b)
Base.:(==)(a::AbstractAxis, b::AbstractAxisArray) = ==(a, parent(b))
Base.:(==)(a::AbstractAxisArray, b::GapRange) = ==(parent(a), b)
Base.:(==)(a::GapRange, b::AbstractAxisArray) = ==(a, parent(b))

Base.:isequal(a::AbstractAxisArray, b::AbstractAxisArray) = isequal(parent(a), parent(b))
Base.:isequal(a::AbstractAxisArray, b::AbstractArray) = isequal(parent(a), b)
Base.:isequal(a::AbstractArray, b::AbstractAxisArray) = isequal(a, parent(b))
Base.:isequal(a::AbstractAxisArray, b::AbstractAxis) = isequal(parent(a), b)
Base.:isequal(a::AbstractAxis, b::AbstractAxisArray) = isequal(a, parent(b))

for f in (:zero, :one, :copy)
    @eval begin
        function Base.$f(a::AbstractAxisArray)
            return unsafe_reconstruct(a, Base.$f(parent(a)))
        end
    end
end

###
### reduce
###
function reconstruct_reduction(old_array, new_array, dims)
    return unsafe_reconstruct(
        old_array,
        new_array,
        reduce_axes(axes(old_array), axes(new_array), dims)
    )
end
reconstruct_reduction(old_array, new_array, dims::Colon) = new_array

function Base.mapslices(f, a::AbstractAxisArray; dims, kwargs...)
    return reconstruct_reduction(a, Base.mapslices(f, parent(a); dims=dims, kwargs...), dims)
end

function Base.mapreduce(f1, f2, a::AbstractAxisArray; dims=:, kwargs...)
    return reconstruct_reduction(a, Base.mapreduce(f1, f2, parent(a); dims=dims, kwargs...), dims)
end

function Base.extrema(A::AbstractAxisArray; dims=:, kwargs...)
    return reconstruct_reduction(A, Base.extrema(parent(A); dims=dims, kwargs...), dims)
end

if VERSION > v"1.2"
    function Base.has_fast_linear_indexing(x::AbstractAxisArray)
        return Base.has_fast_linear_indexing(parent(x))
    end
end

"""
    reshape(A::AbstractAxisArray, shape)

Reshape the array and axes of `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = reshape(AxisArray(Vector(1:8), [:a, :b, :c, :d, :e, :f, :g, :h]), 4, 2);

julia> axes(A)
(Axis([:a, :b, :c, :d] => Base.OneTo(4)), SimpleAxis(Base.OneTo(2)))

julia> axes(reshape(A, 2, :))
(Axis([:a, :b] => Base.OneTo(2)), SimpleAxis(Base.OneTo(4)))
```
"""
function Base.reshape(A::AbstractAxisArray, shp::NTuple{N,Int}) where {N}
    p = reshape(parent(A), shp)
    return unsafe_reconstruct(A, p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

function Base.reshape(A::AbstractAxisArray, shp::Tuple{Vararg{Union{Int,Colon},N}}) where {N}
    p = reshape(parent(A), shp)
    return unsafe_reconstruct(A, p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

for f in (:sort, :sort!)
    @eval function Base.$f(A::AbstractAxisArray; dims, kwargs...)
        return unsafe_reconstruct(A, Base.$f(parent(A); dims=dims, kwargs...))
    end

    # Vector case
    @eval function Base.$f(a::AbstractAxisArray{T,1}; kwargs...) where {T}
        return unsafe_reconstruct(a, Base.$f(parent(a); kwargs...))
    end
end

###
### I/O
###

function Base.unsafe_convert(::Type{Ptr{T}}, x::AbstractAxisArray{T}) where {T}
    return Base.unsafe_convert(Ptr{T}, parent(x))
end

function Base.read!(io::IO, a::AbstractAxisArray)
    read!(io, parent(a))
    return a
end

Base.write(io::IO, a::AbstractAxisArray) = write(io, parent(a))

function Base.empty!(a::AbstractAxisArray)
    for ax_i in axes(a)
        if !can_set_length(ax_i)
            error("Cannot perform `empty!` on AbstractAxisArray that has an axis with a fixed size.")
        end
    end

    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end

for (tf, T, sf, S) in (
    (parent, :AbstractAxisVecOrMat, parent, :AbstractAxisVecOrMat),
    (parent, :AbstractAxisVecOrMat, identity, :AbstractVecOrMat),
    (identity, :AbstractVecOrMat, parent, :AbstractAxisVecOrMat))
    @eval function Base.vcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        p = vcat($tf(A), $sf(B))
        axs = Axes.vcat_axes(A, B, p)
        return vcat(AxisArray(p, axs), Cs...)
    end

    @eval function Base.hcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        p = hcat($tf(A), $sf(B))
        axs = Axes.hcat_axes(A, B, p)
        return hcat(AxisArray(p, axs), Cs...)
    end

    @eval function Base.cat(A::$T, B::$S, Cs::AbstractVecOrMat...; dims)
        p = cat($tf(A), $sf(B); dims=dims)
        return cat(AxisArray(p, Axes.cat_axes(A, B, p, dims)), Cs..., dims=dims)
    end
end

function Base.hcat(A::AbstractAxisArray{T,N}) where {T,N}
    if N === 1
        return unsafe_reconstruct(A, hcat(parent(A)), (axes(A, 1), SimpleAxis(OneTo(1))))
    else
        return A
    end
end

Base.vcat(A::AbstractAxisArray{T,N}) where {T,N} = A

Base.cat(A::AbstractAxisArray{T,N}; dims) where {T,N} = A

function Base.convert(::Type{T}, A::AbstractArray) where {T<:AbstractAxisArray}
    if A isa T
        return A
    else
        return T(A)
    end
end

Base.LogicalIndex(A::AbstractAxisArray) = Base.LogicalIndex(parent(A))

const ReinterpretAxisArray{T,N,S,A<:AbstractAxisArray{S,N}} = ReinterpretArray{T,N,S,A}

function Base.axes(A::ReinterpretAxisArray{T,N,S}) where {T,N,S}
    paxs = axes(parent(A))
    axis_1 = first(paxs)
    len = div(length(axis_1) * sizeof(S), sizeof(T))
    return tuple(resize_last(axis_1, len), tail(paxs)...)
end

function Base.collect(A::AbstractAxisArray)
    p = collect(parent(A))
    return unsafe_reconstruct(A, p, map(assign_indices,  axes(A), axes(p)))
end

#=
function size(a::ReinterpretArray{T,N,S} where {N}) where {T,S}
    psize = size(a.parent)
    size1 = div(psize[1]*sizeof(S), sizeof(T))
    tuple(size1, tail(psize)...)
end
=#
