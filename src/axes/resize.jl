
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

