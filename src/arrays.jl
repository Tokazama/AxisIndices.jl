
_unsafe_reconstruct(arg::AbstractAxis) = arg
_unsafe_reconstruct(arg::Integer) = SimpleAxis(arg)
_unsafe_reconstruct(arg::AbstractUnitRange{T}) where {T<:Integer} = SimpleAxis(arg)
_unsafe_reconstruct(arg::AbstractVector, inds::AbstractUnitRange) = Axis(arg, inds)
function _unsafe_reconstruct(arg::AbstractUnitRange{T}, inds::AbstractUnitRange) where {T<:Integer}
    if (known_first(arg) !== nothing) && (known_first(arg) === known_first(inds))
        check_axis_length(arg, inds)
        if known_last(arg) === nothing
            return SimpleAxis(static_first(arg), static_last(inds))
        else
            return SimpleAxis(static_first(arg), static_last(arg))
        end
    else
        return OffsetAxis(arg, inds)
    end
end
_unsafe_reconstruct(arg::Function, inds::AbstractUnitRange) = arg(inds)



_to_axes(::Tuple{}, ::Tuple{}) = ()
_to_axes(::Tuple, ::Tuple{}) = ()
@inline _to_axes(::Tuple{}, inds::Tuple) = map(i -> _unsafe_reconstruct(i), inds)
@inline function _to_axes(args::Tuple, inds::Tuple)
    return (_unsafe_reconstruct(first(args), first(inds)), _to_axes(tail(args), tail(inds))...)
end

###
### Vectors
###

"""
    AxisVector

A vector whose indices have keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisVector([1, 2], [:a, :b])
2-element AxisArray{Int64,1}
 • dim_1 - [:a, :b]

  a   1
  b   2

```
"""
const AxisVector{T,P<:AbstractVector{T},Ax} = AxisArray{T,1,P,Tuple{Ax}}

function AxisVector{T}(x::AbstractVector{T}, ks::AbstractVector) where {T}
    axis = Axis(ks, axes(x, 1))
    return AxisArray{T,1,typeof(x),Tuple{typeof(axis)}}(x, (axis,))
end

AxisVector(x::AbstractVector{T}, ks::AbstractVector) where {T} = AxisVector{T}(x, ks)

AxisVector(x::AbstractVector) = AxisArray(x)

function AxisVector{T}() where {T}
    return AxisArray{T,1,Vector{T},Tuple{SimpleAxis{Int,OneToMRange{Int}}}}(
        T[], (SimpleAxis(OneToMRange(0)),)
    )
end

function Base.append!(A::AxisVector{T}, collection) where {T}
    append_axis!(axes(A, 1), collection)
    append!(parent(A), collection)
    return A
end

function Base.pop!(A::AxisVector)
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end


function Base.popfirst!(A::AxisVector)
    Axes.popfirst_axis!(axes(A, 1))
    return popfirst!(parent(A))
end

function Base.reverse(x::AxisVector)
    p = reverse(parent(x))
    return AxisArray(p, (reverse_keys(axes(x, 1), axes(p, 1)),))
end

"""
    deleteat!(a::AxisVector, arg)

Remove the items corresponding to `A[arg]`, and return the modified `a`. Subsequent
items are shifted to fill the resulting gap. If the axis of `a` is an `SimpleAxis`
then it is shortened to match the length of `a`.

## Examples
```jldoctest
julia> using AxisIndices

julia> x = AxisArray([1, 2, 3, 4]);

julia> axes_keys(deleteat!(x, 3))
(OneToMRange(3),)

julia> x = AxisArray([1, 2, 3, 4], ["a", "b", "c", "d"]);

julia> axes_keys(deleteat!(x, "c"))
(["a", "b", "d"],)

```
"""
function Base.deleteat!(A::AxisVector{T,P,Ax}, arg) where {T,P,Ax}
    if is_indices_axis(Ax)
        inds = to_index(axes(A, 1), arg)
        shrink_last!(axes(A, 1), length(inds))
        deleteat!(parent(A), inds)
        return A
    else
        inds = to_index(axes(A, 1), arg)
        deleteat!(axes_keys(A, 1), inds)
        shrink_last!(indices(A, 1), length(inds))
        deleteat!(parent(A), inds)
        return A
    end
