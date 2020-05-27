
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

Base.haskey(a::AbstractAxis{K}, key::K) where {K} = key in keys(a)

Interface.keys_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Ks

Interface.indices_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Vs

Base.valtype(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = V

Interface.is_indices_axis(::Type{<:AbstractAxis}) = false

###
### first
###
Base.first(a::AbstractAxis) = first(values(a))
function StaticRanges.can_set_first(::Type{T}) where {T<:AbstractAxis}
    return StaticRanges.can_set_first(keys_type(T))
end
function StaticRanges.set_first!(x::AbstractAxis{K,V}, val::V) where {K,V}
    StaticRanges.can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    StaticRanges.resize_first!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_first(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_first(values(x), val)
    return unsafe_reconstruct(x, StaticRanges.resize_first(keys(x), length(vs)), vs)
end

function StaticRanges.set_first(x::AbstractSimpleAxis{V}, val::V) where {V}
    return unsafe_reconstruct(x, set_first(values(x), val))
end
function StaticRanges.set_first!(x::AbstractSimpleAxis{V}, val::V) where {V}
    StaticRanges.can_set_first(x) || throw(MethodError(set_first!, (x, val)))
    set_first!(values(x), val)
    return x
end

Base.firstindex(a::AbstractAxis) = first(values(a))

###
### last
###
Base.last(a::AbstractAxis) = last(values(a))
function StaticRanges.can_set_last(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs}
    return StaticRanges.can_set_last(Ks) & StaticRanges.can_set_last(Vs)
end
function StaticRanges.set_last!(x::AbstractAxis{K,V}, val::V) where {K,V}
    StaticRanges.can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    StaticRanges.resize_last!(keys(x), length(values(x)))
    return x
end
function StaticRanges.set_last(x::AbstractAxis{K,V}, val::V) where {K,V}
    vs = set_last(values(x), val)
    return unsafe_reconstruct(x, StaticRanges.resize_last(keys(x), length(vs)), vs)
end

function StaticRanges.set_last!(x::AbstractSimpleAxis{V}, val::V) where {V}
    StaticRanges.can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    set_last!(values(x), val)
    return x
end

function StaticRanges.set_last(x::AbstractSimpleAxis{K}, val::K) where {K}
    return unsafe_reconstruct(x, set_last(values(x), val))
end

Base.lastindex(a::AbstractAxis) = last(values(a))

###
### length
###
Base.length(a::AbstractAxis) = length(values(a))

function StaticRanges.can_set_length(::Type{T}) where {T<:AbstractAxis}
    return StaticRanges.can_set_length(keys_type(T)) & StaticRanges.can_set_length(indices_type(T))
end

function StaticRanges.set_length!(a::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    StaticRanges.can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    set_length!(keys(a), len)
    set_length!(values(a), len)
    return a
end
#function StaticRanges.can_set_length(::Type{<:AbstractSimpleAxis{V,Vs}}) where {V,Vs}
#    return can_set_length(Vs)
#end
function StaticRanges.set_length!(a::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    StaticRanges.can_set_length(a) || error("Cannot use set_length! for instances of typeof $(typeof(a)).")
    StaticRanges.set_length!(values(a), len)
    return a
end

function StaticRanges.set_length(a::AbstractAxis{K,V,Ks,Vs}, len) where {K,V,Ks,Vs}
    return unsafe_reconstruct(a, set_length(keys(a), len), set_length(values(a), len))
end

function StaticRanges.set_length(x::AbstractSimpleAxis{V,Vs}, len) where {V,Vs}
    return unsafe_reconstruct(x, StaticRanges.set_length(values(x), len))
end

StaticRanges.Length(::Type{<:AbstractAxis{K,Ks,V,Vs}}) where {K,Ks,V,Vs} = Length(Vs)

###
### step
###
Base.step(a::AbstractAxis) = step(values(a))

Base.step_hp(a::AbstractAxis) = Base.step_hp(values(a))


StaticRanges.Size(::Type{T}) where {T<:AbstractAxis} = StaticRanges.Size(indices_type(T))

Base.size(a::AbstractAxis) = (length(a),)

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
function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T}
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

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
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
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractVector{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    check_length && check_axis_length(new_keys, new_indices)
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys), as_static(new_indices))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys), as_fixed(new_indices))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys), as_dynamic(new_indices))
    end
