
"""
    AbstractAxisIndices

`AbstractAxisIndices` is a subtype of `AbstractArray` that offers integration with the `AbstractAxis` interface.
The only methods that absolutely needs to be defined for a subtype of `AbstractAxisIndices` are `axes`, `parent`, `similar_type`, and `similar`.
Most users should find the provided [`AxisIndicesArray`](@ref) subtype is sufficient for the majority of use cases.
Although custom behavior may be accomplished through a new subtype of `AbstractAxisIndices`, customizing the behavior of many methods described herein can be accomplished through a unique subtype of `AbstractAxis`.

This implementation is meant to be basic, well documented, and have sane defaults that can be overridden as necessary.
In other words, default methods for manipulating arrays that return an `AxisIndicesArray` should not cause unexpected downstream behavior for users;
and developers should be able to freely customize the behavior of `AbstractAxisIndices` subtypes with minimal effort. 
"""
abstract type AbstractAxisIndices{T,N,P,AI} <: AbstractArray{T,N} end

const AbstractAxisIndicesMatrix{T,P<:AbstractMatrix{T},A1,A2} = AbstractAxisIndices{T,2,P,Tuple{A1,A2}}

const AbstractAxisIndicesVector{T,P<:AbstractVector{T},A1} = AbstractAxisIndices{T,1,P,Tuple{A1}}

const AbstractAxisIndicesVecOrMat{T} = Union{<:AbstractAxisIndicesMatrix{T},<:AbstractAxisIndicesVector{T}}

StaticRanges.parent_type(::Type{<:AbstractAxisIndices{T,N,P}}) where {T,N,P} = P

Base.IndexStyle(::Type{<:AbstractAxisIndices{T,N,A,AI}}) where {T,N,A,AI} = IndexStyle(A)

Base.parentindices(x::AbstractAxisIndices) = axes(parent(x))

Base.length(x::AbstractAxisIndices) = prod(size(x))

Base.size(x::AbstractAxisIndices) = map(length, axes(x))

StaticRanges.axes_type(::Type{<:AbstractAxisIndices{T,N,P,AI}}) where {T,N,P,AI} = AI

function Base.axes(x::AbstractAxisIndices{T,N}, i::Integer) where {T,N}
    if i > N
        return SimpleAxis(1)
    else
        return getfield(axes(x), i)
    end
end

# this only works if the axes are the same size
function Interface.unsafe_reconstruct(A::AbstractAxisIndices{T1,N}, p::AbstractArray{T2,N}) where {T1,T2,N}
    return unsafe_reconstruct(A, p, map(assign_indices,  axes(A), axes(p)))
end

"""
    unsafe_reconstruct(A::AbstractAxisIndices, parent, axes)

Reconstructs an `AbstractAxisIndices` of the same type as `A` but with the parent
array `parent` and axes `axes`. This method depends on an underlying call to
`similar_types`. It is considered unsafe because it bypasses safety checks to
ensure the keys of each axis are unique and match the length of each dimension of
`parent`. Therefore, this is not intended for interactive use and should only be
used when it is clear all arguments are composed correctly.
"""
function Interface.unsafe_reconstruct(A::AbstractAxisIndices, p::AbstractArray, axs::Tuple)
    return similar_type(A, typeof(p), typeof(axs))(p, axs)
end

###
### similar
###
@inline function Base.similar(A::AbstractAxisIndices{T}, dims::NTuple{N,Int}) where {T,N}
    return similar(A, T, dims)
end

@inline function Base.similar(A::AbstractAxisIndices{T}, ks::Tuple{Vararg{<:AbstractVector,N}}) where {T,N}
    return similar(A, T, ks)
end

@inline function Base.similar(A::AbstractAxisIndices, ::Type{T}, ks::Tuple{Vararg{<:AbstractVector,N}}) where {T,N}
    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false, Staticness(p)))
end

# Necessary to avoid ambiguities with OffsetArrays
@inline function Base.similar(A::AbstractAxisIndices, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    p = similar(parent(A), T, dims)
    return unsafe_reconstruct(A, p, to_axes(axes(A), (), axes(p), false, Staticness(p)))
end

function Base.similar(A::AbstractAxisIndices, ::Type{T}) where {T}
    p = similar(parent(A), T)
    return unsafe_reconstruct(A, p, map(assign_indices, axes(A), axes(p)))
end

function Base.similar(
    A::AbstractAxisIndices,
    ::Type{T},
    ks::Tuple{Union{Base.IdentityUnitRange, OneTo, UnitRange},Vararg{Union{Base.IdentityUnitRange, OneTo, UnitRange},N}}
) where {T, N}

    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false, Staticness(p)))