end

function Base.insert!(A::AxisVector, index, item)
    if can_change_size(A)
        axis = axes(A, 1)
        unsafe_insert!(parent(A), axis, to_index(axis, index), item)
        return A
    else
        throw(MethodError(insert!, (A, index, item)))
    end
end

function unsafe_insert!(data::AbstractVector{T}, axis, index::Int, item::I) where {T,I}
    unsafe_insert!(data, axis, index, convert(T, item))
    return nothing
end

function unsafe_insert!(data::AbstractVector{T}, axis, index::Int, item::I) where {T,I<:T}
    grow_last!(axis, 1)
    insert!(data, index, item)
    return nothing
end

function Base.resize!(x::AxisVector, n::Integer)
    resize!(parent(x), n)
    resize_last!(axes(x, 1), n)
    return x
end

function Base.push!(A::AxisVector, item)
    StaticRanges.can_set_last(axes(A, 1)) || throw(MethodError(push!, (A, item)))
    push!(parent(A), item)
    grow_last!(axes(A, 1), 1)
    return A
end

function Base.push!(A::AxisVector, item::Pair)
    axis = axes(A, 1)
    StaticRanges.can_set_last(axis) || throw(MethodError(push!, (A, item)))
    push!(parent(A), last(item))
    Axes.push_key!(axis, first(item))
    return A
end

function Base.pushfirst!(A::AxisVector, item)
    can_change_size(A) || throw(MethodError(pushfirst!, (A, item)))
    Axes.pushfirst_axis!(axes(A, 1))
    pushfirst!(parent(A), item)
    return A
end

function Base.pushfirst!(A::AxisVector, item::Pair)
    axis = axes(A, 1)
    StaticRanges.can_set_first(axis) || throw(MethodError(pushfirst!, (A, item)))
    pushfirst!(parent(A), last(item))
    Axes.pushfirst_axis!(axis, first(item))
    return A
end

###
### Matrix methods
###
const AxisMatrix{T,P<:AbstractMatrix{T},Ax1,Ax2} = AxisArray{T,2,P,Tuple{Ax1,Ax2}}

"""
    rot180(A::AxisMatrix)

Rotate `A` 180 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

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
function Base.rot180(x::AxisMatrix)
    p = rot180(parent(x))
    axs = (reverse_keys(axes(x, 1), axes(p, 1)), reverse_keys(axes(x, 2), axes(p, 2)))
    return AxisArray{eltype(p),2,typeof(p),typeof(axs)}(p, axs)
end

"""
    rotr90(A::AxisMatrix)

Rotate `A` right 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotr90(a);

julia> axes_keys(b)
(["one", "two"], ["b", "a"])

