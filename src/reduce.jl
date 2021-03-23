
# TODO this should probably be in ArrayInterface.jl "dimensions.jl"
function Base.reduced_index(i::OptionallyStaticUnitRange)
    start = static_first(i)
    # keep last position dynamic for type stability b/c we don't know which axis is reduced
    return start:dynamic(start)
end
function Base.reduced_index(i::Slice{<:OptionallyStaticUnitRange})
    return Base.Slice(Base.reduced_index(i.indices))
end
function Base.reduced_index(i::IdentityUnitRange{<:OptionallyStaticUnitRange})
    return IdentityUnitRange(Base.reduced_index(i.indices))
end


###
### reduce
###
reduced_axes(::Tuple{}, ::Tuple{}) = ()
function reduced_axes(axs::Tuple{A,Vararg{Any}}, x::Tuple{B,Vararg{Any}}) where {A,B}
    return (reduced_axis(first(axs), first(x)), reduced_axes(tail(axs), tail(x))...)
end

#=
reduced_axis(axis, b::True) = initialize(param(axis), reduced_axis(parent(axis), b))
reduced_axis(axis::SimpleAxis, ::True) = SimpleAxis(static(1):static(1))
function reduced_axis(axis::KeyedAxis, ::True)
    return _Axis(@inbounds(param(axis).keys[static(1):static(1)]), reduced_axis(parent(axis), b))
end
reduced_axis(axis::KeyedAxis, ::False) = axis
reduced_axis(axis::SimpleAxis, ::False) = axis
reduced_axis(axis, ::False) = axis
reduced_axis(axis::SimpleAxis, b::Bool) = b ? SimpleAxis(static(1):1) : axis
reduced_axis(axis, b::Bool) = b ? initialize(param(axis), reduced_axis(parent(axis), b)) : axis
function reduced_axis(axis::KeyedAxis, b::Bool)
    if b
        return _Axis(@inbounds(param(axis).keys[static(1):1]), reduced_axis(parent(axis), b))
    else
        return axis
    end
end
=#
function reduced_axis(axis, ::True)
    start = static_first(axis)
    return @inbounds(axis[start:start])
end
reduced_axis(axis, ::False) = axis
function reduced_axis(axis, b::Bool)
    start = first(axis)
    if b
        return @inbounds(axis[start:dynamic(start)])
    else
        return @inbounds(axis[start:dynamic(last(axis))])
    end
end




# FIXME reduce_param(p::AxisStruct) = 

function reconstruct_reduction(A, a, d)
    return _AxisArray(a, reduced_axes(axes(A), dims_indicators(Static.nstatic(Val(ndims(A))), d)))
end
reconstruct_reduction(old_array, new_array, d::Colon) = new_array

function Base.mapreduce(f, op, A::AxisArray; dims=:, kwargs...)
    d = to_dims(A, dims)
    reconstruct_reduction(A, mapreduce(f, op, parent(A); dims=d, kwargs...), d)
end

function Base.extrema(A::AxisArray; dims=:, kwargs...)
    d = to_dims(A, dims)
    reconstruct_reduction(A, extrema(parent(A); dims=d, kwargs...), d)
end

for f in (:mean, :median, :std, :var)
    @eval function Statistics.$f(a::AxisArray; dims=:, kwargs...)
        d = to_dims(a, dims)
        return reconstruct_reduction(a, Statistics.$f(parent(a); dims=d, kwargs...), d)
    end
end

function Base.mapslices(f, a::AxisArray; dims, kwargs...)
    d = to_dims(a, dims)
    return reconstruct_reduction(a, Base.mapslices(f, parent(a); dims=d, kwargs...), d)
end

