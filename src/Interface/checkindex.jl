# check_index - basically checkindex but passes a style trait argument
@propagate_inbounds function check_index(axis, arg)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function check_index(axis, arg::Indices)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

@propagate_inbounds function check_index(axis, arg::Keys)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

check_index(::KeyElement, axis, arg) = arg in keys(axis)

check_index(::IndexElement, axis, arg) = arg in indices(axis)

check_index(::BoolElement, axis, arg) = checkindex(Bool, indices(axis), arg)

check_index(::CartesianElement, axis, arg) = checkindex(Bool, indices(axis), first(arg.I))

check_index(::KeysCollection, axis, arg) = length(findin(arg, keys(axis))) == length(arg)

check_index(::IndicesCollection, axis, arg) = length(findin(arg, indices(axis))) == length(arg)

check_index(::BoolsCollection, axis, arg) = checkindex(Bool, indices(axis), arg)

check_index(::IntervalCollection, axis, arg) = true

check_index(::KeysIn, axis, arg) = length(findin(arg.x, keys(axis))) == length(arg.x)

check_index(::IndicesIn, axis, arg) = length(findin(arg.x, indices(axis))) == length(arg.x)

check_index(::KeyEquals, axis, arg) = !isa(find_first(arg, keys(axis)), Nothing)

check_index(::IndexEquals, axis, arg) = checkbounds(Bool, indices(axis), arg.x)

check_index(::KeysFix2, axis, arg) = true

check_index(::IndicesFix2, axis, arg) = true

check_index(::SliceCollection, axis, arg) = true

check_index(::KeyedStyle{S}, axis, arg) where {S} = check_index(S, axis, arg)

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