julia> a["a", "one"] == b["one", "a"]
true
```
"""
function Base.rotr90(x::AxisMatrix)
    p = rotr90(parent(x))
    axs = (assign_indices(axes(x, 2), axes(p, 1)), reverse_keys(axes(x, 1), axes(p, 2)))
    return AxisArray{eltype(p),2,typeof(p),typeof(axs)}(p, axs)
end

"""
    rotl90(A::AxisMatrix)

Rotate `A` left 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotl90(a);

julia> axes_keys(b)
(["two", "one"], ["a", "b"])

julia> a["a", "one"] == b["one", "a"]
true

```
"""
function Base.rotl90(x::AxisMatrix)
    p = rotl90(parent(x))
    axs = (reverse_keys(axes(x, 2), axes(p, 1)), assign_indices(axes(x, 1), axes(p, 2)))
    return AxisArray{eltype(p),2,typeof(p),typeof(axs)}(p, axs)
end

###
### VecOrMat
###
const AxisVecOrMat{T} = Union{<:AxisMatrix{T},<:AxisVector{T}}

###
### reduce
###
function reconstruct_reduction(old_array, new_array, dims)
    return AxisArray(new_array, reduce_axes(axes(old_array), axes(new_array), dims))
end
reconstruct_reduction(old_array, new_array, dims::Colon) = new_array

function Base.mapslices(f, a::AxisArray; dims, kwargs...)
    return reconstruct_reduction(a, Base.mapslices(f, parent(a); dims=dims, kwargs...), dims)
end

function Base.mapreduce(f1, f2, a::AxisArray; dims=:, kwargs...)
    return reconstruct_reduction(a, Base.mapreduce(f1, f2, parent(a); dims=dims, kwargs...), dims)
end

function Base.extrema(A::AxisArray; dims=:, kwargs...)
    return reconstruct_reduction(A, Base.extrema(parent(A); dims=dims, kwargs...), dims)
end

if VERSION > v"1.2"
    function Base.has_fast_linear_indexing(x::AxisArray)
        return Base.has_fast_linear_indexing(parent(x))
    end
end

for f in (:mean, :std, :var, :median)
    @eval function Statistics.$f(a::AxisArray; dims=:, kwargs...)
        return reconstruct_reduction(a, Statistics.$f(parent(a); dims=dims, kwargs...), dims)
    end
end

"""
    reshape(A::AxisArray, shape)

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
function Base.reshape(A::AxisArray, shp::NTuple{N,Int}) where {N}
    p = reshape(parent(A), shp)
    return AxisArray(p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

function Base.reshape(A::AxisArray, shp::Tuple{Vararg{Union{Int,Colon},N}}) where {N}
    p = reshape(parent(A), shp)
    return AxisArray(p, reshape_axes(naxes(A, Val(N)), axes(p)))
end

for f in (:sort, :sort!)
    @eval function Base.$f(A::AxisArray; dims, kwargs...)
        p = Base.$f(parent(A); dims=dims, kwargs...)
        return AxisArray(p, map(assign_indices, axes(a), axes(p)))
    end

    # Vector case
    @eval function Base.$f(a::AxisArray{T,1}; kwargs...) where {T}
        p = Base.$f(parent(A); kwargs...)
        return AxisArray(p, map(assign_indices, axes(a), axes(p)))
    end
end

###
### init_array
###

_length(x::Integer) = x
_length(x) = length(x)

function init_array(::Type{T}, init::ArrayInitializer, axs::NTuple{N,Any}) where {T,N}
    create_static_array = true
    for i in 1:N
        is_static(getfield(axs, i)) || return Array{T,N}(init, map(_length, axs))
    end
    return MArray{Tuple{map(_length, axs)...},T,N}(init)
end

#=
function static_init_array(::Type{T}, init::ArrayInitializer, sz::NTuple{N,Any}) where {T,N}
    return
end

function fixed_init_array(::Fixed, ::Type{T}, init::ArrayInitializer, sz::NTuple{N,Any}) where {T,N}
    return
end

# TODO
# Currently, the only dynamic array we support is Vector, eventually it would be
# nice if we could support >1 dimensions being dynamic
function init_array(::Dynamic, ::Type{T}, init::ArrayInitializer, sz::NTuple{N,Any}) where {T,N}
    return Array{T,N}(undef, map(_length, sz))
end
=#

Base.dataids(A::AxisArray) = Base.dataids(parent(A))

function Base.zeros(::Type{T}, axs::Tuple{Vararg{<:AbstractAxis}}) where {T}
    p = zeros(T, map(length, axs))
    return AxisArray(p, axs, axes(p), false)
end

function Base.falses(axs::Tuple{Vararg{<:AbstractAxis}})
    p = falses(map(length, axs))
    return AxisArray(p, axs, axes(p), false)
end

function Base.fill(x, axs::Tuple{Vararg{<:AbstractAxis}})
    p = fill(x, map(length, axs))
    return AxisArray(p, axs, axes(p), false)
end

function Base.reshape(A::AbstractArray, shp::Tuple{<:AbstractAxis,Vararg{<:AbstractAxis}})
    p = reshape(parent(A), map(length, shp))
    axs = reshape_axes(naxes(shp, Val(length(shp))), axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs)
end

#StaticRanges.axes_type(::Type{<:AxisArray{T,N,P,AI}}) where {T,N,P,AI} = AI
#StaticRanges.axes_type(::Type{<:AxisArray{T,N,P,AI}}, i::Int) where {T,N,P,AI} = AI.parameters[i]

###
### similar
###
@inline function Base.similar(A::AxisArray{T}, dims::Tuple{Vararg{Int}}) where {T}
    return similar(A, T, dims)
end

function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{Union{Integer,OneTo}}}) where {T}
    p = similar(parent(A), T, dims)
    return AxisArray(p, to_axes(axes(A), ks, axes(p), false))
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Union{Integer, Base.OneTo},Vararg{Union{Integer, Base.OneTo}}}) where {T}
    p = similar(parent(A), T, dims)
    return AxisArray(p, to_axes(axes(A), ks, axes(p), false))
