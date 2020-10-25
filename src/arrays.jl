
Base.strides(A::AxisArray) = strides(parent(A))

"""
    AxisVector

A vector whose indices have keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisVector([1, 2], [:a, :b])
2-element AxisArray(::Array{Int64,1}
  • axes:
     1 = [:a, :b]
)
      1
  :a  1
  :b  2  

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

@inline function append_axis!(x::Axis{K,I,Ks,Inds}, y) where {K,I,Ks,Inds}
    if Ks <: AbstractRange
        set_length!(values(x), length(x) + length(y))
    else
        if any(in(keys(x)), keys(y))
            error("Cannot append axis keys that are not unique from each other.")
        else
            append!(keys(x), keys(y))
        end
    end
end
function Base.append!(A::AxisVector{T,V,Ax}, collection) where {T,V,Ax}
    if Ax <: Axis
        append_axis!(axes(A, 1), axes(collection, 1))
    else
        set_length!(axes(A, 1), length(A) + length(collection))
    end
    append!(parent(A), collection)
    return A
end

function Base.pop!(A::AxisVector)
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end

function Base.popfirst!(A::AxisVector)
    popfirst_axis!(axes(A, 1))
    return popfirst!(parent(A))
end

function Base.reverse(x::AxisVector)
    p = reverse(parent(x))
    return AxisArray(p, (reverse_keys(axes(x, 1), axes(p, 1)),); checks=NoChecks)
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

julia> deleteat!(x, 3)
3-element AxisArray(::Array{Int64,1}
  • axes:
     1 = 1:3
)
     1
  1  1
  2  2
  3  4  

julia> x = AxisArray([1, 2, 3, 4], ["a", "b", "c", "d"]);

julia> keys.(axes(deleteat!(x, "c")))
(["a", "b", "d"],)

```
"""
function Base.deleteat!(A::AxisVector{T,P,Ax}, arg) where {T,P,Ax}
    if Ax<:Axis
        inds = to_index(axes(A, 1), arg)
        deleteat!(keys(axes(A, 1)), inds)
        shrink_last!(parent(axes(A, 1)), length(inds))
        deleteat!(parent(A), inds)
        return A
    else
        inds = to_index(axes(A, 1), arg)
        shrink_last!(axes(A, 1), length(inds))
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

julia> keys.(axes(b))
(["b", "a"], ["two", "one"])

julia> c = rotr90(rotr90(a));

julia> keys.(axes(c))
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

julia> keys.(axes(b))
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

julia> keys.(axes(b))
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
(Axis([:a, :b, :c, :d] => SimpleAxis(1:4)), SimpleAxis(1:2))

julia> axes(reshape(A, 2, :))
(Axis([:a, :b] => SimpleAxis(1:2)), SimpleAxis(1:4))

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
        return AxisArray(p, map(assign_indices, axes(A), axes(p)))
    end

    # Vector case
    @eval function Base.$f(A::AxisArray{T,1}; kwargs...) where {T}
        p = Base.$f(parent(A); kwargs...)
        return AxisArray(p, map(assign_indices, axes(A), axes(p)))
    end
end

###
### init_array
###

_length(x::Integer) = x
_length(x) = length(x)

#= TODO replace this with what's in VectorizationBase.jl
function init_array(::Type{T}, init::ArrayInitializer, axs::NTuple{N,Any}) where {T,N}
    create_static_array = true
    for i in 1:N
        is_static(getfield(axs, i)) || return Array{T,N}(init, map(_length, axs))
    end
    return MArray{Tuple{map(_length, axs)...},T,N}(init)
end
=#
function init_array(::Type{T}, init::ArrayInitializer, axs::NTuple{N,Any}) where {T,N}
    return Array{T,N}(init, map(_length, axs))
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
    return AxisArray(zeros(T, map(length, axs)), axs; NoChecks)
end

function Base.falses(axs::Tuple{Vararg{<:AbstractAxis}})
    return AxisArray(falses(map(length, axs)), axs; NoChecks)
