
module AxisCore

using ChainedFixes
using IntervalSets
using LinearAlgebra

using LazyArrays
using LazyArrays: Vcat

using StaticRanges
using StaticRanges: can_set_first, can_set_last, can_set_length, same_type,
    checkindexlo, checkindexhi, OneToUnion, grow_first!, grow_last!, resize_last,
    resize_last!, shrink_last!

using StaticRanges: Static, Fixed, Dynamic, Staticness
using StaticArrays
using AxisIndices.PrettyArrays

using Base: @propagate_inbounds, OneTo, Fix2, tail, front, Fix2
using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

export
    AbstractAxisIndices,
    AbstractAxisIndicesMatrix,
    AbstractAxisIndicesVector,
    AbstractAxisIndicesVecOrMat,
    AxisIndicesArray,
    AbstractAxis,
    AbstractSimpleAxis,
    Axis,
    SimpleAxis,
    Indices,
    Keys,
    # methods
    axes_keys,
    first_key,
    step_key,
    last_key,
    similar_axes,
    keys_type,
    indices,
    values_type,
    unsafe_reconstruct,
    maybetail,
    to_axis,
    true_axes,
    assign_indices,
    v2k,
    k2v,
    broadcast_axis,
    cat_axis,
    cat_axes,
    hcat_axes,
    vcat_axes,
    append_axis!,
    permute_axes,
    reduce_axes,
    reduce_axis,
    reconstruct_reduction,
    drop_axes,
    promote_axis_collections,
    unwrap_broadcasted,
    CartesianAxes,
    LinearAxes,
    to_axes,
    # Traits
    AxisIndicesStyle,
    KeyElement,
    IndexElement,
    BoolElement,
    CartesianElement,
    KeysCollection,
    IndicesCollection,
    IntervalCollection,
    BoolsCollection,
    KeysIn,
    IndicesIn,
    KeyEquals,
    IndexEquals,
    KeysFix2,
    IndicesFix2,
    SliceCollection,
    CombineStyle,
    CombineAxis,
    CombineSimpleAxis,
    CombineResize,
    CombineStack,
    CoVector,
    # methods
    is_simple_axis,
    is_element,
    is_index,
    is_collection,
    is_key,
    to_index,
    to_keys


include("abstractaxis.jl")
include("utils.jl")
include("axis.jl")
include("simpleaxis.jl")
include("abstractaxisindices.jl")
include("axisindicesarray.jl")
include("promotion.jl")
include("show.jl")
include("traits.jl")

include("to_axis.jl")

include("promote_axis_collections.jl")
include("append.jl")
include("pop.jl")
include("popfirst.jl")
include("broadcast_axis.jl")
include("broadcast.jl")
include("dropdims.jl")
include("map.jl")
include("rotations.jl")
include("reduce.jl")
include("permutedims.jl")
include("arraymath.jl")
include("cat.jl")
include("io.jl")
include("resize.jl")

include("linearaxes.jl")
include("cartesianaxes.jl")
include("to_axes.jl")
include("to_indices.jl")
include("checkbounds.jl")
include("getindex.jl")
include("reshape.jl")

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

###
### static traits
###
# for when we want the same underlying memory layout but reversed keys

# TODO should this be a formal abstract type?
const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}


# TODO this should all be derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

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

Base.pairs(a::AbstractAxis) = Base.Iterators.Pairs(a, keys(a))

end