end

function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{Int}}) where {T}
    p = similar(parent(A), T, dims)
    return AxisArray(p, to_axes(axes(A), ks, axes(p), false))
end

  #=
function Base.similar(
    A::AxisArray,
    ::Type{T},
    ks::Tuple{Union{Base.IdentityUnitRange, OneTo, UnitRange,Integer},
              Vararg{Union{Base.IdentityUnitRange, OneTo, UnitRange,Integer},N}}
) where {T, N}

    p = similar(parent(A), T, map(length, ks))
    return AxisArray(p, to_axes(axes(A), ks, axes(p), false))
end
@inline function Base.similar(A::AxisArray{T}, ks::Tuple{Vararg{<:AbstractVector}}) where {T}
    return similar(A, T, ks)
end

@inline function Base.similar(A::AxisArray, ::Type{T}, ks::Tuple{Vararg{<:AbstractVector,N}}) where {T,N}
    p = similar(parent(A), T, map(length, ks))
    return AxisArray(p, to_axes(axes(A), ks, axes(p), false))
end

# Necessary to avoid ambiguities with OffsetArrays
@inline function Base.similar(A::AxisArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    p = similar(parent(A), T, dims)
    return AxisArray(p, to_axes(axes(A), (), axes(p), false))
end

function Base.similar(A::AxisArray, ::Type{T}) where {T}
    p = similar(parent(A), T)
    return AxisArray(p, map(unsafe_reconstruct, axes(A), axes(p)))
end

function Base.similar(A::AxisArray, ::Type{T}, ks::Tuple{OneTo,Vararg{OneTo,N}}) where {T, N}
    p = similar(parent(A), T, map(length, ks))
    return AxisArray(p, to_axes(axes(A), ks, axes(p), false))
end

function Base.similar(::Type{T}, ks::Tuple{Vararg{<:AbstractAxis,N}}) where {T<:AbstractArray, N}
    p = similar(T, map(length, ks))
    axs = to_axes((), ks, axes(p), false)
    return AxisArray{eltype(T),N,typeof(p),typeof(axs)}(p, axs)
end

# Necessary to avoid ambiguities with OffsetArrays
@inline function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{<:Integer,N}}) where {T,N}
    p = similar(parent(A), T, dims)
    return AxisArray(p, to_axes(axes(A), (), axes(p), false))
end

=#

# FIXME
# When I use Val(N) on the tuple the it spits out many lines of extra code.
# But without it it loses inferrence
function Base.reinterpret(::Type{Tnew}, A::AxisArray{Told,N}) where {Tnew,Told,N}
    p = reinterpret(Tnew, parent(A))
    axs = ntuple(N) do i
        resize_last(axes(A, i), size(p, i))
    end
    return AxisArray(p, axs)
end

function Base.reverse(x::AxisArray{T,N}; dims::Integer) where {T,N}
    p = reverse(parent(x), dims=dims)
    axs = ntuple(Val(N)) do i
        if i in dims
            reverse_keys(axes(x, i), axes(p, i))
        else
            assign_indices(axes(x, i), axes(p, i))
        end
    end
    return AxisArray(p, axs)
end

Base.has_offset_axes(A::AxisArray) = Base.has_offset_axes(parent(A))

function Base.dropdims(a::AxisArray; dims)
    return AxisArray(dropdims(parent(a); dims=dims), drop_axes(a, dims))
end

###
### Indexing
###
function unsafe_view(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.view(parent(A), inds...))
end

