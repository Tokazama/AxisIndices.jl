
function StaticRanges.unsafe_grow_end!(axis::AbstractAxis, n)
    unsafe_grow_end!(parent(axis), n)
end
unsafe_grow_at!(axis::AbstractAxis, n) = unsafe_grow_at!(parent(axis), n)
function unsafe_grow_at!(axis::KeyedAxis, n)
    unsafe_grow_at!(param(axis).keys, n)
    unsafe_grow_at!(parent(axis), n)
end
unsafe_grow_at!(axis::MutableAxis, n) = unsafe_grow_end!(axis, n)
function unsafe_grow_at!(axis::AbstractRange, n)
    if n === 1
        unsafe_grow_beg!(axis, n)
    else
        unsafe_grow_end!(axis, n)
    end
end

function StaticRanges.unsafe_shrink_end!(axis::AbstractAxis, n)
    unsafe_shrink_end!(parent(axis), n)
end

unsafe_shrink_at!(axis::AbstractAxis, n) = unsafe_shrink_at!(parent(axis), n)
function unsafe_shrink_at!(axis::KeyedAxis, n)
    unsafe_shrink_at!(getfield(axis, :keys), n)
    unsafe_shrink_at!(parent(axis), n)
end
unsafe_shrink_at!(axis::MutableAxis, n) = unsafe_shrink_end!(axis, n)
function unsafe_shrink_at!(axis::AbstractRange, n)
    if n === 1
        unsafe_shrink_beg!(axis, n)
    else
        unsafe_shrink_end!(axis, n)
    end
end

unsafe_shrink_at!(axis::AbstractVector, n) = deleteat!(axis, n)

function Base.empty!(axis::AbstractAxis)
    StaticRanges.shrink_to!(axis, 0)
    return axis
end

function unsafe_shrink_end(axis::AbstractAxis, n)
    len = static_length(axis) - n
    start = static_first(axis)
    return @inbounds(axis[start:(start + len - one(start))])
end

StaticRanges.unsafe_grow_end(axis::SimpleAxis, n::Integer) = SimpleAxis(static(1):(static_length(axis) + n))
StaticRanges.unsafe_grow_end(axis::AbstractAxis, n::Integer) = _unsafe_grow_end(has_keys(axis), axis, n)
function _unsafe_grow_end(::True, axis, n)
    k, p = strip_keys(axis)
    return _Axis(LazyVCat(keys(axis), static(1):n), StaticRanges.unsafe_grow_end(p, n))
end
function _unsafe_grow_end(::False, axis, n)
    return initialize(param(axis), StaticRanges.unsafe_grow_end(parent(axis), n))
end

# TODO remove this
function resize_last(axis, n)
    len = static_length(axis)
    if len > n
        return StaticRanges.unsafe_grow_end(axis, len - n)
    else
        start = static_first(axis)
        stop = start + n - one(start)
        return @inbounds(axis[start:stop])
    end
end