end

function Base.similar(A::AbstractAxisIndices, ::Type{T}, ks::Tuple{OneTo,Vararg{OneTo,N}}) where {T, N}
    p = similar(parent(A), T, map(length, ks))
    return unsafe_reconstruct(A, p, to_axes(axes(A), ks, axes(p), false, Staticness(p)))
end

function Base.similar(::Type{T}, ks::AbstractAxes{N}) where {T<:AbstractArray, N}
    p = similar(T, map(length, ks))
    axs = to_axes((), ks, axes(p), false, Staticness(p))
    return AxisIndicesArray{eltype(T),N,typeof(p),typeof(axs)}(p, axs)
end

# FIXME
# When I use Val(N) on the tuple the it spits out many lines of extra code.
# But without it it loses inferrence
function Base.reinterpret(::Type{Tnew}, A::AbstractAxisIndices{Told,N}) where {Tnew,Told,N}
    p = reinterpret(Tnew, parent(A))
    axs = ntuple(N) do i
        resize_last(axes(A, i), size(p, i))
    end
    return unsafe_reconstruct(A, p, axs)
end

function Base.reverse(x::AbstractAxisIndices{T,1}) where {T}
    p = reverse(parent(x))
    return unsafe_reconstruct(x, p, (reverse_keys(axes(x, 1), axes(p, 1)),))
end

function Base.reverse(x::AbstractAxisIndices{T,N}; dims::Integer) where {T,N}
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


function Base.show(io::IO, x::AbstractAxisIndices; kwargs...)
    return show(io, MIME"text/plain"(), x, kwargs...)
end

function Base.show(io::IO, m::MIME"text/plain", x::AbstractAxisIndices{T,N}; kwargs...) where {T,N}
    println(io, "$(typeof(x).name.name){$T,$N,$(parent_type(x))...}")
    return show_array(io, parent(x), axes(x); kwargs...)
end

Base.has_offset_axes(A::AbstractAxisIndices) = Base.has_offset_axes(parent(A))

function Base.dropdims(a::AbstractAxisIndices; dims)
    return unsafe_reconstruct(a, dropdims(parent(a); dims=dims), drop_axes(a, dims))
end


function Base.pop!(A::AbstractAxisIndices{T,1}) where {T}
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end


function Base.popfirst!(A::AbstractAxisIndices{T,1}) where {T}
    shrink_first!(axes(A, 1), 1)
    return popfirst!(parent(A))
end


###
### Indexing
###
for (unsafe_f, f) in ((:unsafe_getindex, :getindex), (:unsafe_view, :view), (:unsafe_dotview, :dotview))
    @eval begin
        function $unsafe_f(
            A::AbstractArray{T,N},
            args::Tuple,
            inds::Tuple{Vararg{<:Integer}},
        ) where {T,N}

            return @inbounds(Base.$f(parent(A), inds...))
        end

        @propagate_inbounds function $unsafe_f(A, args::Tuple, inds::Tuple)
            p = Base.$f(parent(A), inds...)
            return unsafe_reconstruct(A, p, to_axes(A, args, inds, axes(p), false, Staticness(p)))
        end

        @propagate_inbounds function Base.$f(A::AbstractAxisIndices, args...)
            return $unsafe_f(A, args, to_indices(A, args))
        end
    end
end

@propagate_inbounds function Base.setindex!(a::AbstractAxisIndices, value, inds...)
    return setindex!(parent(a), value, to_indices(a, inds)...)
end


###
### Math
###
for f in (:sum!, :prod!, :maximum!, :minimum!)
    for (A,B) in ((AbstractAxisIndices, AbstractArray),
                  (AbstractArray,       AbstractAxisIndices),
                  (AbstractAxisIndices, AbstractAxisIndices))
        @eval begin
            function Base.$f(a::$A, b::$B)
                Base.$f(parent(a), parent(b))
                return a
            end
        end
    end