function unsafe_view(A, args::Tuple, inds::Tuple)
    p = view(parent(A), inds...)
    return AxisArray(p, to_axes(A, args, axes(p)))
end

function unsafe_dotview(A, args::Tuple, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.dotview(parent(A), inds...))
end

function unsafe_dotview(A, args::Tuple, inds::Tuple)
    p = Base.dotview(parent(A), inds...)
    return AxisArray(p, to_axes(A, args, inds))
end

@propagate_inbounds function Base.getindex(A::AxisArray, gr::StaticRanges.GapRange)
    return unsafe_getindex(A, (gr,), to_indices(A, (gr,)))
end

Base.getindex(A::AxisArray, ::Ellipsis) = A

unsafe_setindex!(a::AxisArray, value, args, inds) = setindex!(parent(a), value, inds)

for (unsafe_f, f) in ((:unsafe_getindex, :getindex),
                      (:unsafe_view, :view),
                      (:unsafe_dotview, :dotview),
                      (:unsafe_setindex!, :setindex!)
                     )
    @eval begin
        @propagate_inbounds function Base.$f(A::AxisArray, args...)
            if should_flatten(args)
                return $f(A, flatten_args(A, args)...)
            else
                return $unsafe_f(A, args, to_indices(A, args))
            end
        end
    end
end

###
### Math
###
for f in (:sum!, :prod!, :maximum!, :minimum!)
    for (A,B) in ((AxisArray, AbstractArray),
                  (AbstractArray,       AxisArray),
                  (AxisArray, AxisArray))
        @eval begin
            function Base.$f(a::$A, b::$B)
                Base.$f(parent(a), parent(b))
                return a
            end
        end
    end
end

for f in (:cumsum, :cumprod)
    @eval function Base.$f(a::AxisArray; dims, kwargs...)
        p = Base.$f(parent(a); dims=dims, kwargs...)
        return AxisArray(p, map(assign_indices, axes(a), axes(p)))
    end

    # Vector case
    @eval function Base.$f(a::AxisArray{T,1}; kwargs...) where {T}
        p = Base.$f(parent(a); kwargs...)
        return AxisArray(p, map(assign_indices, axes(a), axes(p)))
    end
end

Base.isapprox(a::AxisArray, b::AxisArray; kw...) = isapprox(parent(a), parent(b); kw...)
Base.isapprox(a::AxisArray, b::AbstractArray; kw...) = isapprox(parent(a), b; kw...)
Base.isapprox(a::AbstractArray, b::AxisArray; kw...) = isapprox(a, parent(b); kw...)

Base.:(==)(a::AxisArray, b::AxisArray) = ==(parent(a), parent(b))
Base.:(==)(a::AxisArray, b::AbstractArray) = ==(parent(a), b)
Base.:(==)(a::AbstractArray, b::AxisArray) = ==(a, parent(b))
Base.:(==)(a::AxisArray, b::AbstractAxis) = ==(parent(a), b)
Base.:(==)(a::AbstractAxis, b::AxisArray) = ==(a, parent(b))
Base.:(==)(a::AxisArray, b::GapRange) = ==(parent(a), b)
Base.:(==)(a::GapRange, b::AxisArray) = ==(a, parent(b))

Base.:isequal(a::AxisArray, b::AxisArray) = isequal(parent(a), parent(b))
Base.:isequal(a::AxisArray, b::AbstractArray) = isequal(parent(a), b)
Base.:isequal(a::AbstractArray, b::AxisArray) = isequal(a, parent(b))
Base.:isequal(a::AxisArray, b::AbstractAxis) = isequal(parent(a), b)
Base.:isequal(a::AbstractAxis, b::AxisArray) = isequal(a, parent(b))

Base.copy(A::AxisArray) = AxisArray(copy(parent), map(copy, axes(A)))

for f in (:zero, :one)
    @eval begin
        function Base.$f(a::AxisArray)
            p = Base.$f(parent(a))
            return AxisArray(p, map(assign_indices, axes(a), axes(p)))
        end
    end
end

###
### I/O
###

function Base.unsafe_convert(::Type{Ptr{T}}, x::AxisArray{T}) where {T}
    return Base.unsafe_convert(Ptr{T}, parent(x))
