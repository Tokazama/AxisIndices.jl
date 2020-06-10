
# We can't specify Vs<:AbstractUnitRange b/c it does some really bizarre things
# to internal inferrence code on some versions of Julia. It ends up spitting out
# a bunch of references to "intersect"/"intersect_all"/"intersect_asied"/etc in "subtype.c"
"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{K,V<:Integer,Ks,Vs} <: AbstractUnitRange{V} end

"""
    AbstractSimpleAxis{V,Vs}

A subtype of `AbstractAxis` where the keys and values are represented by a single collection.
"""
abstract type AbstractSimpleAxis{V,Vs} <: AbstractAxis{V,V,Vs,Vs} end

Base.keytype(::Type{<:AbstractAxis{K}}) where {K} = K

Base.haskey(axis::AbstractAxis{K}, key::K) where {K} = key in keys(axis)

Interface.keys_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Ks

Interface.indices_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Vs

Base.valtype(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = V

Interface.is_indices_axis(::Type{<:AbstractAxis}) = false

###
### first
###
Base.first(axis::AbstractAxis) = first(values(axis))

StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis} = can_set_first(keys_type(T))

function StaticRanges.set_first(axis::AbstractAxis{K,V}, val::V) where {K,V}
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, set_first(indices(axis), val))
    else
        vs = set_first(values(axis), val)
        return unsafe_reconstruct(axis, resize_first(keys(axis), length(vs)), vs)
    end
end

function StaticRanges.set_first!(axis::AbstractAxis{K,V}, val::V) where {K,V}
    can_set_first(axis) || throw(MethodError(set_first!, (axis, val)))
    set_first!(indices(axis), val)
    if !is_indices_axis(axis)
        resize_first!(keys(axis), length(indices(axis)))
    end
    return axis
end

Base.firstindex(axis::AbstractAxis) = first(indices(axis))

###
### last
###
Base.last(axis::AbstractAxis) = last(indices(axis))

function StaticRanges.can_set_last(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs}
    return can_set_last(Ks) & can_set_last(Vs)
end

function StaticRanges.set_last!(axis::AbstractAxis{K,V}, val::V) where {K,V}
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(indices(axis), val)
    if is_indices_axis(axis)
        resize_last!(keys(axis), length(indices(axis)))
    end
    return axis
end

function StaticRanges.set_last(axis::AbstractAxis{K,V}, val::V) where {K,V}
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, set_last(indices(axis), val))
    else
        vs = set_last(indices(axis), val)
        return unsafe_reconstruct(axis, resize_last(keys(axis), length(vs)), vs)
    end
end

Base.lastindex(a::AbstractAxis) = last(indices(a))

###
### length
###
Base.length(axis::AbstractAxis) = length(indices(axis))

function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return can_set_length(keys_type(T)) & can_set_length(indices_type(T))
end

