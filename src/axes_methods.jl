
# TODO document
reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims::Colon) where {N} = ()
function reduce_axes(old_axes::Tuple{Vararg{Any,N}}, new_axes::Tuple, dims) where {N}
    ntuple(Val(N)) do i
        if i in dims
            StaticRanges.shrink_last(getfield(old_axes, i), getfield(new_axes, i))
        else
            unsafe_reconstruct(getfield(old_axes, i), getfield(new_axes, i))
        end
    end
end

#=
We need to assign new indices to axes of `A` but `reshape` may have changed the
size of any axis
=#
@inline function reshape_axes(axs::Tuple, inds::Tuple{Vararg{Any,N}}) where {N}
    return map((a, i) -> resize_last(a, i), axs, inds)
end