end

function Base.read!(io::IO, a::AxisArray)
    read!(io, parent(a))
    return a
end

Base.write(io::IO, a::AxisArray) = write(io, parent(a))

function Base.empty!(a::AxisArray)
    for ax_i in axes(a)
        if !can_set_length(ax_i)
            error("Cannot perform `empty!` on AxisArray that has an axis with a fixed size.")
        end
    end

    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end

for (tf, T, sf, S) in (
    (parent, :AxisVecOrMat, parent, :AxisVecOrMat),
    (parent, :AxisVecOrMat, identity, :VecOrMat),
    (identity, :VecOrMat, parent, :AxisVecOrMat))
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

function Base.hcat(A::AxisArray{T,N}) where {T,N}
    if N === 1
        return AxisArray(hcat(parent(A)), (axes(A, 1), axes(A, 2)))
    else
        return A
    end
end

Base.vcat(A::AxisArray{T,N}) where {T,N} = A

Base.cat(A::AxisArray{T,N}; dims) where {T,N} = A

function Base.convert(::Type{T}, A::AbstractArray) where {T<:AxisArray}
    if A isa T
        return A
    else
        return T(A)
    end
end

Base.LogicalIndex(A::AxisArray) = Base.LogicalIndex(parent(A))

const ReinterpretAxisArray{T,N,S,A<:AxisArray{S,N}} = ReinterpretArray{T,N,S,A}

function Base.axes(A::ReinterpretAxisArray{T,N,S}) where {T,N,S}
    paxs = axes(parent(A))
    axis_1 = first(paxs)
    len = div(length(axis_1) * sizeof(S), sizeof(T))
    return tuple(resize_last(axis_1, len), tail(paxs)...)
end

function Base.collect(A::AxisArray)
    p = collect(parent(A))
    return AxisArray(p, map(assign_indices,  axes(A), axes(p)))
end

#=
function size(a::ReinterpretArray{T,N,S} where {N}) where {T,S}
    psize = size(a.parent)
    size1 = div(psize[1]*sizeof(S), sizeof(T))
    tuple(size1, tail(psize)...)
end
=#

function Base.permutedims(A::AxisArray{T,N}, perms) where {T,N}
    p = permutedims(parent(A), perms)
    axs = ntuple(Val(N)) do i
        assign_indices(axes(A, perms[i]), axes(p, i))
    end
    return AxisArray(p, axs)
end


@inline function Base.selectdim(A::AxisArray{T,N}, d::Integer, i) where {T,N}
    axs = ntuple(N) do dim_i
        if dim_i == d
            i
        else
            (:)
        end
    end
    return view(A, axs...)
end


"""
    diag(M::AxisMatrix, k::Integer=0; dim::Val=Val(1))

The `k`th diagonal of an `AxisMatrixMatrix`, `M`. The keyword argument
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
function LinearAlgebra.diag(M::AxisArray, k::Integer=0; dim::Val{D}=Val(1)) where {D}
    p = diag(parent(M), k)
    return AxisArray(p, (StaticRanges.shrink_last(axes(M, D), axes(p, 1)),))
end

"""
    inv(M::AxisMatrix)

Computes the inverse of an `AxisMatrixMatrix`
```jldoctest
julia> using AxisIndices, LinearAlgebra

julia> M = AxisArray([2 5; 1 3], ["a", "b"], [:one, :two]);

julia> axes_keys(inv(M))
([:one, :two], ["a", "b"])

```
"""
function Base.inv(A::AxisArray)
    p = inv(parent(A))
    axs = (assign_indices(axes(A, 2), axes(p, 1)), assign_indices(axes(A, 1), axes(A, 2)))
    return AxisArray(p, axs)
end

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv))
    @eval begin
        function $f(A::AxisArray)
            p = $f(parent(A))
            return AxisArray(p, permute_axes(A, p))
        end
    end
end

function Base.sortslices(A::AxisArray; dims, kwargs...)
    return _sortslices(A, Val{dims}(); kwargs...)
end

function _sortslices(A, d::Val{dims}; kws...) where dims
    itspace = Base.compute_itspace(parent(A), d)
    vecs = map(its->view(parent(A), its...), itspace)
    p = sortperm(vecs; kws...)
    B = similar(A)
    for (x, its) in zip(p, itspace)
        B[map(Indices, its)...] = vecs[x]
    end
    return B
end

"""
    permuteddimsview(A, perm)