end


for f in (:cumsum, :cumprod)
    @eval function Base.$f(a::AbstractAxisIndices; dims, kwargs...)
        return unsafe_reconstruct(a, Base.$f(parent(a); dims=dims, kwargs...))
    end

    # Vector case
    @eval function Base.$f(a::AbstractAxisIndices{T,1}; kwargs...) where {T}
        return unsafe_reconstruct(a, Base.$f(parent(a); kwargs...))
    end
end

for f in (:(==), :isequal, :isapprox)
    @eval begin
        @inline Base.$f(a::AbstractAxisIndices, b::AbstractAxisIndices; kw...) = $f(parent(a), parent(b); kw...)
        @inline Base.$f(a::AbstractAxisIndices, b::AbstractArray; kw...) = $f(parent(a), b; kw...)
        @inline Base.$f(a::AbstractArray, b::AbstractAxisIndices; kw...) = $f(a, parent(b); kw...)
    end
end

for f in (:zero, :one, :copy)
    @eval begin
        function Base.$f(a::AbstractAxisIndices)
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
    function Base.has_fast_linear_indexing(x::AbstractAxisIndices)
        return Base.has_fast_linear_indexing(parent(x))
    end
end

"""
    reshape(A::AbstractAxisIndices, shape)

Reshape the array and axes of `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = reshape(AxisIndicesArray(Vector(1:8), [:a, :b, :c, :d, :e, :f, :g, :h]), 4, 2);

julia> axes(A)
(Axis([:a, :b, :c, :d] => Base.OneTo(4)), SimpleAxis(Base.OneTo(2)))

julia> axes(reshape(A, 2, :))
(Axis([:a, :b] => Base.OneTo(2)), SimpleAxis(Base.OneTo(4)))
```
"""
function Base.reshape(A::AbstractAxisIndices, shp::NTuple{N,Int}) where {N}
    p = reshape(parent(A), shp)
    return unsafe_reconstruct(A, p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

function Base.reshape(A::AbstractAxisIndices, shp::Tuple{Vararg{Union{Int,Colon},N}}) where {N}
    p = reshape(parent(A), shp)
    return unsafe_reconstruct(A, p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

for f in (:sort, :sort!)
    @eval function Base.$f(A::AbstractAxisIndices; dims, kwargs...)
        return unsafe_reconstruct(A, Base.$f(parent(A); dims=dims, kwargs...))
    end

    # Vector case
    @eval function Base.$f(a::AbstractAxisIndices{T,1}; kwargs...) where {T}
        return unsafe_reconstruct(a, Base.$f(parent(a); kwargs...))
    end
end

###
### I/O
###

function Base.unsafe_convert(::Type{Ptr{T}}, x::AbstractAxisIndices{T}) where {T}
    return Base.unsafe_convert(Ptr{T}, parent(x))
end

function Base.read!(io::IO, a::AbstractAxisIndices)
    read!(io, parent(a))
    return a
end

Base.write(io::IO, a::AbstractAxisIndices) = write(io, parent(a))

###
### rotations
###
"""
    rot180(A::AbstractAxisIndices)

Rotate `A` 180 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rot180(a);

julia> axes_keys(b)
(["b", "a"], ["two", "one"])

julia> c = rotr90(rotr90(a));

julia> axes_keys(c)
(["b", "a"], ["two", "one"])

julia> a["a", "one"] == b["a", "one"] == c["a", "one"]
true
```
"""
function Base.rot180(x::AbstractAxisIndices)
    p = rot180(parent(x))
    axs = (reverse_keys(axes(x, 1), axes(p, 1)), reverse_keys(axes(x, 2), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end


"""
    rotr90(A::AbstractAxisIndices)

Rotate `A` right 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotr90(a);

julia> axes_keys(b)
(["one", "two"], ["b", "a"])

julia> a["a", "one"] == b["one", "a"]
true
```
"""
function Base.rotr90(x::AbstractAxisIndices)
    p = rotr90(parent(x))
    axs = (assign_indices(axes(x, 2), axes(p, 1)), reverse_keys(axes(x, 1), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end

"""
    rotl90(A::AbstractAxisIndices)

Rotate `A` left 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotl90(a);

julia> axes_keys(b)
(["two", "one"], ["a", "b"])

julia> a["a", "one"] == b["one", "a"]
true

```
"""
function Base.rotl90(x::AbstractAxisIndices)
    p = rotl90(parent(x))
    axs = (reverse_keys(axes(x, 2), axes(p, 1)), assign_indices(axes(x, 1), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end

"""
    deleteat!(a::AbstractAxisIndicesVector, arg)

Remove the items corresponding to `A[arg]`, and return the modified `a`. Subsequent
items are shifted to fill the resulting gap. If the axis of `a` is an `AbstractSimpleAxis`
then it is shortened to match the length of `a`. If the 

## Examples
```jldoctest
julia> using AxisIndices

julia> x = AxisIndicesArray([1, 2, 3, 4]);

julia> axes_keys(deleteat!(x, 3))
(OneToMRange(3),)

julia> x = AxisIndicesArray([1, 2, 3, 4], ["a", "b", "c", "d"]);

julia> axes_keys(deleteat!(x, "c"))
(["a", "b", "d"],)

```
"""
function Base.deleteat!(A::AbstractAxisIndices{T,1,P,Tuple{Ax1}}, arg) where {T,P,Ax1<:AbstractSimpleAxis}
    inds = to_index(axes(A, 1), arg)
    shrink_last!(axes(A, 1), length(inds))
    deleteat!(parent(A), inds)
    return A
end

function Base.deleteat!(A::AbstractAxisIndices{T,1,P,Tuple{Ax1}}, arg) where {T,P,Ax1<:AbstractAxis}
    inds = to_index(axes(A, 1), arg)
    deleteat!(axes_keys(A, 1), inds)
    shrink_last!(indices(A, 1), length(inds))
    deleteat!(parent(A), inds)
    return A
end

function Base.resize!(x::AbstractAxisIndices{T,1}, n::Integer) where {T}
    resize!(parent(x), n)
    resize_last!(axes(x, 1), n)
    return x
end

function Base.push!(A::AbstractAxisIndices{T,1}, items...) where {T}
    grow_last!(axes(A, 1), length(items))
    push!(parent(A), items...)
    return A
end

function Base.pushfirst!(A::AbstractAxisIndices{T,1}, items...) where {T}
    grow_first!(axes(A, 1), length(items))
    pushfirst!(parent(A), items...)
    return A
end

function Base.empty!(a::AbstractAxisIndices)
    for ax_i in axes(a)
        if !can_set_length(ax_i)
            error("Cannot perform `empty!` on AbstractAxisIndices that has an axis with a fixed size.")
        end
    end

    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end

function Base.append!(A::AbstractAxisIndices{T,1}, collection) where {T}
    append_axis!(axes(A, 1), axes(collection, 1))
    append!(parent(A), collection)
    return A
end

for (tf, T, sf, S) in ((parent, :AbstractAxisIndicesVecOrMat, parent, :AbstractAxisIndicesVecOrMat),
                       (parent, :AbstractAxisIndicesVecOrMat, identity, :AbstractVecOrMat),
                       (identity, :AbstractVecOrMat,          parent,  :AbstractAxisIndicesVecOrMat))
    @eval function Base.vcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        p = vcat($tf(A), $sf(B))
        axs = Axes.vcat_axes(A, B, p)
        return vcat(AxisIndicesArray(p, axs), Cs...)
    end

    @eval function Base.hcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        p = hcat($tf(A), $sf(B))
        axs = Axes.hcat_axes(A, B, p)
        return hcat(AxisIndicesArray(p, axs), Cs...)
    end

    @eval function Base.cat(A::$T, B::$S, Cs::AbstractVecOrMat...; dims)
        p = cat($tf(A), $sf(B); dims=dims)
        return cat(AxisIndicesArray(p, Axes.cat_axes(A, B, p, dims)), Cs..., dims=dims)
    end
end

function Base.hcat(A::AbstractAxisIndices{T,N}) where {T,N}
    if N === 1
        return unsafe_reconstruct(A, hcat(parent(A)), (axes(A, 1), SimpleAxis(OneTo(1))))
    else
        return A
    end
end

Base.vcat(A::AbstractAxisIndices{T,N}) where {T,N} = A

Base.cat(A::AbstractAxisIndices{T,N}; dims) where {T,N} = A

