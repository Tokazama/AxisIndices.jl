
Axis() = _Axis(Vector{Any}(), SimpleAxis(DynamicAxis(0)))

Axis(x::Pair) = Axis(x.first, x.second)
Axis(x::Axis) = x

@inline Axis(k::AbstractVector, axis) = Axis(k, compose_axis(axis))
@inline function Axis(k::AbstractVector, axis::AbstractAxis)
    check_axis_length(k, axis)
    check_unique_keys(k)
    return _Axis(_maybe_offset(offset1(axis) - offset1(k), k), drop_keys(axis))
end

function Axis(ks::AbstractVector)
    check_unique_keys(ks)
    if can_change_size(ks)
        inds = SimpleAxis(DynamicAxis(length(ks)))
    else
        inds = compose_axis(static_first(eachindex(ks)):static_length(ks))
    end
    return _Axis(ks, inds)
end

## interface
@inline Base.getproperty(axis::Axis, k::Symbol) = getproperty(parent(axis), k)

function ArrayInterface.unsafe_reconstruct(axis::Axis, inds; keys=nothing)
    if keys === nothing
        ks = Base.keys(axis)
        p = parent(axis)
        kindex = firstindex(ks)
        pindex = first(p)
        if kindex === pindex
            return _Axis(@inbounds(ks[inds]), compose_axis(inds))
        else
            return _Axis(@inbounds(ks[inds .+ (pindex - kindex)]), compose_axis(inds))
        end
    else
        return _Axis(keys, compose_axis(inds))
    end
end

@inline function ArrayInterface.to_axis(::IndexAxis, axis::Axis, inds)
    if allunique(inds)
        ks = Base.keys(axis)
        p = parent(axis)
        kindex = firstindex(ks)
        pindex = first(p)
        if kindex === pindex
            return _Axis(@inbounds(ks[inds]), to_axis(parent(axis), inds))
        else
            return _Axis(
                @inbounds(ks[inds .+ (pindex - kindex)]),
                to_axis(parent(axis), inds)
            )
        end
    else
        return unsafe_reconstruct(axis, to_axis(parent(axis), inds))
    end
end

function maybe_unsafe_reconstruct(axis::Axis, inds::AbstractUnitRange{I}; keys=nothing) where {I<:Integer}
    if keys === nothing
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=@inbounds(Base.keys(axis)[inds]))
    else
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=keys)
    end
end
function maybe_unsafe_reconstruct(axis::Axis, inds::AbstractArray)
    if keys === nothing
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds))),)
    elseif allunique(inds)
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds)); keys=@inbounds(keys(axis)[inds])),)
    else  # not all indices are unique so will result in non-unique keys
        axs = (SimpleAxis(eachindex(inds)),)
    end
    return AxisArray{eltype(axis),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
end

function StaticRanges.unsafe_grow_end!(axis::Axis, n::Integer)
    StaticRanges.unsafe_grow_end!(keys(axis), n)
    StaticRanges.unsafe_grow_end!(parent(axis), n)
    return nothing
end
function StaticRanges.unsafe_shrink_end!(axis::Axis, n::Integer)
    StaticRanges.unsafe_shrink_end!(keys(axis), n)
    StaticRanges.unsafe_shrink_end!(parent(axis), n)
    return nothing
end

function ArrayInterface.can_change_size(::Type{T}) where {T<:Axis}
    return can_change_size(keys_type(T)) & can_change_size(parent_type(T))
end

@propagate_inbounds function Base.getindex(axis::Axis, arg::AbstractUnitRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    ks = keys(axis)
    p = parent(axis)
    kindex = firstindex(ks)
    pindex = first(p)
    if kindex === pindex
        return _Axis(
            @inbounds(ks[arg]),
            @inbounds(getindex(p, arg))
        )
    else
        return _Axis(
            @inbounds(ks[arg .+ (kindex - pindex)]),
            @inbounds(getindex(p, arg))
        )
    end
end

print_axis(io::IO, axis::Axis) = print(io, "Axis($(keys(axis)) => $(parent(axis)))")