returns a "view" of `A` with its dimensions permuted as specified by
`perm`. This is like `permutedims`, except that it produces a view
rather than a copy of `A`; consequently, any manipulations you make to
the output will be mirrored in `A`. Compared to the copy, the view is
much faster to create, but generally slower to use.
"""
permuteddimsview(A, perm) = PermutedDimsArray(A, perm)
function permuteddimsview(A::AxisArray, perm)
    p = PermutedDimsArray(parent(A), perm)
    return AxisArray(p, permute_axes(A, p, perm))
end

for f in (:map, :map!)
    # Here f::F where {F} is needed to avoid ambiguities in Julia 1.0
    @eval begin
        function Base.$f(f::F, a::AbstractArray, b::AxisArray, cs::AbstractArray...) where {F}
            return AxisArray(
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AxisArray, b::AxisArray, cs::AbstractArray...) where {F}
            return AxisArray(
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AxisArray, b::AbstractArray, cs::AbstractArray...) where {F}
            return AxisArray(
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end
    end
end

Base.map(f, A::AxisArray) = AxisArray(map(f, parent(A)), axes(A))

# We can't just make a type alias for mapped array types because this would require
# multiple calls to combine_axes for multi-mapped types for every axes call. It also
# would require overloading a bunch of other methods to ensure they work correctly
# (e.g., getindex, setindex!, view, show, etc...)
#
# We can't directly overload the head of each method because data::AbstractArray....
# is too similar to Union{AxisArray,AbstractArray} so we only specialize
# on method heads that handle all AxisArray subtypes. Therefore, including
# any other array type will miss these specific methods.

function MappedArrays.mappedarray(f, data::AxisArray)
    return AxisArray(data, mappedarray(f, parent(data)), axes(data))
end

function MappedArrays.mappedarray(::Type{T}, data::AxisArray) where T
    return AxisArray(mappedarray(T, parent(data)), axes(data))
end

function MappedArrays.mappedarray(f, data::AxisArray...)
    return AxisArray(
        mappedarray(f, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, data::AxisArray...) where T
    return AxisArray(
        mappedarray(T, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

# These needed to have the additional ::Function defined to avoid ambiguities
function MappedArrays.mappedarray(f, finv::Function, data::AxisArray)
    return AxisArray(mappedarray(f, finv, parent(data)), axes(data))
end

function MappedArrays.mappedarray(f, finv::Function, data::AxisArray...)
    return AxisArray(
        mappedarray(f, finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, finv::Function, data::AxisArray...) where T
    return AxisArray(
        mappedarray(T, finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(f, ::Type{Finv}, data::AxisArray...) where Finv
    return AxisArray(
        mappedarray(f, Finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, ::Type{Finv}, data::AxisArray...) where {T,Finv}
    return AxisArray(
        mappedarray(T, Finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

#
#    AxisArrayStyle{S}
#
# This is a `BroadcastStyle` for AxisArray's It preserves the dimension
# names. `S` should be the `BroadcastStyle` of the wrapped type.
struct AxisArrayStyle{S <: BroadcastStyle} <: AbstractArrayStyle{Any} end
AxisArrayStyle(::S) where {S} = AxisArrayStyle{S}()
AxisArrayStyle(::S, ::Val{N}) where {S,N} = AxisArrayStyle(S(Val(N)))
AxisArrayStyle(::Val{N}) where N = AxisArrayStyle{DefaultArrayStyle{N}}()
function AxisArrayStyle(a::BroadcastStyle, b::BroadcastStyle)
    inner_style = BroadcastStyle(a, b)

    # if the inner_style is Unknown then so is the outer-style
    if inner_style isa Unknown
        return Unknown()
    else
        return AxisArrayStyle(inner_style)
    end
end

function Base.BroadcastStyle(::Type{T}) where {T<:AxisArray}
    return AxisArrayStyle{typeof(BroadcastStyle(parent_type(T)))}()
end

Base.BroadcastStyle(::AxisArrayStyle{A}, ::AxisArrayStyle{B}) where {A, B} = AxisArrayStyle(A(), B())
#Base.BroadcastStyle(::AxisArrayStyle{A}, b::B) where {A, B} = AxisArrayStyle(A(), b)
#Base.BroadcastStyle(a::A, ::AxisArrayStyle{B}) where {A, B} = AxisArrayStyle(a, B())
Base.BroadcastStyle(::AxisArrayStyle{A}, b::DefaultArrayStyle) where {A} = AxisArrayStyle(A(), b)
Base.BroadcastStyle(a::AbstractArrayStyle{M}, ::AxisArrayStyle{B}) where {B,M} = AxisArrayStyle(a, B())

#
#    unwrap_broadcasted
#
# Recursively unwraps `AxisArray`s and `AxisArrayStyle`s.
# replacing the `AxisArray`s with the wrapped array,
# and `AxisArrayStyle` with the wrapped `BroadcastStyle`.
function unwrap_broadcasted(bc::Broadcasted{AxisArrayStyle{S}}) where S
    return Broadcasted{S}(bc.f, map(unwrap_broadcasted, bc.args))
end
unwrap_broadcasted(a::AxisArray) = parent(a)
unwrap_broadcasted(x) = x

get_first_axis_indices(bc::Broadcasted) = _get_first_axis_indices(bc.args)
_get_first_axis_indices(args::Tuple{Any,Vararg{Any}}) = _get_first_axis_indices(tail(args))
_get_first_axis_indices(args::Tuple{<:AxisArray,Vararg{Any}}) = first(args)
_get_first_axis_indices(args::Tuple{}) = nothing

# We need to implement copy because if the wrapper array type does not support setindex
# then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{AxisArrayStyle{S}}) where S
    return AxisArray(copy(unwrap_broadcasted(bc)), Broadcast.combine_axes(bc.args...))
end

function Base.copyto!(
    dest::AxisArray,
    ds::Integer,
    src::AxisArray,
    ss::Integer,
    n::Integer
)
    return copyto!(
        parent(dest),
        to_index(eachindex(dest), ds),
        parent(src),
        to_index(eachindex(src), ss),
        n
    )
end
function Base.copyto!(
    dest::AbstractArray,
    ds::Integer,
    src::AxisArray,
    ss::Integer,
    n::Integer
)

    copyto!(dest, ds, parent(src), to_index(eachindex(src), ss), n)
end

function Base.copyto!(
    dest::AxisArray,
    ds::Integer,
    src::AbstractArray,
    ss::Integer,
    n::Integer
)

    return copyto!(parent(dest), to_index(eachindex(dest), ds), src, ss, n)
end

function Base.copyto!(dest::AxisArray, dstart::Integer, src::AbstractArray)
    return copyto!(parent(dest), to_index(eachindex(dest), dstart), src)
end

function Base.copyto!(dest::AxisArray, dstart::Integer, src::AxisArray)
    return copyto!(parent(dest), to_index(eachindex(dest), dstart), parent(src))
end

function Base.copyto!(dest::AbstractArray, dstart::Integer, src::AxisArray)
    return copyto!(dest, dstart, parent(src))
end

function Base.copyto!(dest::AxisArray{T,2}, src::SparseArrays.AbstractSparseMatrixCSC) where {T}
    return copyto!(parent(dest), src)
end

Base.copyto!(dest::AxisArray, src::AxisArray) = copyto!(parent(dest), parent(src))
Base.copyto!(dest::AbstractArray, src::AxisArray) = copyto!(dest, parent(src))
Base.copyto!(dest::AxisArray, src::AbstractArray) = copyto!(parent(dest), src)
Base.copyto!(dest::SparseVector, src::AxisArray{T,1}) where {T} = copyto!(dest, parent(src))
Base.copyto!(dest::PermutedDimsArray, src::AxisArray) = copyto!(dest, parent(src))
Base.copyto!(dest::AxisArray, src::SuiteSparse.CHOLMOD.Dense) = copyto!(parent(dest), src)