function StaticRanges.set_length!(axis::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(indices(axis), len)
    if !is_indices_axis(axis)
        set_length!(keys(axis), len)
    end
    return axis
end

function StaticRanges.set_length(axis::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    if is_indices_axis(axis)
        return unsafe_reconstruct(axis, set_length(indices(axis), len))
    else
        return unsafe_reconstruct(axis, set_length(keys(axis), len), set_length(indices(axis), len))
    end
end

StaticRanges.Length(::Type{<:AbstractAxis{K,Ks,V,Vs}}) where {K,Ks,V,Vs} = Length(Vs)

###
### step
###
Base.step(axis::AbstractAxis) = step(indices(axis))

Base.step_hp(axis::AbstractAxis) = Base.step_hp(indices(axis))


StaticRanges.Size(::Type{T}) where {T<:AbstractAxis} = StaticRanges.Size(indices_type(T))

Base.size(axis::AbstractAxis) = (length(axis),)

###
### similar
###
function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=indices_type(A)
) where {A<:AbstractAxis}

    return similar_type(A, ks_type, vs_type)
end

function StaticRanges.similar_type(
    ::A,
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
) where {A<:AbstractSimpleAxis}

    return similar_type(A, vs_type)
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two])
Axis([:one, :two] => 1:2)
```
"""
function Base.similar(axis::AbstractAxis, new_keys::AbstractVector)
    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end

#=
function Base.similar(
    axis::AbstractAxis,
    new_keys::AbstractUnitRange{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end
=#

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector, new_indices::AbstractUnitRange{Integer} [, check_length::Bool=true] ) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`
and indices `new_indices`. If `check_length` is `true` then the lengths of `new_keys`
and `new_indices` are checked to ensure they have the same length before construction.

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(2))
Axis([:one, :two] => 0x0000000000000001:0x0000000000000002)

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(3))
ERROR: DimensionMismatch("keys and indices must have same length, got length(keys) = 2 and length(indices) = 3.")
[...]
```
"""
function Base.similar(
    axis::AbstractAxis,
    new_keys::AbstractVector,
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
)

    check_length && check_axis_length(new_keys, new_indices)
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys), as_static(new_indices))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys), as_fixed(new_indices))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys), as_dynamic(new_indices))
    end
end

"""
    similar(axis::AbstractAxis, new_indices::AbstractUnitRange)

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(SimpleAxis(1:10), 1:3)
SimpleAxis(1:3)
```
"""
function Base.similar(axis::AbstractAxis, new_keys::AbstractUnitRange{<:Integer})
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys))
    end
end

const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}

# :resize_first!, :resize_last! don't need to define these ones b/c non mutating ones are only
# defined to avoid ambiguities with methods that pass AbstractUnitRange{<:Integer} instead of Integer
for f in (:grow_last!, :grow_first!, :shrink_last!, :shrink_first!)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            can_set_length(axis) ||  throw(MethodError($f, (axis, n)))
            if !is_indices_axis(axis)
                StaticRanges.$f(keys(axis), n)
            end
            StaticRanges.$f(indices(axis), n)
            return axis
        end
    end
end

for f in (:grow_last, :grow_first, :shrink_last, :shrink_first, :resize_first, :resize_last)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            if is_indices_axis(axis)
                return unsafe_reconstruct(axis, StaticRanges.$f(indices(axis), n))
            else
                return unsafe_reconstruct(
                    axis,
                    StaticRanges.$f(keys(axis), n),
                    StaticRanges.$f(indices(axis), n)
                )
            end
        end

    end
end

for f in (:shrink_last, :shrink_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            if is_indices_axis(axis)
                return unsafe_reconstruct(axis, n)
            else
                return unsafe_reconstruct(axis, StaticRanges.$f(keys(axis), length(axis) - length(n)), n)
            end
        end
    end
end

for f in (:grow_last, :grow_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            if is_indices_axis(axis)
                return unsafe_reconstruct(axis, n)
            else
                return unsafe_reconstruct(axis, StaticRanges.$f(keys(axis), length(n) - length(axis)), n)
            end
        end
    end
end

for f in (:resize_last, :resize_first)
    @eval begin
        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            if is_indices_axis(axis)
                return unsafe_reconstruct(axis, n)
            else
                return unsafe_reconstruct(axis, StaticRanges.$f(keys(axis), length(n)), n)
            end
        end
    end
end

Base.allunique(a::AbstractAxis) = true

Base.in(x::Integer, a::AbstractAxis) = in(x, values(a))

Base.collect(a::AbstractAxis) = collect(values(a))

Base.eachindex(a::AbstractAxis) = values(a)

#Base.axes(a::AbstractAxis) = values(a)

# This is required for performing `similar` on arrays
Base.to_shape(r::AbstractAxis) = length(r)

# for when we want the same underlying memory layout but reversed keys
# TODO should this be a formal abstract type?
const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}


# TODO this should all be derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

function Interface.print_axis_compactly(io, axis::AbstractAxis)
    return Interface.print_axis_compactly(io, keys(axis))
end

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

#=
We need to assign new indices to axes of `A` but `reshape` may have changed the
size of any axis
=#
@inline function reshape_axes(axs::Tuple, inds::Tuple{Vararg{Any,N}}) where {N}
    return map((a, i) -> resize_last(a, i), axs, inds)
end

Base.isempty(a::AbstractAxis) = isempty(values(a))

Base.sum(x::AbstractAxis) = sum(values(x))

for f in (:(==), :isequal)
    @eval begin
        Base.$(f)(x::AbstractAxis, y::AbstractAxis) = $f(eachindex(x), eachindex(y))
        Base.$(f)(x::AbstractArray, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::AbstractArray) = $f(eachindex(x), y)

        Base.$(f)(x::OrdinalRange, y::AbstractAxis) = $f(x, eachindex(y))
        Base.$(f)(x::AbstractAxis, y::OrdinalRange) = $f(eachindex(x), y)
    end
end

# TODO document
reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims::Colon) where {N} = ()
function reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims) where {N}
    ntuple(Val(N)) do i
        if i in dims
            axis = getfield(old_axes, i)
            if is_indices_axis(axis)
                unsafe_reconstruct(axis, getfield(new_axes, i))
            else
                unsafe_reconstruct(axis, set_length(keys(axis), 1), getfield(new_axes, i))
            end
        else
            assign_indices(getfield(old_axes, i), getfield(new_axes, i))
        end
    end
end

###
### offset axes
###
function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:AbstractUnitRange}
    return true
end

function StaticRanges.has_offset_axes(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs<:OneToUnion}
    return false
end

# StaticRanges.has_offset_axes is taken care of by any array type that defines `axes_type`

function StaticRanges.Staticness(::Type{A}) where {A<:AbstractAxis}
    if is_indices_axis(A)
        return StaticRanges.Staticness(indices_type(A))
    else
        return StaticRanges._combine(Tuple{indices_type(A),keys_type(A)})
    end
end

for f in (:as_static, :as_fixed, :as_dynamic)
    @eval begin
        function StaticRanges.$f(x::A) where {A<:AbstractAxis}
            if is_indices_axis(A)
                return unsafe_reconstruct(x, StaticRanges.$f(values(x)))
            else
                return unsafe_reconstruct(x, StaticRanges.$f(keys(x)), StaticRanges.$f(values(x)))
            end
        end
    end
end

# TODO how do I make this generic?
function reverse_keys(old_axis::AbstractAxis, new_index::AbstractUnitRange)
    return similar(old_axis, reverse(keys(old_axis)), new_index, false)
end

function reverse_keys(old_axis::AbstractSimpleAxis, new_index::AbstractUnitRange)
    return Axis(reverse(keys(old_axis)), new_index, false)
end

@inline function Base.compute_offset1(parent, stride1::Integer, dims::Tuple{Int}, inds::Tuple{<:AbstractAxis}, I::Tuple)
    return Base.compute_linindex(parent, I) - stride1 * first(axes(parent, first(dims)))
end

@inline Base.axes(axis::AbstractAxis) = (Base.axes1(axis),)

@inline Base.axes1(axis::AbstractAxis) = copy(axis)

@inline Base.unsafe_indices(axis::AbstractAxis) = (axis,)

###
### General constructors
###
#=

(A::Type{<:AbstractAxis})(kv::Pair) = A(first(kv), last(kv))

@inline function (A::Type{<:AbstractAxis{K}})(ks::AbstractIndices, inds::AbstractIndices, args...; kwargs...) where {K}
    if eltype(ks) <: K
        A
    else
        return A(AbstractIndices{K}(ks)
    end
end


=#

Base.show(io::IO, ::MIME"text/plain", axis::AbstractAxis) = Interface.print_axis(io, axis)
Base.show(io::IO, axis::AbstractAxis) = Interface.print_axis(io, axis)

