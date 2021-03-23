
if VERSION > v"1.2"
    function Base.has_fast_linear_indexing(x::AxisArray)
        return Base.has_fast_linear_indexing(parent(x))
    end
end

"""
    AxisVector

A vector whose indices have keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisVector([1, 2], [:a, :b])
2-element AxisArray(::Vector{Int64}
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

AxisVector{T}() where {T} = _AxisArray(T[], (SimpleAxis(DynamicAxis(0)),))

function Base.reverse(x::AxisVector)
    p = reverse(parent(x))
    return _AxisArray(p, (reverse_keys(axes(x, 1), axes(p, 1)),))
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
    return _AxisArray(p, axs)
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
    return _AxisArray(p, axs)
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
    return _AxisArray(p, axs)
end

###
### VecOrMat
###
const AxisVecOrMat{T} = Union{<:AxisMatrix{T},<:AxisVector{T}}

function Base.sort(A::AxisArray; dims, kwargs...)
    p = sort(parent(A); dims=dims, kwargs...)
    return AxisArray(p, map(assign_indices, axes(A), axes(p)))
end
function Base.sort(A::AxisArray{T,1}; kwargs...) where {T}
    p = sort(parent(A); kwargs...)
    return AxisArray(p, map(assign_indices, axes(A), axes(p)))
end
function Base.sort!(A::AxisArray; dims, kwargs...)
    p = sort!(parent(A); dims=dims, kwargs...)
    return AxisArray(p, map(assign_indices, axes(A), axes(p)))
end
function Base.sort!(A::AxisArray{T,1}; kwargs...) where {T}
    p = sort!(parent(A); kwargs...)
    return AxisArray(p, map(assign_indices, axes(A), axes(p)))
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
    return initialize_axis_array(zeros(T, map(length, axs)), axs)
end

function Base.falses(axs::Tuple{Vararg{<:AbstractAxis}})
    return initialize_axis_array(falses(map(length, axs)), axs)
end

function Base.fill(x, axs::Tuple{Vararg{<:AbstractAxis}})
    return initialize_axis_array(fill(x, map(length, axs)), axs)
end

function Base.reshape(A::AbstractArray, shp::Tuple{<:AbstractAxis,Vararg{<:AbstractAxis}})
    p = reshape(parent(A), map(length, shp))
    axs = reshape_axes(naxes(shp, Val(length(shp))), axes(p))
    return _AxisArray(p, axs)
end

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
unsafe_view(A, inds::Tuple{Vararg{<:Integer}}) = @inbounds(Base.view(parent(A), inds...))

function unsafe_view(A, inds::Tuple)
    p = @inbounds(Base.view(parent(A), inds...))
    return unsafe_reconstruct(A, p; axes=to_axes(A, inds))
end

function unsafe_dotview(A, inds::Tuple{Vararg{<:Integer}})
    return @inbounds(Base.dotview(parent(A), inds...))
end

function unsafe_dotview(A, inds::Tuple)
    p = @inbounds(Base.dotview(parent(A), inds...))
    return AxisArray(p, to_axes(A, axes(p)))
end

@propagate_inbounds function Base.getindex(A::AxisArray, args...)
    return ArrayInterface.getindex(A, args...)
end

Base.getindex(A::AxisArray, ::Ellipsis) = A

@propagate_inbounds function Base.setindex!(A::AxisArray, val, args...)
    return ArrayInterface.setindex!(A, val, args...)
end

for (unsafe_f, f) in (
    (:unsafe_view, :view),
    (:unsafe_dotview, :dotview))
    @eval begin
        @propagate_inbounds function Base.$f(A::AxisArray, args...)
            return unsafe_view(A, ArrayInterface.to_indices(A, args))
        end
    end
end

###
### Math
###
for f in (:sum!, :prod!, :maximum!, :minimum!)
    for (A,B) in (
        (AxisArray, AbstractArray),
        (AbstractArray, AxisArray),
        (AxisArray, AxisArray))
        @eval begin
            function Base.$f(a::$A, b::$B)
                Base.$f(parent(a), parent(b))
                return a
            end
        end
    end
end

Base.accumulate(op, A::AxisArray; dims=nothing, init=nothing) = _accumulate(op, A, dims, init)
_accumulate_similar(op, A, ::Nothing) = similar(A, Base.promote_op(op, eltype(A), eltype(A)))
_accumulate_similar(op, A, init) = Base.promote_op(op, typeof(init), eltype(A))

function _accumulate(op, A, dims, init)
    return _accumulate!(op, _accumulate_similar(op, A, init), A, dims, init)
end
_accumulate(op, A, ::Nothing, init) = _accumulate_dims_nothing(op, A, init)
function _accumulate_dims_nothing(op, A::AbstractVector, init)
    return _accumulate!(op, _accumulate_similar(op, A, init), A, nothing, init)
end
_accumulate_dims_nothing(op, A, init) = collect(Iterators.accumulate(op, A); init=init)
_accumulate_dims_nothing(op, A, ::Nothing) = collect(Iterators.accumulate(op, A))

function Base.accumulate!(op, B, A::AxisArray; dims=nothing, init=nothing)
    return _accumulate!(op, B, A, dims, init)
end
_accumulate!(op, B, A, ::Nothing, ::Nothing) = Base._accumulate!(op, B, A, nothing, nothing)
function _accumulate!(op, B, A, dims, ::Nothing)
    return Base._accumulate!(op, B, A, to_dims(A, dims), nothing)
end
function _accumulate!(op, B, A, ::Nothing, init)
    return Base._accumulate!(op, B, A, nothing, Some(init))
end
function _accumulate!(op, B, A, dims, init)
    return Base._accumulate!(op, B, A, to_dims(A, dims), Some(init))
end

# TODO cumsum/cumprod/cumsum!/cumprod! checks

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
        if !can_change_size(axis)
            error("Cannot perform `empty!` on AxisArray that has an axis with a fixed size.")
        end
    end

    for axis in axes(a)
        empty!(axis)
    end
    empty!(parent(a))
    return a
end

#=
function Base.convert(::Type{T}, A::AbstractArray) where {T<:AxisArray}
    if A isa T
        return A
    else
        return T(A)
    end
end
=#

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
    return _AxisArray(p, axs)
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


# FIXME get rid of Val
"""
    diag(M::AxisMatrix, k::Integer=0; dim::Val=Val(1))