end

function Base.fill(x, axs::Tuple{Vararg{<:AbstractAxis}})
    return AxisArray(fill(x, map(length, axs)), axs; NoChecks)
end

function Base.reshape(A::AbstractArray, shp::Tuple{<:AbstractAxis,Vararg{<:AbstractAxis}})
    p = reshape(parent(A), map(length, shp))
    axs = reshape_axes(naxes(shp, Val(length(shp))), axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end

#StaticRanges.axes_type(::Type{<:AxisArray{T,N,P,AI}}) where {T,N,P,AI} = AI
#StaticRanges.axes_type(::Type{<:AxisArray{T,N,P,AI}}, i::Int) where {T,N,P,AI} = AI.parameters[i]

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

###
### Indexing
###
function unsafe_view(A, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.view(parent(A), apply_offsets(A, inds)...))
end

function unsafe_view(A, inds::Tuple)
    p = @inbounds(Base.view(parent(A), apply_offsets(A, inds)...))
    return unsafe_reconstruct(A, p; axes=to_axes(A, inds))
end

function unsafe_dotview(A, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.dotview(parent(A), _sub_offset(A, inds)...))
end

function unsafe_dotview(A, inds::Tuple)
    p = @inbounds(Base.dotview(parent(A), _sub_offset(A, inds)...))
    return AxisArray(p, to_axes(A, axes(p)))
end

@propagate_inbounds function Base.getindex(A::AxisArray, args...)
    return ArrayInterface.getindex(A, args...)
end

Base.getindex(A::AxisArray, ::Ellipsis) = A

@propagate_inbounds function Base.setindex!(A::AxisArray, val, args...)
    return ArrayInterface.setindex!(A, val, args...)
end

for (unsafe_f, f) in ((:unsafe_view, :view),
                      (:unsafe_dotview, :dotview),
                     )
    @eval begin
        @propagate_inbounds function Base.$f(A::AxisArray, args...)
            return unsafe_view(A, to_indices(A, args))
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

function Base.unsafe_convert(::Type{Ptr{T}}, x::AxisArray{T}) where {T}
    return Base.unsafe_convert(Ptr{T}, parent(x))
end

function Base.read!(io::IO, a::AxisArray)
    read!(io, parent(a))
    return a
end

Base.write(io::IO, a::AxisArray) = write(io, parent(a))

function Base.empty!(a::AxisArray)
    for axis in axes(a)
        if !can_set_length(axis)
            error("Cannot perform `empty!` on AxisArray that has an axis with a fixed size.")
        end
    end

    for axis in axes(a)
        empty!(axis)
    end
    empty!(parent(a))
    return a
end

function Base.convert(::Type{T}, A::AbstractArray) where {T<:AxisArray}
    if A isa T
        return A
    else
        return T(A)
    end
end

const ReinterpretAxisArray{T,N,S,A<:AxisArray{S,N}} = ReinterpretArray{T,N,S,A}

function Base.axes(A::ReinterpretAxisArray{T,N,S}) where {T,N,S}
    paxs = axes(parent(A))
    axis_1 = first(paxs)
    len = div(length(axis_1) * sizeof(S), sizeof(T))
    return tuple(resize_last(axis_1, len), tail(paxs)...)
end

function Base.collect(A::AxisArray{T,N}) where {T,N}
    p = similar(parent(A), size(A))
    copyto!(p, A)
    axs = map(unsafe_reconstruct,  axes(A), axes(p))
    return AxisArray{T,N,typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end

#=
function size(a::ReinterpretArray{T,N,S} where {N}) where {T,S}
    psize = size(a.parent)
    size1 = div(psize[1]*sizeof(S), sizeof(T))
    tuple(size1, tail(psize)...)
end
=#

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

julia> keys.(axes(diag(A)))
(["a", "b", "c"],)

julia> keys.(axes(diag(A, 1; dim=Val(2))))
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

julia> keys.(axes(inv(M)))
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
    :(LinearAlgebra.pinv))
    @eval begin
        function $f(A::AxisArray)
            p = $f(parent(A))
            return AxisArray(p, permute_axes(A, p))
        end
    end
end

#=

axs = Base.Iterators.ProductIterator{Tuple{Base.OneTo{Int64},Tuple{Colon}}}((Base.OneTo(4), (Colon(),)))

axs = Base.Iterators.ProductIterator{Tuple{Base.OneTo{Int64},Tuple{Colon}}}((Base.OneTo(4), (Colon(),)))
collect(Base.Iterators.ProductIterator(axes(A)))

function Base.sortslices(A::AxisArray; dims, kwargs...)
    itspace = Base.compute_itspace(parent(A), ifelse(dims isa Val, dims, Val(dims)))
    vecs = map(its->view(parent(A), its...), itspace)
    p = sortperm(vecs; kwargs...)
    B = similar(A)
    for (x, its) in zip(p, itspace)
        B[its...] = vecs[x]
    end
    return B
end

function compute_itspace(A, ::Val{dims}) where {dims}
    N = ndims(A)
    negdims = filter(i-> !(i in dims), 1:N)
    axs = Iterators.product(ntuple(DimSelector{dims}(A), N)...)
    vec(permutedims(collect(axs), (dims..., negdims...)))
end
=#


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
    return AxisArray(mappedarray(f, parent(data)), axes(data))
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

for f in (:zero, :one)
    @eval begin
        function Base.$f(a::AxisArray)
            p = Base.$f(parent(a))
            return AxisArray(p, map(assign_indices, axes(a), axes(p)))
        end
    end
end

drop_axes(x::AbstractArray, d::Int) = drop_axes(x, (d,))
drop_axes(x::AbstractArray, d::Tuple) = drop_axes(x, dim(dimnames(x), d))
drop_axes(x::AbstractArray, d::Tuple{Vararg{Int}}) = drop_axes(axes(x), d)
drop_axes(x::Tuple{Vararg{<:Any}}, d::Int) = drop_axes(x, (d,))
drop_axes(x::Tuple{Vararg{<:Any}}, d::Tuple) = _drop_axes(x, d)
_drop_axes(x, y) = select_axes(x, dropinds(x, y))

select_axes(x::AbstractArray, d::Tuple) = select_axes(x, dims(dimnames(x), d))
select_axes(x::AbstractArray, d::Tuple{Vararg{Int}}) = map(i -> axes(x, i), d)
select_axes(x::Tuple, d::Tuple) = map(i -> getfield(x, i), d)

dropinds(x, y) = _dropinds(x, y)
Base.@pure @inline function _dropinds(x::Tuple{Vararg{Any,N}}, dims::NTuple{M,Int}) where {N,M}
    out = ()
    for i in 1:N
        cnd = true
        for j in dims
            if i === j
                cnd = false
                break
            end
        end
        if cnd
            out = (out..., i)
        end
    end
    return out::NTuple{N - M, Int}
end

function Base.dropdims(a::AxisArray; dims)
    return AxisArray(dropdims(parent(a); dims=dims), drop_axes(a, dims))
end

for (X,Y) in (
    (:(Base.Indices),:(Tuple{Vararg{<:AbstractAxis}})),
    (:(Tuple{Vararg{<:AbstractAxis}}),:(Base.Indices)),
    (:(Tuple{Vararg{<:AbstractAxis}}),:(Tuple{Vararg{<:AbstractAxis}})))
    @eval begin
        function Base.promote_shape(a::$X, b::$Y)
            if length(a) < length(b)
                return Base.promote_shape(b, a)
            end
            for i=1:length(b)
                if length(a[i]) != length(b[i])
                    throw(DimensionMismatch("dimensions must match: a has dims $a, b has dims $b, mismatch at $i"))
                end
            end
            for i=length(b)+1:length(a)
                if length(a[i]) != 1
                    throw(DimensionMismatch("dimensions must match: a has dims $a, must have singleton at dim $i"))
                end
            end
            return a
        end
    end
end