end

function Base.similar(
    axis::AbstractAxis{K,V,Ks,Vs},
    new_keys::AbstractUnitRange{T},
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

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
    similar(axis::AbstractSimpleAxis, new_indices::AbstractUnitRange{Integer}) -> AbstractSimpleAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(SimpleAxis(1:10), 1:3)
SimpleAxis(1:3)
```
"""
function Base.similar(
    axis::AbstractSimpleAxis{V,Vs},
    new_keys::AbstractUnitRange{T}
) where {V<:Integer,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys))
    end
end

const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}

# Vectors should have a mutable axis
true_axes(x::Vector) = (OneToMRange(length(x)),)
true_axes(x) = axes(x)
true_axes(x::Vector, i) = (OneToMRange(length(x)),)
true_axes(x, i) = axes(x, i)

# :resize_first!, :resize_last! don't need to define these ones b/c non mutating ones are only
# defined to avoid ambiguities with methods that pass AbstractUnitRange{<:Integer} instead of Integer
for f in (:grow_last!, :grow_first!, :shrink_last!, :shrink_first!)
    @eval begin
        function StaticRanges.$f(axis::AbstractSimpleAxis, n::Integer)
            StaticRanges.$f(values(axis), n)
            return axis
        end

        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            StaticRanges.$f(keys(axis), n)
            StaticRanges.$f(values(axis), n)
            return axis
        end
    end
end

for f in (:grow_last, :grow_first, :shrink_last, :shrink_first, :resize_first, :resize_last)
    @eval begin
        function StaticRanges.$f(axis::AbstractSimpleAxis, n::Integer)
            return unsafe_reconstruct(axis, StaticRanges.$f(values(axis), n))
        end

        function StaticRanges.$f(axis::AbstractAxis, n::Integer)
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(keys(axis), n),
                StaticRanges.$f(values(axis), n)
            )
        end

        function StaticRanges.$f(axis::AbstractSimpleAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, n)
        end

        function StaticRanges.$f(axis::AbstractAxis, n::AbstractUnitRange{<:Integer})
            return unsafe_reconstruct(axis, StaticRanges.$f(keys(axis), length(n)), n)
        end
    end
end

#= assign_indices(axis, indices)

Reconstructs `axis` but with `indices` replacing the indices/values.
There shouldn't be any change in size of the indices.
=#
assign_indices(axs::AbstractSimpleAxis, inds) = similar(axs, inds)
assign_indices(axis::AbstractAxis, inds) = unsafe_reconstruct(axis, keys(axis), inds)

Base.allunique(a::AbstractAxis) = true

Base.in(x::Integer, a::AbstractAxis) = in(x, values(a))

Base.collect(a::AbstractAxis) = collect(values(a))

Base.eachindex(a::AbstractAxis) = values(a)

function reverse_keys(old_axis::AbstractAxis, new_index::AbstractUnitRange)
    return similar(old_axis, reverse(keys(old_axis)), new_index, false)
end

function reverse_keys(old_axis::AbstractSimpleAxis, new_index::AbstractUnitRange)
    return Axis(reverse(keys(old_axis)), new_index, false)
end

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

Base.show(io::IO, ::MIME"text/plain", axis::AbstractAxis) = Interface.print_axis(io, axis)
Base.show(io::IO, axis::AbstractAxis) = Interface.print_axis(io, axis)

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

#=
We need to assign new indices to axes of `A` but `reshape` may have changed the
size of any axis
=#
@inline function reshape_axis(axis::A, inds) where {A}
    if is_indices_axis(A)
        return unsafe_reconstruct(axis, inds)
    else
        return unsafe_reconstruct(axis, resize_last(keys(axis), length(inds)), inds)
    end
end

@inline function reshape_axes(axs::Tuple, inds::Tuple{Vararg{Any,N}}) where {N}
    return map(reshape_axis, axs, inds)
end

Base.isempty(a::AbstractAxis) = isempty(values(a))

Base.sum(x::AbstractAxis) = sum(values(x))

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