The `k`th diagonal of an `AxisMatrixMatrix`, `M`. The keyword argument
`dim` specifies which dimension's axis to preserve, with the default being
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
    return AxisArray(p, (StaticRanges.shrink_end(axes(M, D), axes(p, 1)),))
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

function Base.transpose(A::AxisArray)
    p = Base.transpose(parent(A))
    return AxisArray(p, permute_axes(A, p))
end
function Base.adjoint(A::AxisArray)
    p = Base.adjoint(parent(A))
    return AxisArray(p, permute_axes(A, p))
end
function LinearAlgebra.pinv(A::AxisArray)
    p = LinearAlgebra.pinv(parent(A))
    return AxisArray(p, permute_axes(A, p))
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
        function Base.$f(f, a::AbstractArray, b::AxisArray, cs::AbstractArray...)
            return AxisArray(
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f, a::AxisArray, b::AxisArray, cs::AbstractArray...)
            return AxisArray(
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f, a::AxisArray, b::AbstractArray, cs::AbstractArray...)
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

# We need to implement copy because if the wrapper array type does not support setindex
# then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{AxisArrayStyle{S}}) where S
    return AxisArray(copy(unwrap_broadcasted(bc)), Broadcast.combine_axes(bc.args...))
end

function Base.one(a::AxisArray)
    p = Base.one(parent(a))
    return AxisArray(p, map(assign_indices, axes(a), axes(p)))
end
function Base.zero(a::AxisArray)
    p = Base.zero(parent(a))
    return AxisArray(p, map(assign_indices, axes(a), axes(p)))
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

