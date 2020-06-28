# FIXME to_index(::OffsetAxis, :) returns the indices instead of a Slice
# FIXME to_index(::IndicesCollection, axis, ::AbstractAxis) causes problems (i.e., axis[axis] -> errors)

"""
    to_index(axis, arg) -> to_index(AxisIndicesStyle(axis, arg), axis, arg)

Unique implementation of `to_index` for the `AxisIndices` package that specializes
based on each axis and indexing argument (as opposed to the array and indexing argument).
"""
@propagate_inbounds function to_index(axis)
    @boundscheck if length(axis) != 1
        throw(BoundsError(axis, ()))
    end
    return first(axis)
end

@propagate_inbounds function to_index(axis, arg)
    return to_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function to_index(axis, arg::Indices)
    return to_index(Styles.force_indices(AxisIndicesStyle(axis, arg)), axis, arg.x)
end

@propagate_inbounds function to_index(axis, arg::Keys)
    return to_index(Styles.force_keys(AxisIndicesStyle(axis, arg)), axis, arg.x)
end

@propagate_inbounds function to_index(::KeyElement, axis, arg)
    mapping = find_firsteq(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

@propagate_inbounds function to_index(::IndexElement, axis, arg)
    @boundscheck if !in(arg, indices(axis))
        throw(BoundsError(axis, arg))
    end
    return arg
end

@propagate_inbounds to_index(::BoolElement, axis, arg) = getindex(values(axis), arg)

@propagate_inbounds function to_index(::CartesianElement, axis, arg)
    index = first(arg.I)
    @boundscheck if !checkindex(Bool, indices(axis), index)
        throw(BoundsError(axis, arg.I...))
    end
    return index
end

@propagate_inbounds function to_index(::KeysCollection, axis, arg)
    mapping = findin(arg, keys(axis))
    @boundscheck if length(arg) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

# TODO boundschecking should be replace by the yet undeveloped `allin` method in StaticRanges
# if we're referring to an element than we just need to know if it's inbounds
@propagate_inbounds function to_index(::IndicesCollection, axis, arg)
    @boundscheck if length(findin(arg, indices(axis))) != length(arg)
        throw(BoundsError(axis, arg))
    end
    return arg
end

@propagate_inbounds function to_index(::BoolsCollection, axis, arg)
    return getindex(indices(axis), arg)
end

function to_index(::IntervalCollection, axis, arg)
    return k2v(keys(axis), indices(axis), findin(arg, keys(axis)))
end

@propagate_inbounds function to_index(::KeysIn, axis, arg)
    mapping = findin(arg.x, keys(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

@propagate_inbounds function to_index(::IndicesIn, axis, arg)
    mapping = findin(arg.x, indices(axis))
    @boundscheck if length(arg.x) != length(mapping)
        throw(BoundsError(axis, arg))
    end
    return mapping
end

@propagate_inbounds function to_index(::KeyEquals, axis, arg)
    mapping = find_first(arg, keys(axis))
    @boundscheck if mapping isa Nothing
        throw(BoundsError(axis, arg))
    end
    return k2v(keys(axis), indices(axis), mapping)
end

@propagate_inbounds function to_index(::IndexEquals, axis, arg)
    @boundscheck if !checkbounds(Bool, indices(axis), arg.x)
        throw(BoundsError(axis, arg.x))
    end
    return arg.x
end

@inline to_index(::KeysFix2, axis, arg) = k2v(keys(axis), indices(axis), find_all(arg, keys(axis)))

@inline to_index(::IndicesFix2, axis, arg) = find_all(arg, indices(axis))

to_index(::SliceCollection, axis, arg) = Base.Slice(indices(axis))

to_index(::KeyedStyle{S}, axis, arg) where {S} = to_index(S, axis, arg)

# TODO benchmark times on this one
@boundscheck function to_index(::CartesianIndexCollection, axis, arg)
    if arg isa CartesianIndices
        return _cartesian_indices_to_index(axis, arg.indices)
    else
        @boundscheck checkbounds(axis, arg)
        return @inbounds(indices(axis)[arg])
    end
end

_cartesian_indices_to_index(axis, arg::Tuple{}) = empty(indices(axis))
@propagate_inbounds function _cartesian_indices_to_index(axis, arg::NTuple{1,Any})
    return to_index(axis, first(arg))
end
@propagate_inbounds function _cartesian_indices_to_index(axis, arg::NTuple{N,Any}) where {N}
    @boundscheck if !all(arg_i -> length(arg_i) == 1, tail(arg))
        throw(BoundsError(axis, arg))
    end
    return to_index(axis, first(arg))
end

#=

@inline function checkbounds_indices(::Type{Bool}, ::Tuple{}, I::Tuple{CartesianIndex,Vararg{Any}})
    checkbounds_indices(Bool, (), (I[1].I..., tail(I)...))
end

@inline function checkbounds_indices(::Type{Bool}, IA::Tuple{Any}, I::Tuple{CartesianIndex,Vararg{Any}})
    checkbounds_indices(Bool, IA, (I[1].I..., tail(I)...))
end

@inline function checkbounds_indices(::Type{Bool}, IA::Tuple, I::Tuple{CartesianIndex,Vararg{Any}})
    checkbounds_indices(Bool, IA, (I[1].I..., tail(I)...))
end

function checkbounds_indices(::Type{Bool}, IA::Tuple, I::Tuple)
    @_inline_meta
    checkindex(Bool, IA[1], I[1]) & checkbounds_indices(Bool, tail(IA), tail(I))
end
function checkbounds_indices(::Type{Bool}, ::Tuple{}, I::Tuple)
    @_inline_meta
    checkindex(Bool, OneTo(1), I[1]) & checkbounds_indices(Bool, (), tail(I))
end
checkbounds_indices(::Type{Bool}, IA::Tuple, ::Tuple{}) = (@_inline_meta; all(x->unsafe_length(x)==1, IA))
checkbounds_indices(::Type{Bool}, ::Tuple{}, ::Tuple{}) = true

#
@inline function checkbounds_indices(::Type{Bool}, ::Tuple{}, I::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    return checkindex(Bool, (), I[1]) & checkbounds_indices(Bool, (), tail(I))
end
@inline function checkbounds_indices(::Type{Bool}, IA::Tuple{Any}, I::Tuple{AbstractArray{CartesianIndex{0}},Vararg{Any}})
    return checkbounds_indices(Bool, IA, tail(I))
end
@inline function checkbounds_indices(::Type{Bool}, IA::Tuple{Any}, I::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    return checkindex(Bool, IA, I[1]) & checkbounds_indices(Bool, (), tail(I))
end
@inline function checkbounds_indices(::Type{Bool}, IA::Tuple, I::Tuple{AbstractArray{CartesianIndex{N}},Vararg{Any}}) where N
    IA1, IArest = IteratorsMD.split(IA, Val(N))
    checkindex(Bool, IA1, I[1]) & checkbounds_indices(Bool, IArest, tail(I))
end

function checkindex(::Type{Bool}, inds::Tuple, I::AbstractArray{<:CartesianIndex})
    b = true
    for i in I
        b &= checkbounds_indices(Bool, inds, (i,))
    end
    b
end

A = ones(3,3,3);
getindex(A, [CartesianIndex(1, 1),CartesianIndex(2, 1)], 1:2)

=#

