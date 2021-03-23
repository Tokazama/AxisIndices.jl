
ArrayInterface.unsafe_reconstruct(axis::SimpleAxis, x) = SimpleAxis(x)

# FIXME this should be deleted once https://github.com/SciML/ArrayInterface.jl/issues/79 is resolved
@propagate_inbounds function Base.getindex(axis::SimpleAxis, arg::StepRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    return maybe_unsafe_reconstruct(axis, arg)
end

print_axis(io::IO, axis::SimpleAxis) = print(io, "SimpleAxis($(parent(axis)))")

#=
We need to assign new indices to axes of `A` but `reshape` may have changed the
size of any axis
=#
@inline function reshape_axes(axs::Tuple, inds::Tuple{Vararg{Any,N}}) where {N}
    return map((a, i) -> resize_last(a, i), axs, inds)
end

Base.isempty(axis::AbstractAxis) = isempty(parent(axis))
Base.empty(axis::SimpleAxis) = SimpleAxis(static(1):static(0))
Base.empty(axis::Axis) = _Axis(empty(keys(axis)), parent(axis))

